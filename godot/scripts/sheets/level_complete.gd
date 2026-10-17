extends Sheet
## Bölüm sonucu: ışınlar + paket dostu/maskot, başlık, 3 işlemeli yıldız tek tek "damgalanır",
## yeni rekor, süre/en iyi hapları, sayarak artan ödül çipleri → coin/gem üst bara uçar, zincir ve
## sandık rozetleri, Nook parçası açılışı, Sonraki / Tekrar / Ana menü.
## args: res (Progress.record_level sonucu), level (id), screen (GameScreen).

var res := {}
var id := ""
var mode := "campaign"
var _fx: Fx
var _chips: Array[Control] = []
var _bar: TopBar
var _share_sub := ""

func _init() -> void:
	dismissible = false
	panel_size = Vector2(-1, 1300)
	dim_alpha = 0.6

func build() -> void:
	res = args.get("res", {})
	id = String(args.get("level", res.get("level_id", "")))
	mode = String(res.get("mode", "campaign"))
	var w := pw()
	var scr = args.get("screen")
	if scr and is_instance_valid(scr) and scr.hud:
		scr.hud.create_tween().tween_property(scr.hud, "modulate:a", 0.0, 0.25)
	_bar = TopBar.new()
	_bar.currencies = ["coin", "gem"]
	_bar.tap_to_shop = false
	_bar.position = Vector2((size.x - 560) / 2.0, Ui.safe_top() + 30)
	_bar.size = Vector2(560, 110)
	add_child(_bar)
	var rewards := {"coin": int(res.get("coins", 0)), "gem": int(res.get("gems", 0))}
	Fly.hold(rewards)
	# Kahraman
	var rays := Rays.new()
	rays.size = Vector2(820, 820)
	rays.position = Vector2(w / 2.0 - 410, -420)
	panel.add_child(rays)
	panel.move_child(rays, 0)
	var pid := String(Progress.split_id(id)[0])
	var tex: Texture2D = PackArt.animal(pid, "cheer") if mode == "campaign" else UiArt.tex("cheer", "mascot")
	var hero := Ui.tex_rect(tex, Vector2(320, 320))
	add(hero, Vector2((w - 320) / 2.0, -225))
	Ui.pop_in(hero, 0.1, 0.2, 0.6)
	Ui.bob(hero, 8.0, 1.5)
	var title := tr("complete.dailyAllDone") if res.get("daily_all_done", false) else tr("complete.puzzleSolved")
	var y := _ribbon(title, 110, 760)
	var sub := ""
	match mode:
		"campaign": sub = "%s · %s" % [tr(Progress.pack(pid).get("title", "")), tr("level.label") % int(Progress.split_id(id)[1])]
		"daily": sub = tr("daily.level") % [int(res.get("daily_index", 0)) + 1, Progress.DAILY_LEVELS]
		"endless": sub = "%s · %s" % [tr("endless.title"), tr("level.label") % int(Progress.split_id(id)[1])]
	_share_sub = sub
	if sub != "":
		var sl := Ui.label(sub, 34, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		add(sl, Vector2(0, y - 14), Vector2(w, 46))
		y += 40
	# Yıldızlar
	y += 20
	var stars := int(res.get("stars", 0))
	for i in 3:
		var s := 180.0 if i == 1 else 150.0
		var st := Ui.icon("ic_star", Vector2(s, s))
		var cx := w / 2.0 + (i - 1) * 200.0
		add(st, Vector2(cx - s / 2.0, y + (0.0 if i == 1 else 34.0)))
		_stamp(st, i < stars, 0.45 + i * 0.3, i)
	y += 220
	if res.get("new_best", false):
		var nb := Ui.badge(tr("complete.newBest"), Palette.FLAME)
		(nb as Badge).fs = 34
		add(nb, Vector2(w / 2.0 - 110, y - 26))
		nb.get_tree().create_timer(1.4).timeout.connect(func() -> void:
			nb.position.x = (w - nb.size.x) / 2.0
			Ui.pop_in(nb, 0.0, 0.2)
			Sfx.play("levelUp", 1.2, -6.0))
		nb.modulate.a = 0.0
		y += 40
	# Süre hapları
	var pills := [[tr("complete.time"), Ui.fmt_time(float(res.get("seconds", 0.0)))]]
	if mode == "campaign":
		pills.append([tr("complete.bestTime"), Ui.fmt_time(Progress.best_time(id))])
	var pw2 := 300.0
	var px := (w - (pills.size() * pw2 + (pills.size() - 1) * 24)) / 2.0
	for i in pills.size():
		var pill := QuiltCard.new()
		pill.fill = Palette.CREAM
		pill.radius = 34
		pill.depth = 6
		add(pill, Vector2(px + i * (pw2 + 24), y), Vector2(pw2, 96))
		var k := Ui.label(pills[i][0], 26, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(k, Vector2(0, 6), Vector2(pw2, 34))
		pill.add_child(k)
		var v := Ui.label(pills[i][1], 42, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(v, Vector2(0, 36), Vector2(pw2, 52))
		pill.add_child(v)
		Ui.pop_in(pill, 0.9 + i * 0.08, 0.6)
	y += 126
	# Ödül çipleri
	var list := []
	for c in ["coin", "gem", "key"]:
		var key: String = {"coin": "coins", "gem": "gems", "key": "keys"}[c]
		if int(res.get(key, 0)) > 0:
			list.append([c, int(res.get(key, 0))])
	if int(res.get("xp", 0)) > 0:
		list.append(["xp", int(res.xp)])
	var cw := 190.0
	var cx0 := (w - (list.size() * cw + (list.size() - 1) * 18)) / 2.0
	for i in list.size():
		var c: String = list[i][0]
		var amt: int = list[i][1]
		var chip := QuiltCard.new()
		chip.fill = Palette.CREAM
		chip.radius = 38
		chip.depth = 8
		add(chip, Vector2(cx0 + i * (cw + 18), y), Vector2(cw, 170))
		var ic := Ui.icon(Ui.currency_icon(c), Vector2(84, 84))
		Ui.place(ic, Vector2((cw - 84) / 2.0, 8), Vector2(84, 84))
		chip.add_child(ic)
		if c == "xp":
			var xl := Ui.title("XP", 30)
			Ui.place(xl, Vector2(0, 30), Vector2(cw, 40))
			chip.add_child(xl)
		var l := Ui.label("+0", 44, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(l, Vector2(0, 96), Vector2(cw, 60))
		chip.add_child(l)
		chip.set_meta("c", c)
		chip.set_meta("amt", amt)
		_chips.append(chip)
		Ui.pop_in(chip, 1.2 + i * 0.12, 0.3)
		get_tree().create_timer(1.3 + i * 0.12).timeout.connect(func() -> void:
			if is_instance_valid(l):
				Ui.tick(l, 0, amt, 0.6, "+%d"))
	if not list.is_empty():
		y += 190
	# Zincir + sandık rozetleri
	var tags := []
	if int(res.get("chain", 0)) >= 2:
		tags.append([tr("chain.label") % int(res.chain), Palette.MUSTARD.darkened(0.15)])
	if res.get("chest_ready", false):
		tags.append([tr("chest.ready"), Palette.SAGE.darkened(0.1)])
	if not tags.is_empty():
		var tx := 70.0
		for t in tags:
			var b := Ui.badge(t[0], t[1])
			(b as Badge).fs = 30
			add(b, Vector2(tx, y))
			tx += Ui.FONT.get_string_size(t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 60
			Ui.pop_in(b, 1.7, 0.3)
		y += 70
	# Butonlar
	y += 10
	var next := _next_id()
	var nxt := Ui.button(tr("complete.next") if next != "" else tr("complete.home"), "terracotta", Vector2(w - 140, 160))
	var short := next != "" and not Energy.can_start_game() and not Energy.is_free_level(next)
	if short:
		nxt.text = tr("complete.outOfEnergy")
		nxt.skin = UiArt.tex("btn_mustard")
		nxt.icon = UiArt.tex("ic_energy")
	add(nxt, Vector2(70, y))
	nxt.tapped.connect(func() -> void:
		if next == "":
			close()
			Main.home()
		elif short:
			Main.open("energy", {"level": next})
		else:
			close()
			Main.play(next))
	Ui.pop_in(nxt, 1.5, 0.5)
	y += 180
	var bw := (w - 160) / 2.0
	var replay := Ui.button(tr("complete.replay"), "sage", Vector2(bw, 130))
	add(replay, Vector2(70, y))
	replay.tapped.connect(func() -> void:
		close()
		Main.play(id))
	Ui.pop_in(replay, 1.6, 0.6)
	var home := Ui.button(tr("complete.home"), "mustard", Vector2(bw, 130), "ic_home")
	add(home, Vector2(90 + bw, y))
	home.tapped.connect(func() -> void:
		close()
		Main.home())
	Ui.pop_in(home, 1.65, 0.6)
	panel.size.y = y + 170
	# Sonucu paylaş (Swift ResultCard): panelin sağ üst köşesinde, kurdelenin üstünde.
	var share := Ui.icon_button("ic_share", 112)
	add(share, Vector2(w - 146, -34))
	share.tapped.connect(_share)
	Ui.pop_in(share, 1.8, 0.4)
	_place_panel()
	panel.position.y = maxf(Ui.safe_top() + 330.0, panel.position.y + 90)
	if panel.position.y + panel.size.y > size.y - Ui.safe_bottom() - 10:
		panel.position.y = maxf(Ui.safe_top() + 230.0, size.y - Ui.safe_bottom() - 10 - panel.size.y)
	_fx = Fx.new()
	add_child(_fx)
	get_tree().create_timer(0.3).timeout.connect(func() -> void:
		_fx.confetti(Vector2(-20, size.y * 0.55), 60, PI * 0.18, -PI * 0.3, 2000.0)
		_fx.confetti(Vector2(size.x + 20, size.y * 0.55), 60, PI * 0.18, -PI * 0.7, 2000.0))
	get_tree().create_timer(2.1).timeout.connect(_fly)
	if int(res.get("nook_piece", -1)) >= 0 and mode == "campaign":
		get_tree().create_timer(2.8).timeout.connect(_nook_reveal.bind(pid, int(res.nook_piece)))

func _share() -> void:
	var st := int(res.get("stars", 0))
	var stars := "★".repeat(st) + "☆".repeat(3 - st)
	var lines := ["Snuglo — %s %s" % [tr("share.solved"), stars]]
	if _share_sub != "":
		lines.append(_share_sub)
	var info := "%s %s" % [tr("share.time"), Ui.fmt_time(float(res.get("seconds", 0.0)))]
	if Progress.play_streak > 0:
		info += " · %s %d" % [tr("share.streak"), Progress.play_streak]
	lines.append(info)
	lines.append("Snuglo · " + tr("share.tagline"))
	Share.share(self, "\n".join(lines))

func _stamp(st: Control, filled: bool, delay: float, i: int) -> void:
	st.pivot_offset = st.size / 2.0
	st.modulate = Color(1, 1, 1, 0) if filled else Color(0.5, 0.45, 0.42, 0.0)
	st.scale = Vector2(2.4, 2.4)
	var target_a := 1.0 if filled else 0.5
	var tw := st.create_tween()
	tw.tween_interval(delay)
	tw.set_parallel()
	tw.tween_property(st, "scale", Vector2.ONE * 0.9, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(st, "modulate:a", target_a, 0.1)
	tw.set_parallel(false)
	tw.tween_callback(func() -> void:
		if filled:
			Sfx.note(4 + i * 2, "levelUp", -4.0)
			Juice.haptic("medium")
			Ui.shake(panel, 8.0 + i * 4)
			_fx.sparks(st.global_position + st.size / 2.0, 18, Palette.GOLD, 700.0)
			_fx.ring(st.global_position + st.size / 2.0, 110.0, Palette.GOLD, 12.0)
		else:
			Sfx.play("click", 0.7, -6.0))
	tw.tween_property(st, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _fly() -> void:
	for ch in _chips:
		if not is_instance_valid(ch):
			continue
		var c: String = ch.get_meta("c")
		if c in ["coin", "gem", "key"]:
			Fly.currency(ch.global_position + ch.size / 2.0, c, int(ch.get_meta("amt")))
			Ui.punch(ch, 0.12)

func _nook_reveal(pid: String, piece: int) -> void:
	if not is_inside_tree() or _closing:
		return
	Main.open("nook_reveal", {"pack": pid, "piece": piece, "on_place": _go_nook.bind(pid), "on_later": func() -> void: pass})

func _go_nook(pid: String) -> void:
	close()
	Main.replace("nook", {"pack": pid})

func _next_id() -> String:
	var n := int(Progress.split_id(id)[1])
	match mode:
		"daily":
			return "" if Progress.is_daily_all_complete() else "daily-%d" % Progress.daily_next_index()
		"endless":
			return "endless-%d" % (n + 1)
		"campaign":
			return Progress.next_level_id(id)
	return ""

func on_back() -> bool:
	return true


func _ribbon(text: String, y: float, w := 680.0) -> float:
	var b := Ui.banner(text, w)
	add(b, Vector2((pw() - b.size.x) / 2.0, y))
	Ui.pop_in(b, 0.15, 0.4)
	return y + b.size.y + 10.0
