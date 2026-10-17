extends Screen
## Oyun ekranı: Game (tahta+tepsi) + HUD + sistem bağlantıları.
## Süre (kampanya/günlük geri sayım, Kule kat süresi; zen/endless yukarı sayar), başarısızlık,
## güçlendirmeler (Wallet.pay_powerup), kombo, övgü, Progress.record_level (bir kez), sonuç kartı,
## yarım kalan oturum kaydı/geri yükleme, ilk bölüm öğreticisi. args: level (id), dev_solve, dev_sheet.

const TutorialOverlay := preload("res://scripts/game/tutorial_overlay.gd")

var id := ""
var mode := "campaign"
var floor_n := 0
var relaxed := false
var limit := 0
var lvl: LevelData
var game: Game
var hud: GameHud
var _bg: SceneBackdrop
var _free_peek := 1
var _combo := 0
## Övgü kelime havuzları: anahtar → varyant sayısı (i18n praise.<havuz>.<n>, ses audio/voice/<dil>/<anahtar>).
const PRAISE := {"t1": 3, "t2": 3, "t3": 3, "t4": 4, "t5": 4, "near": 3, "final": 3}
var _fresh_n := 0   ## bu denemede oyuncunun ilk kez yerleştirdiği parça sayısı (övgü yazısı)
var _last_place := -10.0
var _failed := false
var _result := {}
var _sheets := 0
var _covered := false
var _acc := 0.0
var _tutorial: Control

func build() -> void:
	id = String(args.get("level", "cozy-beginnings-1"))
	for m in ["daily", "endless", "tower"]:
		if id.begins_with(m):
			mode = m
	var parts := Progress.split_id(id)
	floor_n = int(parts[1])
	lvl = Main.level_data(id)
	relaxed = mode == "endless" or (Settings.zen_mode and mode != "tower")
	if mode == "tower":
		limit = Tower.time_limit(floor_n)
	elif not relaxed:
		limit = Progress.time_limit(lvl.width, lvl.height)
	_bg = SceneBackdrop.new()
	_bg.tex = PackArt.scene_by_name(_scene_name())
	_bg.wash_top = 0.15
	_bg.wash_bottom = 0.9
	_bg.motes = 10
	_bg.size = size
	add_child(_bg)
	var restore := {}
	if Progress.is_resumable(id):
		var s := Progress.get_session(id)
		if String(s.get("fingerprint", "")) == _fingerprint():
			for p in s.get("placements", []):
				restore[String(p.piece)] = Vector2i(int(p.x), int(p.y))
			_start_game(restore, float(s.get("elapsed", 0.0)), int(s.get("hints", 0)))
			return
	_start_game({}, Tower.saved_elapsed(floor_n) if mode == "tower" else 0.0)

func _scene_name() -> String:
	match mode:
		"daily": return ["flower", "beach", "lake", "forest", "island", "snow", "autumn"][Progress.local_date(true).day % 7]
		"endless": return "lake"
		"tower": return "volcano"
	return PackArt.scene_name(String(Progress.split_id(id)[0]))

func _title() -> Array:
	match mode:
		"daily": return [tr("game.title.daily"), tr("daily.level") % [floor_n + 1, Progress.DAILY_LEVELS]]
		"endless": return [tr("endless.title"), tr("level.label") % floor_n]
		"tower": return [tr("tower.title"), tr("tower.floor") % floor_n]
	return [tr(Progress.pack(String(Progress.split_id(id)[0])).get("title", "")), tr("level.label") % floor_n]

func _fingerprint() -> String:
	var ids := []
	for p in lvl.pieces:
		ids.append(p.id)
	return "%dx%d:%s" % [lvl.width, lvl.height, ",".join(ids)]

