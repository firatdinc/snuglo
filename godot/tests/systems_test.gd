extends SceneTree
## Sistem katmanı testleri (Save/Progress/Wallet/Meta/Purchases).
## godot --headless --path godot -s tests/systems_test.gd
## Kayıt geçici dosyaya gider (SNUG_SAVE); gerçek kayda dokunulmaz.

var fails := 0
var passes := 0
var _tmp := ""

func _init() -> void:
	_tmp = OS.get_user_data_dir().path_join("snuglo_systems_test.json")
	OS.set_environment("SNUG_SAVE", _tmp)
	OS.set_environment("SNUG_MUTE", "1")

func _initialize() -> void:
	_run.call_deferred()

func _check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("PASS ", name)
	else:
		fails += 1
		print("FAIL ", name, "  ", detail)

func _node(n: String) -> Node:
	return root.get_node("/root/" + n)

func _run() -> void:
	# Güvenlik: bir şey takılırsa 90 sn sonra başarısız çık.
	create_timer(90.0).timeout.connect(func() -> void:
		print("FAIL zaman aşımı")
		quit(1))
	await process_frame
	var save := _node("Save")
	save.path = _tmp          # SNUG_SAVE erken okunmadıysa da güvence
	save.reset_all()
	var progress := _node("Progress")
	progress.today_override = "2026-03-02"
	_test_save(save)
	_test_wallet()
	_test_record_level()
	_test_pack_reward()
	_test_daily_streak()
	_test_quests()
	_test_achievements()
	_test_purchases()
	_test_meta_misc()
	_test_play_streak_freeze()
	_test_relaxed()
	_test_energy()
	_test_tower()
	_test_nook()
	_test_version_ads()
	_test_legacy()
	DirAccess.remove_absolute(_tmp)
	print("systems: %d passed, %d failed" % [passes, fails])
	quit(1 if fails > 0 else 0)

func _test_save(save: Node) -> void:
	var wallet := _node("Wallet")
	wallet.debug_set("coin", 1234)
	save.flush()
	var disk = JSON.parse_string(FileAccess.get_file_as_string(_tmp))
	_check("save: diske yazıldı + şema", disk is Dictionary and int(disk.get("schema", 0)) == save.SCHEMA \
		and int(disk.wallet.coin) == 1234, str(disk))
	var code: String = save.export_code()
	_check("save: export SNUG2 başlığı + imza", code.begins_with("SNUG2:") and code.contains("."))
	# Elle düzenlenmiş kod (bakiye şişirilmiş, imza aynı) reddedilmeli.
	var body: String = code.substr(6).split(".")[0]
	var tampered_json := Marshalls.base64_to_utf8(body).replace("1234", "99999")
	var tampered := "SNUG2:" + Marshalls.utf8_to_base64(tampered_json) + "." + code.split(".")[1]
	save.reset_all()
	_check("save: reset sıfırlar", wallet.coins == 0)
	_check("save: import geçerli kod", save.import_code(code) and wallet.coins == 1234, str(wallet.coins))
	_check("save: import geçersiz kod reddedilir", not save.import_code("SNUG2:@@bozuk@@") \
		and not save.import_code("merhaba") and not save.import_code(tampered) \
		and not save.import_code("SNUG1:" + body) and wallet.coins == 1234)
	save.reset_all()

func _test_wallet() -> void:
	var w := _node("Wallet")
	w.debug_set("coin", 10)
	var got := []
	var cb := func(c: String, a: int, d: int) -> void: got.append([c, a, d])
	_node("Events").wallet_changed.connect(cb)
	_check("wallet: yetersiz harcama false", not w.spend("coin", 20) and w.coins == 10)
	_check("wallet: harcama + sinyal", w.spend("coin", 4) and w.coins == 6 and got.back() == ["coin", 6, -4], str(got))
	_check("wallet: can_afford", w.can_afford("coin", 6) and not w.can_afford("coin", 7) and not w.can_afford("coin", 0))
	_node("Events").wallet_changed.disconnect(cb)
	w.debug_set("gem", 0)
	w.debug_set("hint", 1)
	_check("wallet: ipucu önce envanterden", w.pay_powerup("hint") == "free" and w.hints == 0)
	_check("wallet: gem yoksa güçlendirme yok", w.pay_powerup("hint") == "")
	w.debug_set("gem", 30)
	_check("wallet: ipucu gem ile (30)", w.pay_powerup("hint") == "gem" and w.gems == 0)
	w.debug_set("coin", 250)
	_check("wallet: coin→gem takası", w.exchange_coins_to_gems(2) and w.coins == 50 and w.gems == 2)