func _start_game(restore: Dictionary, elapsed := 0.0, hints := 0) -> void:
	if game:
		game.queue_free()
	_failed = false
	_combo = 0
	_fresh_n = 0
	game = Game.new()
	game.use_backdrop = false
	add_child(game)
	hud = GameHud.new()
	game.add_child(hud)
	var t := _title()
	hud.setup(t[0], t[1], limit == 0)
	game.area_top = hud.top_h
	game.area_bottom = size.y - hud.bottom_h
	game.start(lvl, restore)
	game.elapsed = elapsed
	game.hints_used = hints
	game.move_child(hud, game.get_child_count() - 1)
	game.placed.connect(_on_placed)
	game.invalid_drop.connect(func() -> void: _combo = 0)
	game.solve_started.connect(_on_solve_started)
	game.solved.connect(_on_solved)
	hud.pause_pressed.connect(open_pause)
	hud.powerup.connect(_powerup)
	hud.set_chain(Progress.win_chain)
	_refresh_powerups()
	_update_timer()
	Dev.attach(game)
	if id == "cozy-beginnings-1" and not bool(Settings.get_value("coach_shown")) and restore.is_empty():
		_tutorial = TutorialOverlay.new()
		game.add_child(_tutorial)
		_tutorial.setup(game)
		game.picked.connect(func() -> void:
			if is_instance_valid(_tutorial):
				_tutorial.dismiss()
				Settings.set_value("coach_shown", true), CONNECT_ONE_SHOT)

func on_enter() -> void:
	var spent := Energy.consume_spend_animation()
	if spent > 0 and hud:
		hud.float_energy(spent)
	if args.get("dev_solve", false):
		await get_tree().create_timer(0.8).timeout
		for p in lvl.pieces:
			if not is_instance_valid(game) or game.done:
				break
			if game.placements.get(p.id, Vector2i(-99, -99)) != lvl.solution[p.id]:
				game._place(game.pieces[p.id], lvl.solution[p.id], true)
				await get_tree().create_timer(0.12).timeout
	var dev_sheet := String(args.get("dev_sheet", ""))
	if OS.get_environment("SNUG_TIMEUP") != "":
		dev_sheet = "fail"   # Geliştirme: süre doldu akışı (Kule'de tower_over)
	match dev_sheet:
		"pause":
			await get_tree().create_timer(0.8).timeout
			open_pause()
		"fail":
			await get_tree().create_timer(0.8).timeout
			_time_up()

# ------------------------------------------------------------------ Süre

func _process(dt: float) -> void:
	if game == null or not is_instance_valid(game):
		return
	game.paused = _sheets > 0 or _covered or _failed
	_update_timer()
	if limit > 0 and not game.done and not _failed and game.elapsed >= limit:
		_time_up()
	_acc += dt
	if _acc >= 0.5:
		_acc = 0.0
		_refresh_powerups()

func _update_timer() -> void:
	if limit > 0:
		var rem := maxf(0.0, limit - game.elapsed)
		hud.set_time(rem, rem <= 30.0)
	else:
		hud.set_time(game.elapsed, false)

func _time_up() -> void:
	if _failed or game.done:
		return
	_failed = true
	Sfx.play("error", 0.8, 0.0, 0.0)
	Juice.add_trauma(0.4)
	Juice.haptic("heavy")
	Progress.clear_session(id)
	if mode == "tower":
		var r := Tower.end_run()
		_track(Main.open("tower_over", {"floors": r.floors, "coins": r.coins, "best": Tower.best_floor, "screen": self}))
	else:
		Progress.break_chain()
		Energy.end_paid_session(id)
		_track(Main.open("fail", {"level": id, "screen": self}))

# ------------------------------------------------------------------ Sheet / duraklatma

## Açık sheet'leri say: açıkken oyun duraklar.
func _track(sh: Sheet) -> Sheet:
	if sh == null:
		return null
	_sheets += 1
	sh.closed.connect(func() -> void: _sheets = maxi(0, _sheets - 1))
	return sh

func open_pause() -> void:
	if game.done or _failed or _sheets > 0:
		return
	_track(Main.open("pause", {"level": id, "screen": self}))

func on_back() -> bool:
	if not game.done and not _failed:
		open_pause()
	return true

func on_cover(covered: bool) -> void:
	_covered = covered

func is_relaxed() -> bool:
	return relaxed

## Tahtayı baştan kur (yeniden başlat / tekrar dene). charge: enerji ücreti alınsın mı.
func restart(charge := true) -> bool:
	if charge and not Energy.charge_restart(id):
		Main.open("energy", {"level": id})
		return false
	Progress.break_chain()
	Progress.clear_session(id)
	_start_game({})
	Juice.add_trauma(0.15)
	return true

## Ana menüye çık (zincir kırılır; yarım oturum kaydedilir). Devam edilecek oturum yoksa ücretli
## giriş kapanır → aynı bölüme yeniden girmek yine enerji ister.
func quit() -> void:
	Progress.break_chain()
	_save_session()
	if Progress.get_session(id).is_empty():
		Energy.end_paid_session(id)
	Main.home()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_save_session()

func _save_session() -> void:
	if mode == "tower" and game != null and is_instance_valid(game) and not game.done and not _failed:
		Tower.save_elapsed(floor_n, game.elapsed)
	if game == null or not is_instance_valid(game) or game.done or _failed or game.placements.is_empty():
		return
	if not Progress.is_resumable(id):
		return
	var pl := []
	for pid in game.placements:
		var o: Vector2i = game.placements[pid]
		pl.append({"piece": pid, "x": o.x, "y": o.y})
	Progress.save_session(id, {"fingerprint": _fingerprint(), "placements": pl, "elapsed": game.elapsed,
		"hints": game.hints_used, "moves": game.history.size(), "history": game.history.duplicate()})

func _exit_tree() -> void:
	_save_session()

# ------------------------------------------------------------------ Yerleşim / kombo

func _board_top_center() -> Vector2:
	return Vector2(size.x / 2.0, game.board.position.y + game.cs * 0.6)

func _on_placed(by_player: bool, fresh: bool) -> void:
	_save_session()
	# Yalnız tepsiden ilk kez gelen parça komboyu sürdürür; tahtadaki parçayı oynatmak coin üretmez.
	if not by_player or not fresh or game.done:
		return
	var now := Time.get_ticks_msec() / 1000.0
	_combo = _combo + 1 if now - _last_place <= Progress.COMBO_WINDOW else 1
	_last_place = now
	_fresh_n += 1
	# Kumaş övgü yazısı: ilk yerleşimde ve bölümü bitiren son parçada yok (çözüm övgüsü gelir).
	var last := game.placements.size() >= lvl.pieces.size()
	if _fresh_n >= 2 and not last:
		var pool := "near" if game.board.filled_ratio() >= 0.8 else "t%d" % clampi(_combo, 1, 5)
		_praise_word(pool, "×%d" % _combo if _combo >= 2 else "")
	if _combo < 2:
		return
	var r := Progress.award_combo(_combo, relaxed)
	if r.milestone:
		Sfx.play("reward", 1.0 + _combo * 0.03, -4.0)
		Juice.haptic("heavy")
		Juice.add_trauma(0.3)
		game.fx.sparks(_board_top_center(), 18, Palette.GOLD, 600.0)
	else:
		Sfx.play("combo", 1.0 + _combo * 0.05, -6.0)
	if int(r.coins) > 0:
		Fly.currency(_board_top_center(), "coin", int(r.coins))

## Yerleşen parçanın üstünde (yer yoksa altında) kumaş harfli övgü; tahta içinde kalır, HUD'a girmez.
func _praise_key(pool: String) -> String:
	return "praise.%s.%d" % [pool, randi_range(1, int(PRAISE.get(pool, 1)))]

func _praise_word(pool: String, sub: String) -> void:
	var key := _praise_key(pool)
	var text := tr(key)
	Sfx.voice(key)
	var tier := 5 if pool == "near" else int(pool.substr(1)) if pool.begins_with("t") else 3
	var bp := game.board.position
	var gp := game.board.grid_px()
	var fs := int(clampf(game.cs * 1.0, 72.0, 150.0))
	var sz := FabricWord.measure(text, fs)
	while sz.x > gp.x + game.cs * 0.3 and fs > 36:
		fs -= 4
		sz = FabricWord.measure(text, fs)
	var r: Rect2 = game.last_rect
	var hh := sz.y / 2.0 + (fs * 0.45 if sub != "" else 0.0)
	var top_lim := maxf(hud.top_h, bp.y - game.cs * 0.35)
	var bot_lim := bp.y + gp.y + game.cs * 0.35
	var c := Vector2(r.get_center().x, r.position.y - sz.y * 0.45)
	if c.y - hh < top_lim:
		c.y = r.end.y + sz.y * 0.45          # üstte yer yok → parçanın altı
		if c.y + hh > bot_lim:
			c.y = r.get_center().y           # altta da yok → parçanın üstüne bindir
	c.x = clampf(c.x, bp.x + sz.x / 2.0, bp.x + gp.x - sz.x / 2.0) if sz.x < gp.x else bp.x + gp.x / 2.0
	c.y = clampf(c.y, top_lim + hh, bot_lim - hh)
	FabricWord.show_at(hud, text, c, fs, {sub = sub, hold = 0.55 + tier * 0.06})
	if tier >= 3:
		game.fx.sparks(c, 6 + tier * 2, Palette.CREAM, 380.0)