func _test_record_level() -> void:
	var p := _node("Progress")
	_check("stars: kurallar", p.compute_stars(30, 5) == 3 and p.compute_stars(31, 5) == 2 \
		and p.compute_stars(61, 5) == 1 and p.compute_stars(120, 8) == 3 and p.compute_stars(240, 8) == 2 \
		and p.compute_stars(241, 8) == 1)
	_check("unlock: başlangıç", p.is_level_unlocked("cozy-beginnings", 1) \
		and not p.is_level_unlocked("cozy-beginnings", 2))
	_check("continue: ilk bölüm", p.continue_target() == "cozy-beginnings-1", p.continue_target())
	p.break_chain()
	var r: Dictionary = p.record_level("cozy-beginnings-1", 20.0, 0)
	_check("record: 3 yıldız + ilk çözüm", r.stars == 3 and r.first_clear and not r.new_best, str(r))
	_check("record: coin/gem/anahtar/xp (5/3 + ilk 3★ gem)", r.coins == 18 and r.gems == 1 and r.keys == 1 and r.xp == 50, str(r))
	_check("record: zincir unlock", p.is_level_unlocked("cozy-beginnings", 2) \
		and not p.is_level_unlocked("cozy-beginnings", 3))
	r = p.record_level("cozy-beginnings-1", 45.0, 0)
	_check("record: kötü tekrar yıldız düşürmez", p.stars("cozy-beginnings-1") == 3 and r.stars == 2 \
		and not r.new_best and not r.first_clear and r.chain == 2 and r.chain_bonus == 5 and r.gems == 0, str(r))
	r = p.record_level("cozy-beginnings-1", 12.0, 0)
	_check("record: yeni rekor, tekrar 3★ gem vermez", r.new_best and r.gems == 0 \
		and is_equal_approx(p.best_time("cozy-beginnings-1"), 12.0))
	_check("continue: sonraki", p.continue_target() == "cozy-beginnings-2", p.continue_target())
	_check("stats: toplamlar", p.stats().total_levels == 1 and p.stats().stars == 3 and p.stats().perfect == 1)

func _test_pack_reward() -> void:
	var p := _node("Progress")
	var w := _node("Wallet")
	for i in range(1, 61):
		p.record_level("cozy-beginnings-%d" % i, 200.0, 1)
	_check("pack: tamamlandı bekliyor", p.pending_pack_reward() == "cozy-beginnings" and p.is_pack_complete("cozy-beginnings"))
	var c0: int = w.coins
	var g0: int = w.gems
	_check("pack: sonraki paket kilitli → tamamlanınca açılır", p.is_pack_unlocked("spice-route") \
		and not p.is_pack_unlocked("mambo-nights"))
	var k0: int = w.keys
	var got: Dictionary = p.collect_pack_reward()
	_check("pack: 200 coin + 25 gem + 2 anahtar", got.get("coin") == 200 and w.coins - c0 == 200 \
		and w.gems - g0 == 25 and got.get("key") == 2 and w.keys - k0 == 2, str(got))
	_check("pack: ikinci toplama yok", p.collect_pack_reward().is_empty())
	p.record_level("cozy-beginnings-5", 100.0, 0)
	_check("pack: yeniden çözüm tekrar ödüllendirmez", p.pending_pack_reward() == "")
	_check("pack: continue sonraki pakete geçer", p.continue_target() == "spice-route-1", p.continue_target())
	_check("unlock: başta 2. paket kilitliydi (premium yok)", p.TOTAL_LEVELS == 1020 and p.PACKS.size() == 17)

func _test_daily_streak() -> void:
	var p := _node("Progress")
	var solved := []
	var cb := func(i: int) -> void: solved.append(i)
	_node("Events").daily_solved.connect(cb)
	p.today_override = "2026-03-02"
	for i in 5:
		p.record_level("daily-%d" % i, 40.0, 0)
	_check("daily: 5/5 + sinyal", p.is_daily_all_complete() and p.daily_solved_count() == 5 \
		and solved == [0, 1, 2, 3, 4], str(solved))
	_check("daily: seri 1", p.daily_streak == 1, str(p.daily_streak))
	p.today_override = "2026-03-03"
	_check("daily: yeni gün sıfır", p.daily_solved_count() == 0 and p.daily_next_index() == 0 and p.daily_streak == 1)
	p.record_level("daily-0", 40.0, 0)
	_check("daily: seri 2", p.daily_streak == 2 and p.daily_solved_count() == 1)
	p.today_override = "2026-03-05"
	_check("daily: bir gün kaçtı → seri 0", p.daily_streak == 0, str(p.daily_streak))
	p.record_level("daily-0", 40.0, 0)
	_check("daily: seri 1, en uzun 2", p.daily_streak == 1 and p.daily_longest == 2)
	var month: Array = p.daily_month(2026, 3)
	_check("daily: takvim", month.size() == 31 and month[1].full and month[2].count == 1 and not month[3].solved)
	_node("Events").daily_solved.disconnect(cb)

func _test_quests() -> void:
	var p := _node("Progress")
	var q := _node("Quests")
	p.today_override = "2026-04-10"
	var qs: Array = q.today()
	_check("quests: yeni gün 3 görev sıfır", qs.size() == 3 and qs[0].progress == 0 and not qs[0].complete)
	var goal: int = qs[0].goal
	var done := []
	for i in goal:
		done.append_array(p.record_level("cozy-beginnings-%d" % (i + 1), 20.0, 0).quests_completed)
	qs = q.today()
	_check("quests: çöz N bölüm tamam", qs[0].complete and 0 in done and 1 in done, str(done))
	var w := _node("Wallet")
	var c0: int = w.coins
	_check("quests: ödül alınır", q.claim(0).get("coin") == 60 and w.coins - c0 == 60)
	_check("quests: ikinci kez alınmaz", q.claim(0).is_empty())
	p.today_override = "2026-04-11"
	_check("quests: ertesi gün sıfırlanır", q.today()[0].progress == 0 and not q.today()[0].claimed)
	_check("quests: haftalık ilerliyor", q.weekly().progress >= 0 and q.weekly().goal in [15, 20, 25])

func _test_achievements() -> void:
	var a := _node("Achievements")
	_check("ach: firstSteps açık", a.is_unlocked("firstSteps") and a.is_unlocked("perfectionist1") \
		and a.is_unlocked("levelMaster50") and a.is_unlocked("packFinisher") and a.is_unlocked("speedSolver"))
	_check("ach: progress", a.progress("levelLegend100") == Vector2i(60, 100), str(a.progress("levelLegend100")))
	_check("ach: idempotent", a.evaluate().is_empty())
	_check("ach: 35 başarım", a.all().size() == 35 and a.is_unlocked("levelHunter25") and not a.is_unlocked("levelVoyager250"))
	_node("Save").reset_all()
	var p := _node("Progress")
	p.today_override = "2026-05-01"
	var got := []
	var cb := func(id: String) -> void: got.append(id)
	_node("Events").achievement_unlocked.connect(cb)
	var r: Dictionary = p.record_level("cozy-beginnings-1", 100.0, 1)
	_node("Events").achievement_unlocked.disconnect(cb)
	_check("ach: ilk çözüm sinyali", "firstSteps" in got and "firstSteps" in r.achievements \
		and not "perfectionist1" in got, str(got))