func _on_solve_started() -> void:
	Progress.clear_session(id)
	_result = Progress.record_level(id, game.elapsed, game.hints_used, lvl.width, 1 if relaxed else 0)
	if mode != "tower":
		Ads.on_level_completed()
	var key := _praise_key("final")
	var text := tr(key)
	if mode == "tower":
		text = tr("tower.floorUp")
	elif mode == "endless" and _result.get("endless_record", false):
		text = tr("endless.record")
	var gp := game.board.grid_px()
	var fs := 112
	while FabricWord.measure(text, fs).x > gp.x + game.cs * 0.6 and fs > 48:
		fs -= 4
	if mode != "tower" and not (mode == "endless" and _result.get("endless_record", false)):
		Sfx.voice(key)
	FabricWord.show_at(hud, text, game.board.position + gp / 2.0, fs, {hold = 1.1})
	hud.set_chain(int(_result.get("chain", 0)))

func _on_solved(_stars: int, _secs: float) -> void:
	if mode == "tower":
		await get_tree().create_timer(0.3).timeout
		Main.replace("game", {"level": "tower-%d" % (floor_n + 1)})
		return
	_track(Main.open("levelcomplete", {"res": _result, "level": id, "screen": self}))

# ------------------------------------------------------------------ Güçlendirmeler

func _powerup(kind: String) -> void:
	if game.done or game.paused:
		return
	match kind:
		"hint":
			if not game.can_hint():
				return
			if Wallet.hints > 0 or Wallet.can_afford("gem", int(Wallet.POWERUP_COST.hint)):
				var paid := Wallet.pay_powerup("hint")
				if not game.hint():
					Wallet.refund_powerup("hint", paid)
			elif Ads.rewarded_ready():
				Ads.show_rewarded(func() -> void: game.hint())
			else:
				_insufficient()
		"peek":
			if not game.can_peek():
				return
			if _free_peek > 0:
				_free_peek -= 1
				game.peek()
			elif Wallet.can_afford("gem", int(Wallet.POWERUP_COST.peek)):
				var paid := Wallet.pay_powerup("peek")
				if not game.peek():
					Wallet.refund_powerup("peek", paid)
			elif Ads.rewarded_ready():
				Ads.show_rewarded(func() -> void: game.peek())
			else:
				_insufficient()
		"shuffle":
			if game.placements.is_empty():
				return
			if Wallet.can_afford("gem", int(Wallet.POWERUP_COST.shuffle)):
				var paid := Wallet.pay_powerup("shuffle")
				if not game.reset_board():
					Wallet.refund_powerup("shuffle", paid)
				_combo = 0
			else:
				_insufficient()
	_refresh_powerups()

func _insufficient() -> void:
	_track(Main.confirm(tr("powerup.insufficient.gem.title"), tr("powerup.insufficient.gem.message"),
		tr("powerup.insufficient.gem.cta"), func() -> void: Main.open_shop()))

func _refresh_powerups() -> void:
	if hud == null or game == null:
		return
	var gems := Wallet.gems
	var ad := Ads.rewarded_ready()
	var hc := int(Wallet.POWERUP_COST.hint)
	var can_h := game.can_hint()
	if Wallet.hints > 0:
		hud.set_power("hint", "×%d" % Wallet.hints, "count", can_h)
	elif gems >= hc:
		hud.set_power("hint", str(hc), "gem", can_h)
	elif ad:
		hud.set_power("hint", tr("powerup.free"), "ad", can_h)
	else:
		hud.set_power("hint", str(hc), "gem", false)
	var pc := int(Wallet.POWERUP_COST.peek)
	var can_p := game.can_peek()
	if _free_peek > 0:
		hud.set_power("peek", "×1", "count", can_p)
	elif gems >= pc:
		hud.set_power("peek", str(pc), "gem", can_p)
	elif ad:
		hud.set_power("peek", tr("powerup.free"), "ad", can_p)
	else:
		hud.set_power("peek", str(pc), "gem", false)
	var sc := int(Wallet.POWERUP_COST.shuffle)
	hud.set_power("shuffle", str(sc), "gem", not game.placements.is_empty() and gems >= sc and not game.done)