func _test_purchases() -> void:
	var p := _node("Progress")
	var pu := _node("Purchases")
	var w := _node("Wallet")
	_check("iap: ikinci paket kilitli, premium yok", not p.is_pack_unlocked("spice-route") \
		and p.is_pack_unlocked("cozy-beginnings") and not pu.is_premium() and not pu.ads_removed())
	_check("iap: yedek fiyat", pu.get_price(pu.PREMIUM) == "$4.99" and pu.get_price(pu.REMOVE_ADS) == "$2.99" \
		and pu.get_price("com.snuglo.gems.tier4") == "$19.99")
	var got := []
	var cb := func(id: String) -> void: got.append(id)
	_node("Events").purchase_completed.connect(cb)
	var g0: int = w.gems
	pu.buy("com.snuglo.gems.tier1")
	_check("iap: gem paketi +100", w.gems - g0 == 100)
	var h0: int = w.hints
	var k0: int = w.keys
	pu.buy(pu.HINTS_SMALL)
	pu.buy(pu.KEYS_SMALL)
	_check("iap: ipucu +10, anahtar +3", w.hints - h0 == 10 and w.keys - k0 == 3)
	pu.buy(pu.PREMIUM)
	_check("iap: premium → tüm paketler + reklamsız + sınırsız enerji", pu.is_premium() and pu.ads_removed() \
		and p.is_pack_unlocked("aurora-vale") and _node("Energy").start_game("spice-route-1") \
		and _node("Energy").current == 50)
	_check("iap: sinyaller", got == ["com.snuglo.gems.tier1", pu.HINTS_SMALL, pu.KEYS_SMALL, pu.PREMIUM], str(got))
	_check("iap: premium tüm kozmetikleri açar", _node("Cosmetics").is_fabric_unlocked("blossom"))
	_node("Events").purchase_completed.disconnect(cb)
	pu.debug_clear()
	_check("iap: temizlenince premium yok", not pu.is_premium())

func _test_meta_misc() -> void:
	var p := _node("Progress")
	p.today_override = "2026-06-01"
	var spin := _node("Spin")
	_check("spin: bilet dilimi yok", spin.SEGMENTS.all(func(sg): return sg.currency in ["coin", "gem"]))
	_check("spin: ağırlık toplamı 100", spin.WEIGHTS.reduce(func(a, b): return a + b, 0) == 100)
	_check("spin: bugün dönebilir", spin.can_spin())
	_check("spin: commit sonra kilit", not spin.commit(spin.choose_index()).is_empty() and not spin.can_spin())
	p.today_override = "2026-06-02"
	_check("spin: ertesi gün açık", spin.can_spin())
	var dr := _node("DailyReward")
	var a: Dictionary = dr.claim_week()
	_check("daily reward: gün 1 = 50 coin", a.day == 1 and a.reward.get("coin") == 50, str(a))
	_check("daily reward: aynı gün yok", dr.claim_week().is_empty())
	p.today_override = "2026-06-03"
	_check("daily reward: gün 2", dr.claim_week().day == 2)
	p.today_override = "2026-06-05"
	_check("daily reward: kaçınca gün 1", dr.claim_week().day == 1)
	_check("calendar: gün 1 = 55 coin", dr.claim_calendar().reward.coin == 55)
	var xp := _node("XP")
	_check("xp: eğri + seviye coin'i", xp.info(100).level == 2 and xp.info(259).level == 2 and xp.info(260).level == 3 \
		and xp.level_up_coins(2) == 30)
	var chest := _node("Chest")
	var pend: int = chest.pending
	for i in 5:
		chest.record_solve()
	_check("chest: 5 çözüm = +1 sandık", chest.pending == pend + 1)
	w0_keys_reset()
	_check("chest: anahtarsız açılmaz", chest.open().is_empty() and not chest.can_open())
	_node("Wallet").debug_set("key", 1)
	var cr: Dictionary = chest.open()
	# Efsanevi kademe 1 anahtar geri verir.
	_check("chest: anahtarla aç", not cr.is_empty() and chest.pending == pend and _node("Wallet").keys == int(cr.get("rewards", {}).get("key", 0)))
	var cos := _node("Cosmetics")
	var w := _node("Wallet")
	_check("cosmetics: aurora kilitli", not cos.is_fabric_unlocked("aurora") and not cos.select_fabric("aurora"))
	w.debug_set("gem", 29)
	_check("cosmetics: 30 gem yetmez", not cos.buy_fabric("aurora"))
	w.debug_set("gem", 30)
	_check("cosmetics: satın al + seç", cos.buy_fabric("aurora") and cos.select_fabric("aurora") \
		and cos.selected_fabric == "aurora" and w.gems == 0)
	w.debug_set("gem", 300)
	_check("cosmetics: premium set 300 gem", not cos.is_fabric_unlocked("midnight") and cos.buy_fabric("midnight") and w.gems == 0)
	_check("cosmetics: tahta seç", cos.select_board("night") and cos.selected_board == "night" \
		and not cos.select_board("x") and not cos.select_board("ember"))
	w.debug_set("gem", 250)
	_check("cosmetics: premium tahta 250 gem", cos.buy_board("ember") and cos.select_board("ember") and w.gems == 0)
	var combo: Dictionary = p.award_combo(5)
	_check("combo: ×5 = 10 + 10 coin, gem yok", combo.coins == 20 and combo.milestone and p.award_combo(5, true).coins == 0)
	var gc := _node("GameCenter")
	var sc: Dictionary = gc.scores({"total_levels": 7, "best_time": 12.5, "daily_longest": 3})
	_check("gamecenter: santisaniye eşlemesi", sc[gc.FASTEST_SOLVE] == 1250 and sc[gc.TOTAL_LEVELS] == 7 and sc[gc.BEST_STREAK] == 3)
	var st := _node("Settings")
	st.sfx_volume = 0.25
	_check("settings: sfx uygulanır", is_equal_approx(_node("Sfx").sfx_volume, 0.25) \
		and is_equal_approx(float(_node("Save").get_section("settings").sfx_volume), 0.25))
	st.language = "tr"
	_check("settings: dil", TranslationServer.get_locale().begins_with("tr") and tr("common.cancel") == "İptal", tr("common.cancel"))
	st.language = "xx"
	_check("settings: geçersiz dil → sistem", st.language == "")

func _test_play_streak_freeze() -> void:
	_node("Save").reset_all()
	var p := _node("Progress")
	var w := _node("Wallet")
	for d in ["2026-07-01", "2026-07-02", "2026-07-03"]:
		p.today_override = d
		p.record_level("cozy-beginnings-1", 100.0, 0)
	_check("play streak: 3 gün", p.play_streak == 3 and p.pending_streak_milestone() == 3)
	var m: Dictionary = p.collect_streak_milestone()
	_check("play streak: kilometre taşı ödülü", m.get("coin") == 30 and p.pending_streak_milestone() == 0)
	w.debug_set("gem", 5)
	_check("freeze: 5 gem'e alınır", p.buy_streak_freeze() and p.streak_freezes == 1 and w.gems == 0)
	p.today_override = "2026-07-05"   # 07-04 kaçtı
	p.refresh_streaks()
	_check("freeze: tek kaçan gün köprülenir", p.play_streak == 4 and p.streak_freezes == 0, "%d %d" % [p.play_streak, p.streak_freezes])
	p.today_override = "2026-07-08"
	p.refresh_streaks()
	_check("play streak: dondurmasız kırılır", p.play_streak == 0 and p.longest_play_streak == 4)

func w0_keys_reset() -> void:
	_node("Wallet").debug_set("key", 0)

func _test_relaxed() -> void:
	_node("Save").reset_all()
	var p := _node("Progress")
	p.today_override = "2026-08-01"
	var w := _node("Wallet")
	var r: Dictionary = p.record_level("endless-1", 10.0, 0)
	_check("relaxed: endless 5 coin + 10 XP, gem/görev yok", r.relaxed and r.coins == 5 and r.xp == 10 \
		and r.gems == 0 and r.quests_completed.is_empty() and r.endless_record and w.coins == 5, str(r))
	for i in range(2, 10):
		r = p.record_level("endless-%d" % i, 10.0, 0)
	_check("relaxed: günlük tavan 25 coin / 50 XP", w.coins == 25 and _node("XP").total == 50 and r.coins == 0)
	_check("relaxed: endless rekoru", p.endless_best == 9)
	_node("Settings").zen_mode = true
	r = p.record_level("cozy-beginnings-1", 10.0, 0)
	_check("relaxed: zen'de kampanya kaydedilir ama ödül tavanlı", r.relaxed and r.coins == 0 and r.gems == 0 \
		and p.is_completed("cozy-beginnings-1"))
	_node("Settings").zen_mode = false
	p.today_override = "2026-08-02"
	r = p.record_level("endless-1", 10.0, 0)
	_check("relaxed: ertesi gün tavan sıfırlanır", r.coins == 5)

func _test_energy() -> void:
	var e := _node("Energy")
	e.now_override = 1000000.0
	e.reset()
	_check("energy: dolu 50", e.current == 50 and e.can_start_game())
	_check("energy: oyun -5", e.start_game("cozy-beginnings-2") and e.current == 45 and e.consume_spend_animation() == 5)
	_check("energy: yarım bölüme dönüş ücretsiz", e.start_game("cozy-beginnings-2") and e.current == 45)
	_check("energy: endless/tower ücretsiz", e.start_game("endless-3") and e.start_game("tower-1") and e.current == 45)
	_check("energy: yeniden başlatma ücretli", e.charge_restart("cozy-beginnings-2") and e.current == 40)
	e.end_paid_session("cozy-beginnings-2")
	e.start_game("cozy-beginnings-2")
	_check("energy: tamamlanınca tekrar ücretli", e.current == 35)
	e.now_override += 180.0 * 2 + 5.0
	_check("energy: 3 dk'da +1", e.current == 37 and e.seconds_until_next() == 175, "%d %d" % [e.current, e.seconds_until_next()])
	for i in 7:
		e.start_game("x-%d" % i)
	_check("energy: 2 kaldı → başlatamaz", e.current == 2 and not e.can_start_game() and not e.start_game("y-1"))
	_check("energy: oynanabilir süre", e.seconds_until_playable() == 175 + 2 * 180, str(e.seconds_until_playable()))
	e.add(10)
	_check("energy: reklam +10", e.current == 12)
	e.now_override += 100000.0
	_check("energy: en çok 50", e.current == 50)
	e.now_override = -1.0

func _test_tower() -> void:
	var t := _node("Tower")
	var w := _node("Wallet")
	w.debug_set("ticket", 0)
	_check("tower: biletsiz giriş yok", not t.can_enter() and not t.start_run())
	w.debug_set("gem", 50)
	_check("tower: 50 gem → 1 bilet", w.exchange("gem", "ticket", 1) and w.tickets == 1)
	_check("tower: başla", t.start_run() and t.current_floor == 1 and w.tickets == 0)
	_check("tower: kurallar", t.grid_size(1) == 5 and t.grid_size(5) == 6 and t.grid_size(30) == 8 \
		and t.time_limit(1) == 75 and t.time_limit(30) == 105)
	var r: Dictionary = _node("Progress").record_level("tower-1", 20.0, 0)
	_node("Progress").record_level("tower-2", 20.0, 0)
	_check("tower: kat geçişi + rekor", r.mode == "tower" and r.tower_record and t.current_floor == 3 \
		and t.best_floor == 2 and not _node("Progress").is_completed("tower-1"))
	var c0: int = w.coins
	var end: Dictionary = t.end_run()
	_check("tower: bitiş 2 kat × 20", end.floors == 2 and end.coins == 40 and w.coins - c0 == 40 and not t.has_active_run())

func _test_nook() -> void:
	_node("Save").reset_all()
	var p := _node("Progress")
	var nook := _node("Nook")
	var piece := -2
	for i in range(1, 21):
		var r: Dictionary = p.record_level("cozy-beginnings-%d" % i, 100.0, 0)
		if i == 10:
			piece = r.nook_piece
	_check("nook: 10. bölüm parça açar", piece == 0 and nook.earned_pieces("cozy-beginnings") == 2 \
		and nook.available_pieces("cozy-beginnings") == 2 and nook.total_available() == 2)
	_check("nook: yerleştir", nook.place_next_piece("cozy-beginnings") == 0 and nook.place_next_piece("cozy-beginnings") == 1 \
		and nook.place_next_piece("cozy-beginnings") == -1 and nook.placed_pieces("cozy-beginnings") == 2)
	_check("nook: ilerleme", is_equal_approx(nook.completion(), 2.0 / (17 * 6)) and not nook.is_restored("cozy-beginnings"))
	var r2: Dictionary = p.record_level("cozy-beginnings-10", 50.0, 0)
	_check("nook: tekrar çözüm parça vermez", r2.nook_piece == -1)
	p.save_session("cozy-beginnings-21", {"fingerprint": "5x5|a,b", "elapsed": 12})
	p.save_session("endless-4", {"elapsed": 1})
	_check("session: kaydet / endless kaydedilmez", p.get_session("cozy-beginnings-21").elapsed == 12 and p.get_session("endless-4").is_empty())
	p.record_level("cozy-beginnings-21", 50.0, 0)
	_check("session: çözülünce silinir", p.get_session("cozy-beginnings-21").is_empty())

func _test_version_ads() -> void:
	var v := _node("VersionGate")
	_check("version: karşılaştırma", v.is_less("1.2", "1.10") and not v.is_less("1.2.0", "1.2") and v.is_less("0.9.9", "1.0"))
	v.apply_config({"ios": {"latestVersion": "999.0", "minVersion": "998.0"}})
	_check("version: zorunlu", v.state == "forced")
	v.apply_config({"ios": {"latestVersion": "999.0", "minVersion": "0"}})
	_check("version: yumuşak", v.state == "soft")
	v.dismiss_soft()
	v.apply_config({"ios": {"latestVersion": "999.0", "minVersion": "0"}})
	_check("version: kapatılan sürüm susar", v.state == "up_to_date")
	var ads := _node("Ads")
	var got := [false]
	ads.show_rewarded(func() -> void: got[0] = true)
	_check("ads: debug ödüllü reklam + bekleme", got[0] and not ads.rewarded_ready() and ads.rewarded_cooldown_remaining() > 0)

func _test_legacy() -> void:
	var save := _node("Save")
	save.reset_all()
	var apple := func(key: String) -> float:
		return Time.get_unix_time_from_datetime_string(key + "T12:00:00") - 978307200.0
	var legacy := {
		"snuglo.progress.v1": JSON.stringify({
			"levelProgress": {
				"cozy-beginnings-1": {"isCompleted": true, "stars": 3, "bestTime": 22.5, "completedAt": apple.call("2026-05-01"), "bestHintsUsed": 0},
				"cozy-beginnings-2": {"isCompleted": true, "stars": 2, "bestTime": 70.0},
				"tower-3": {"isCompleted": true, "stars": 3, "bestTime": 9.0},
			},
			"dailyResults": [{"date": "2026-05-01", "solved": true, "time": 40.0}, {"date": "2026-05-02", "solved": true}],
			"currentStreak": 2, "longestStreak": 4, "hintCount": 7,
			"lastClaimedDate": apple.call("2026-05-02"), "lastClaimedDay": 3,
			"dailyChallenge": {"date": "2026-05-02", "solvedCount": 4},
			"playedDays": ["2026-05-01", "2026-05-02"], "longestPlayStreak": 5,
			"lastRewardedStreak": 3, "streakFreezes": 2,
		}).to_utf8_buffer(),
		"snuglo.wallet.v1": JSON.stringify({"coin": 1500, "gem": 42, "ticket": 3, "cup": 1}),
		"snuglo.xp.v1": JSON.stringify({"totalXP": 260}),
		"snuglo.achievements.v1": JSON.stringify({"unlocked": ["firstSteps", "perfectionist1", "bogus"]}),
		"snuglo.chests.v1": JSON.stringify({"progress": 3, "pending": 1, "keys": 2}),
		"snuglo.spin.v1": JSON.stringify({"lastSpinDay": 20000}),
		"snuglo.dailyquests.v1": JSON.stringify({"day": 20000, "progress": [1, 0, 2], "claimed": [false, false, true]}),
		"snuglo.weekly.v1": JSON.stringify({"week": 2857, "progress": 9, "claimed": false}),
		"snuglo.cosmetics.v1": ["candy", "midnight"],
		"snuglo.cosmetics.boards.v1": ["ember"],
		"blockSkin": "candy", "boardBackground": "ember",
		"snuglo.dailycal.v1": JSON.stringify({"claimedCycleDay": 6, "lastClaimedDayNumber": 20000}),
		"snuglo.endless.v1": 14,
		"snuglo.packrewards.v1": ["cozy-beginnings"], "snuglo.packrewards.pending": "spice-route",
		"snuglo.energy.value.v1": 23, "snuglo.energy.anchor.v1": 1.78e9, "snuglo.energy.openlevels.v1": ["cozy-beginnings-3"],
		"snuglo.gamesessions.v1": JSON.stringify({"cozy-beginnings-3": {"levelID": "cozy-beginnings-3",
			"fingerprint": "5x5|p1,p2", "placements": [{"pieceId": "p1", "origin": {"x": 1, "y": 2}}],
			"elapsedSeconds": 33, "moveCount": 4, "hintsUsed": 1, "moveHistory": ["p1"]}}),
		"snuglo.nook.v2": JSON.stringify({"placed": {"cozy-beginnings": 2}}),
		"snuglo.tower.bestFloor.v1": 7, "snuglo.tower.currentFloor.v1": 3,
		"snuglo.relaxedReward.v1": JSON.stringify({"day": "2026-05-02", "xp": 20, "coin": 10}),
		"snuglo.purchased.v1": ["com.snuglo.removeads", "com.snuglo.pack.spice_route"],
		"snuglo.premium.active": false, "snuglo.ads.removed": true,
		"snuglo.ads.rewarded.count": 4, "snuglo.ads.rewarded.day": 20000, "snuglo.ads.rewarded.last": 1.78e9,
		"snuglo.version.dismissedSoft": "1.3.0",
		"musicVolume": 0.4, "sfxEnabled": false, "hapticsEnabled": false, "zenMode": true,
		"musicTrack": "zen", "hapticLevel": "light", "soundPack": "soft", "appTheme": 2,
		"dailyReminderEnabled": true, "comebackRemindersEnabled": true, "hasOnboarded": true,
		"snuglo.language.override": "es",
	}
	var n: int = save.import_legacy(legacy)
	var p := _node("Progress")
	var w := _node("Wallet")
	var st := _node("Settings")
	_check("legacy: anahtarlar işlendi", n >= 35, str(n))
	_check("legacy: bölümler", p.is_completed("cozy-beginnings-1") and p.stars("cozy-beginnings-1") == 3 \
		and is_equal_approx(p.best_time("cozy-beginnings-1"), 22.5) and p.level("cozy-beginnings-1").completed_at == "2026-05-01" \
		and p.level("cozy-beginnings-1").hints_used == 0 and p.total_completed() == 2 and p.level("tower-3").is_empty())
	_check("legacy: günlük + seriler", p.daily_history()["2026-05-02"].count == 4 and p.daily_longest == 4 \
		and p.longest_play_streak == 5 and p.streak_freezes == 2 and p.endless_best == 14)
	_check("legacy: cüzdan", w.coins == 1500 and w.gems == 42 and w.tickets == 3 and w.cups == 1 \
		and w.hints == 7 and w.keys == 2)
	_check("legacy: xp/başarım/sandık", _node("XP").level == 3 and _node("Achievements").is_unlocked("firstSteps") \
		and _node("Achievements").unlocked_count() == 2 and _node("Chest").pending == 1 and _node("Chest").progress == 3)
	_check("legacy: kozmetik eşleme", _node("Cosmetics").is_fabric_unlocked("midnight") \
		and _node("Cosmetics").selected_fabric == "meadow" and _node("Cosmetics").selected_board == "ember")
	_check("legacy: paket ödülü bekliyor", p.pending_pack_reward() == "spice-route")
	_check("legacy: enerji/kule/nook", _node("Energy").now_override < 0 and int(save.get_section("energy").value) == 23 \
		and _node("Tower").best_floor == 7 and _node("Tower").current_floor == 3 and _node("Nook").placed_pieces("cozy-beginnings") == 2)
	var sess: Dictionary = p.get_session("cozy-beginnings-3")
	_check("legacy: yarım bölüm", sess.elapsed == 33 and sess.placements[0].piece == "p1" and sess.placements[0].y == 2)
	_check("legacy: satın alma önbelleği", _node("Purchases").ads_removed() and not _node("Purchases").is_premium() \
		and _node("Purchases").owns("com.snuglo.removeads") and not _node("Purchases").owns("com.snuglo.pack.spice_route"))
	_check("legacy: ayarlar", is_equal_approx(st.music_volume, 0.4) and not st.sfx_enabled and not st.haptics \
		and st.zen_mode and st.music_track == "zen" and st.daily_reminder and st.language == "es" \
		and st.get_value("theme") == 2 and st.get_value("haptic_level") == "light")
	_check("legacy: ikinci kez uygulanmaz", save.import_legacy(legacy) == 0)
	st.zen_mode = false
	st.language = "en"
