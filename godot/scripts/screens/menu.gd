extends Screen
## Ana menü merkezi: yaşayan yorgan manzarası + maskot, üst bar (XP halkası, enerji/coin/gem),
## seri alevi + selam/görev çipi + ayarlar, büyük Oyna/Devam, Günlük kartı, Mod kartları
## (Zen anahtarı, Endless, Kule), ödül menüsü (günlük giriş, çark, sandık, görevler), premium tacı,
## alt rıhtım (Mağaza, Nook, Harita, Başarımlar, İstatistik). Girişte bekleyen kutlamalar sırayla.

var _bg: SceneBackdrop
var _mascot: TextureRect
var _rewards_btn: JuicyButton
var _rewards_badge: Badge
var _nook_badge: Badge
var _dropdown: Control
var _daily_timer: Label
var _queue: Array[Callable] = []
var _acc := 0.0
var _anim: Array[Control] = []

func build() -> void:
	var target := Progress.continue_target()
	var pid: String = Progress.split_id(target)[0] if target != "" else "cozy-beginnings"
	_bg = SceneBackdrop.new()
	_bg.tex = PackArt.scene(pid)
	_bg.wash_top = 0.35
	_bg.wash_bottom = 0.8
	_bg.size = size
	add_child(_bg)
	if Settings.zen_mode:
		_bg.darken = 0.0
		_bg.modulate = Color(0.86, 0.95, 0.86)

	# Dikey düzen: sabit bloklar + esnek boşluklar.
	var dock_h := 190.0
	var fixed := [120.0, 84.0, 250.0, 330.0, 190.0, 200.0, 240.0]
	var gaps_w := [0.0, 0.6, 0.5, 0.2, 0.6, 0.45, 0.45, 0.7]
	var avail := H - TOP - BOTTOM - dock_h - 24.0
	var used := 0.0
	for f in fixed:
		used += f
	var free := maxf(0.0, avail - used)
	var wsum := 0.0
	for g in gaps_w:
		wsum += g
	var ys := []
	var y := TOP + 20.0
	for i in fixed.size():
		y += free * gaps_w[i] / wsum
		ys.append(y)
		y += fixed[i]

	_top_row(ys[0])
	_chip_row(ys[1])
	_logo(ys[2])
	_hero(ys[3])
	_play(ys[4], target)
	_daily(ys[5])
	_modes(ys[6])
	_dock(H - BOTTOM - dock_h, dock_h)
	_refresh_badges()
	Ui.stagger(_anim, 0.04, 0.05)

func _top_row(y: float) -> void:
	var ring := Widgets.XpRing.new()
	ring.level = XP.level
	ring.frac = XP.fraction
	var hit := JuicyButton.new()
	hit.skin = null
	hit.draw_flat_bg = false
	put(hit, Vector2(X0 + 26, y), Vector2(124, 124))
	hit.add_child(ring)
	ring.size = Vector2(124, 124)
	hit.tapped.connect(func() -> void: Main.push("profile"))
	_anim.append(hit)
	var bar := TopBar.new()
	put(bar, Vector2(X0 + 170, y + 14), Vector2(W - 196, 110))

func _chip_row(y: float) -> void:
	# Seri alevi
	var streak := Progress.play_streak
	var sc := QuiltCard.new()
	sc.pressable = true
	sc.fill = Palette.CARD
	sc.radius = 42
	sc.depth = 6
	put(sc, Vector2(X0 + 30, y), Vector2(190, 84))
	var fl := Widgets.Flame.new()
	fl.lit = streak > 0
	Ui.place(fl, Vector2(16, 6), Vector2(60, 72))
	sc.add_child(fl)
	var sl := Ui.label(str(streak), 44, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(sl, Vector2(76, 0), Vector2(96, 84))
	sc.add_child(sl)
	sc.tapped.connect(func() -> void:
		Main.toast(tr("menu.streak.days") % streak if streak > 0 else tr("menu.streak.start"), "", Palette.FLAME)
		Ui.punch(fl, 0.4))
	_anim.append(sc)
	# Selam + görevler
	var qn := Quests.completed_count()
	var gc := QuiltCard.new()
	gc.pressable = true
	gc.fill = Palette.CARD
	gc.radius = 42
	gc.depth = 6
	var gw := W - 30 - 190 - 24 - 24 - 110 - 30
	put(gc, Vector2(X0 + 244, y), Vector2(gw, 84))
	var gl := Ui.label("%s  ·  %d/3" % [_greeting(), qn], 34, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	gl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(gl, Vector2(20, 0), Vector2(gw - 40, 84))
	gc.add_child(gl)
	if qn >= 3:
		gl.add_theme_color_override("font_color", Palette.SAGE.darkened(0.3))
	gc.tapped.connect(func() -> void: Main.open("quests"))
	_anim.append(gc)
	# Ayarlar
	var gear := Ui.icon_button("ic_settings", 110)
	put(gear, Vector2(X0 + W - 140, y - 13), Vector2(110, 110))
	gear.tapped.connect(func() -> void: Main.push("settings"))
	_anim.append(gear)

func _greeting() -> String:
	var h: int = Time.get_datetime_dict_from_system().hour
	var k := "night" if h < 6 else ("morning" if h < 12 else ("afternoon" if h < 18 else "evening"))
	return tr("today.greeting." + k)

func _logo(y: float) -> void:
	var tex := UiArt.tex("logo")
	var h := 250.0
	var w := minf(W - 200, tex.get_width() * h / tex.get_height())
	var logo := Ui.icon("logo", Vector2(w, h))
	put(logo, Vector2(X0 + (W - w) / 2.0, y))
	Ui.pop_in(logo, 0.1, 0.3, 0.6)
	Ui.bob(logo, 7.0, 3.2)

func _hero(y: float) -> void:
	var s := 330.0
	_mascot = Ui.icon("idle", Vector2(s, s), "mascot")
	var shadow := Shadow.new()
	put(shadow, Vector2(X0 + W / 2.0 - 130, y + s - 34), Vector2(260, 44))
	put(_mascot, Vector2(X0 + (W - s) / 2.0, y))
	Ui.pop_in(_mascot, 0.25, 0.2, 0.6)
	Ui.bob(_mascot, 9.0, 2.6)
	var hit := Control.new()
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	put(hit, _mascot.position, Vector2(s, s))
	hit.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventScreenTouch and e.pressed:
			_poke_mascot())
	# Sol: ödüller, sağ: premium + Nook kısayolu
	_rewards_btn = Ui.icon_button("ic_gift", 150)
	put(_rewards_btn, Vector2(X0 + 40, y + 40), Vector2(150, 150))
	_rewards_btn.tapped.connect(_toggle_rewards)
	Ui.bob(_rewards_btn, 6.0, 2.0, 1.0)
	_anim.append(_rewards_btn)
	var rl := Ui.title(tr("rewards.fab"), 30)
	Ui.place(rl, Vector2(-30, 140), Vector2(210, 50))
	_rewards_btn.add_child(rl)
	if not Purchases.is_premium():
		var crown := Ui.icon_button("ic_crown", 150)
		put(crown, Vector2(X0 + W - 190, y + 40), Vector2(150, 150))
		crown.tapped.connect(func() -> void: Main.open("premium"))
		Ui.bob(crown, 6.0, 2.2, 2.0)
		_anim.append(crown)
		var cl := Ui.title(tr("menu.premium"), 30)
		Ui.place(cl, Vector2(-30, 140), Vector2(210, 50))
		crown.add_child(cl)

func _poke_mascot() -> void:
	var poses := ["cheer", "wave", "think"]
	_mascot.texture = UiArt.tex(poses[randi() % poses.size()], "mascot")
	Ui.punch(_mascot, 0.22)
	Sfx.note(randi() % 6 + 3, "place", -6.0)
	Juice.haptic("light")
	get_tree().create_timer(1.4).timeout.connect(func() -> void:
		if is_instance_valid(_mascot):
			_mascot.texture = UiArt.tex("idle", "mascot"))

func _play(y: float, target: String) -> void:
	var bw := minf(W - 200, 800.0)
	var b := Ui.button(tr("tab.play"), "terracotta", Vector2(bw, 190), "", 84)
	if target != "":
		var parts := Progress.split_id(target)
		b.sub = "%s · %s" % [tr(Progress.pack(parts[0]).title), tr("level.label") % int(parts[1])]
		if Progress.total_completed() > 0:
			b.text = tr("menu.continue")
	else:
		b.sub = tr("daily.allDone")
	put(b, Vector2(X0 + (W - bw) / 2.0, y), Vector2(bw, 190))
	b.tapped.connect(func() -> void:
		if target == "":
			Main.push("map")
		else:
			Main.play(target))
	_anim.append(b)
	if not Ui.reduce_motion():
		var tw := b.create_tween().set_loops()
		tw.tween_interval(2.4)
		tw.tween_property(b, "rotation", 0.025, 0.08)
		tw.tween_property(b, "rotation", -0.025, 0.1)
		tw.tween_property(b, "rotation", 0.0, 0.12).set_trans(Tween.TRANS_ELASTIC)
	# Harita kısayolu (paket listesi)
	var map := Ui.icon_button("ic_star", 120)
	put(map, Vector2(X0 + (W - bw) / 2.0 + bw + 10, y + 35), Vector2(120, 120))
	map.tapped.connect(func() -> void: Main.push("map"))
	_anim.append(map)
	if X0 + (W - bw) / 2.0 + bw + 130 > X0 + W:
		map.position.x = X0 + W - 125

func _daily(y: float) -> void:
	var done := Progress.daily_solved_count()
	var all := Progress.is_daily_all_complete()
	var card := QuiltCard.new()
	card.pressable = true
	card.fabric = 5
	card.inner = 14
	card.radius = 50
	card.glow = not all
	var cw := W - 80
	put(card, Vector2(X0 + 40, y), Vector2(cw, 200))
	_anim.append(card)
	var cal := Ui.icon("ic_calendar", Vector2(140, 140))
	Ui.place(cal, Vector2(28, 30), Vector2(140, 140))
	card.add_child(cal)
	var day := Ui.label(str(Progress.local_date(true).day), 50, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(day, Vector2(28, 66), Vector2(140, 90))
	card.add_child(day)
	var t := Ui.label(tr("menu.dailyPuzzle"), 50, Palette.INK)
	Ui.place(t, Vector2(190, 28), Vector2(cw - 420, 64))
	card.add_child(t)
	# 5 yama noktası
	for i in Progress.DAILY_LEVELS:
		var dot := PatchDot.new()
		dot.filled = i < done
		dot.idx = i
		Ui.place(dot, Vector2(192 + i * 66, 104), Vector2(54, 54))
		card.add_child(dot)
	_daily_timer = Ui.label("", 30, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	Ui.place(_daily_timer, Vector2(cw - 330, 26), Vector2(290, 50))
	card.add_child(_daily_timer)
	var go := Ui.button("%d/%d" % [done, Progress.DAILY_LEVELS] if not all else "✓", "sage" if all else "mustard", Vector2(180, 96), "", 44)
	Ui.place(go, Vector2(cw - 220, 82), Vector2(180, 96))
	card.add_child(go)
	var play := func() -> void:
		if all:
			Main.push("daily")
		else:
			Main.play("daily-%d" % Progress.daily_next_index())
	card.tapped.connect(play)
	go.tapped.connect(play)
	_tick_daily()

func _tick_daily() -> void:
	if _daily_timer:
		var s := Ui.seconds_to_utc_midnight()
		_daily_timer.text = (tr("menu.refresh") % Ui.fmt_time(s)) if not Progress.is_daily_all_complete() else tr("menu.dailyNext") + " " + Ui.fmt_time(s)

func _modes(y: float) -> void:
	var gap := 24.0
	var cw := (W - 80 - gap * 2) / 3.0
	var ch := 240.0
	# Zen anahtarı
	var zen := _mode_card(X0 + 40, y, cw, ch, 2, "ic_zen", tr("zen.mode.title"), tr("common.ok") if false else "")
	var tg := Widgets.Toggle.new()
	tg.on = Settings.zen_mode
	Ui.place(tg, Vector2((cw - 120) / 2.0, ch - 74), Vector2(120, 56))
	zen.add_child(tg)
	tg.toggled.connect(func(on: bool) -> void:
		Settings.zen_mode = on
		Main.toast(tr("zen.mode.subtitle") if on else tr("zen.mode.title") + " ✕", "ic_zen", Palette.SAGE)
		var tw := create_tween()
		tw.tween_property(_bg, "modulate", Color(0.86, 0.95, 0.86) if on else Color.WHITE, 0.6))
	zen.tapped.connect(func() -> void:
		tg.set_on(not tg.on)
		tg.toggled.emit(tg.on))
	# Endless
	var best := Progress.endless_best
	var en := _mode_card(X0 + 40 + cw + gap, y, cw, ch, 6, "ic_endless", tr("endless.title"), tr("endless.best") % best if best > 0 else tr("endless.subtitle"))
	en.tapped.connect(func() -> void: Main.play("endless-1"))
	# Kule
	var sub := tr("tower.resume") % Tower.current_floor if Tower.has_active_run() else (tr("tower.best") % Tower.best_floor if Tower.best_floor > 0 else tr("tower.subtitle"))
	var tw2 := _mode_card(X0 + 40 + (cw + gap) * 2, y, cw, ch, 4, "ic_tower", tr("tower.title"), sub)
	tw2.tapped.connect(func() -> void: Main.open("tower"))
	var tk := Ui.badge("%d" % Wallet.tickets, Palette.MUSTARD.darkened(0.15))
	tk.position = Vector2(cw - 56, -14)
	tw2.add_child(tk)

func _mode_card(x: float, y: float, w: float, h: float, fabric: int, icon: String, title: String, sub: String) -> QuiltCard:
	var c := QuiltCard.new()
	c.pressable = true
	c.fabric = fabric
	c.inner = 12
	c.radius = 44
	put(c, Vector2(x, y), Vector2(w, h))
	var ic := Ui.icon(icon, Vector2(104, 104))
	Ui.place(ic, Vector2((w - 104) / 2.0, 14), Vector2(104, 104))
	c.add_child(ic)
	var t := Ui.label(title, 34, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(t, Vector2(16, 116), Vector2(w - 32, 46))
	c.add_child(t)
	if sub != "":
		var s := Ui.label(sub, 25, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		Ui.place(s, Vector2(16, 160), Vector2(w - 32, 56))
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.max_lines_visible = 2
		c.add_child(s)
	_anim.append(c)
	return c

func _dock(y: float, h: float) -> void:
	var dock := QuiltCard.new()
	dock.fabric = 10
	dock.inner = 0
	dock.radius = 60
	put(dock, Vector2(X0 + 20, y), Vector2(W - 40, h + BOTTOM + 60))
	var items := [["ic_shop", "tab.shop", func() -> void: Main.open_shop()],
		["ic_home", "nook.title", func() -> void: Main.push("nook")],
		["ic_star", "levels.title", func() -> void: Main.push("map")],
		["ic_trophy", "achievements.title", func() -> void: Main.push("achievements")],
		["ic_stats", "tab.stats", func() -> void: Main.push("stats")]]
	var n := items.size()
	var step := (W - 80) / n
	for i in n:
		var it: Array = items[i]
		var b := Ui.icon_button(it[0], 128)
		put(b, Vector2(X0 + 40 + i * step + (step - 128) / 2.0, y + 16), Vector2(128, 128))
		b.tapped.connect(it[2])
		var lw := minf(step - 6.0, 190.0)
		var l := Ui.title(tr(it[1]), Ui.fit_font(tr(it[1]), 28, lw - 8.0, 18))
		Ui.place(l, Vector2((128 - lw) / 2.0, 118), Vector2(lw, 40))
		b.add_child(l)
		_anim.append(b)
		if i == 1:
			_nook_badge = Ui.badge("0", Palette.MUSTARD.darkened(0.1))
			_nook_badge.position = Vector2(84, -12)
			b.add_child(_nook_badge)

# ------------------------------------------------------------------ Ödül menüsü

func _reward_items() -> Array:
	return [
		{"icon": "ic_calendar", "key": "dailyReward.title", "ready": DailyReward.can_claim_week(), "go": func() -> void: Main.open("daily_login")},
		{"icon": "wheel", "key": "spin.title", "ready": Spin.can_spin(), "go": func() -> void: Main.open("spin")},
		{"icon": "chest_closed", "key": "chest.title", "ready": Chest.can_open(), "go": func() -> void: Main.open("chest"),
			"badge": "%d" % Chest.pending if Chest.pending > 0 else ""},
		{"icon": "ic_star", "key": "quest.header", "ready": Quests.has_claimable(), "go": func() -> void: Main.open("quests")},
		{"icon": "ic_gift", "key": "calendar.title", "ready": DailyReward.can_claim_calendar(), "go": func() -> void: Main.open("calendar")},
	]

func _toggle_rewards() -> void:
	if _dropdown:
		_close_dropdown()
		return
	var items := _reward_items()
	_dropdown = Control.new()
	_dropdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var catcher := Control.new()
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.size = size
	catcher.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventScreenTouch and not e.pressed:
			_close_dropdown())
	_dropdown.add_child(catcher)
	add_child(_dropdown)
	var bx := _rewards_btn.position.x
	var by := _rewards_btn.position.y + 200
	var panel := QuiltCard.new()
	panel.skin_name = "panel_sage"
	panel.fabric = 1
	panel.inner = 12
	panel.radius = 44
	var ih := 116.0
	panel.size = Vector2(470, items.size() * ih + 40)
	panel.position = Vector2(bx, by)
	_dropdown.add_child(panel)
	panel.pivot_offset = Vector2(60, 0)
	panel.scale = Vector2(0.6, 0.2)
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in items.size():
		var it: Dictionary = items[i]
		var row := QuiltCard.new()
		row.pressable = true
		row.fill = Palette.CARD
		row.radius = 34
		row.depth = 5
		row.stitch = false
		row.glow = bool(it.ready)
		Ui.place(row, Vector2(22, 20 + i * ih), Vector2(426, ih - 14))
		panel.add_child(row)
		var ic: Control
		if it.icon == "wheel" and UiArt.tex("wheel") == null:
			ic = Widgets.WheelIcon.new()
		else:
			ic = Ui.icon(String(it.icon), Vector2(84, 84))
		Ui.place(ic, Vector2(14, 9), Vector2(84, 84))
		row.add_child(ic)
		var l := Ui.label(tr(String(it.key)), 34, Palette.INK)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		Ui.place(l, Vector2(110, 0), Vector2(290, ih - 14))
		row.add_child(l)
		if bool(it.ready):
			var bd := Ui.badge("!")
			bd.position = Vector2(380, -8)
			row.add_child(bd)
		var go: Callable = it.go
		row.tapped.connect(func() -> void:
			_close_dropdown()
			go.call())
		Ui.pop_in(row, 0.05 + i * 0.04, 0.6)

func _close_dropdown() -> void:
	if _dropdown == null:
		return
	var d := _dropdown
	_dropdown = null
	var tw := d.create_tween()
	tw.tween_property(d, "modulate:a", 0.0, 0.12)
	tw.tween_callback(d.queue_free)

func _refresh_badges() -> void:
	var n := 0
	for it in _reward_items():
		if it.ready:
			n += 1
	if _rewards_badge and is_instance_valid(_rewards_badge):
		_rewards_badge.queue_free()
		_rewards_badge = null
	if n > 0:
		_rewards_badge = Ui.badge(str(n))
		_rewards_badge.position = Vector2(110, -6)
		_rewards_btn.add_child(_rewards_badge)
	var nk := Nook.total_available()
	if _nook_badge:
		_nook_badge.visible = nk > 0
		_nook_badge.text = str(nk)
		_nook_badge.queue_redraw()

func _process(dt: float) -> void:
	_acc += dt
	if _acc >= 1.0:
		_acc = 0.0
		_tick_daily()

# ------------------------------------------------------------------ Yaşam döngüsü

func on_enter() -> void:
	if args.get("dev_quiet", false):
		return
	_build_queue()
	_next_in_queue()

func on_resume() -> void:
	# Oyundan dönüş: ekranı tazele (bakiye/ilerleme), sonra kutlamalar.
	Main.replace("menu", {}, "none")

## Bekleyen kutlamalar (Swift öncelik sırası: paket > seviye > seri > günlük giriş).
func _build_queue() -> void:
	_queue.clear()
	if Progress.pending_pack_reward() != "":
		_queue.append(func() -> Sheet:
			var pid := Progress.pending_pack_reward()
			var r := Progress.collect_pack_reward()
			var sh := Main.reward(tr("pack.complete.title"), {"coin": r.coin, "gem": r.gem, "key": r.key},
				{"subtitle": tr(Progress.pack(pid).title), "pose": "cheer"})
			if sh:
				sh.closed.connect(func() -> void:
					if is_instance_valid(self):
						Share.maybe_request_review(self), CONNECT_ONE_SHOT)
			return sh)
	if not XP.pending_level_up().is_empty():
		_queue.append(func() -> Sheet:
			var lu := XP.pending_level_up()
			XP.consume_level_up()
			return Main.reward(tr("level.reached") % int(lu.level), {"coin": int(lu.coins)}, {"subtitle": tr("level.up"), "pose": "cheer"}))
	if Progress.pending_streak_milestone() > 0:
		_queue.append(func() -> Sheet:
			var r := Progress.collect_streak_milestone()
			return Main.reward(tr("streak.milestone") % int(r.days), {"coin": r.coin, "gem": r.gem}, {"subtitle": tr("streak.keepGoing"), "pose": "wave"}))
	if DailyReward.can_claim_week() and Progress.total_completed() > 0:
		_queue.append(func() -> Sheet: return Main.open("daily_login"))

func _next_in_queue() -> void:
	_refresh_badges()
	if _queue.is_empty() or not is_inside_tree():
		return
	var f: Callable = _queue.pop_front()
	var sh: Sheet = f.call()
	if sh:
		sh.closed.connect(func() -> void:
			if is_instance_valid(self):
				get_tree().create_timer(0.2).timeout.connect(_next_in_queue))
	else:
		_next_in_queue()

func on_cover(covered: bool) -> void:
	if not covered:
		_refresh_badges()

class Shadow extends Control:
	func _draw() -> void:
		var c := size / 2.0
		for i in 4:
			draw_set_transform(c, 0, Vector2(1.0, 0.28))
			draw_circle(Vector2.ZERO, size.x / 2.0 * (1.0 - i * 0.18), Color(Palette.INK, 0.06))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

## Günlük ilerleme yaması: dolu → kumaş kare + dikiş, boş → tebeşir izi.
class PatchDot extends Control:
	var filled := false
	var idx := 0
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if filled:
			var tex := Fabrics.get_tex(idx * 2 + 1)
			var poly := Ui.rrect(r, 12, 3)
			draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 4), size), 12, 3), Palette.SHADOW)
			if tex:
				var uv := PackedVector2Array()
				for p in poly:
					uv.append(p / (tex.get_size() * 0.75))
				draw_colored_polygon(poly, Color.WHITE, uv, tex)
			else:
				draw_colored_polygon(poly, Palette.piece(idx))
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-7), 8, 3), 6, 4), Color(Palette.STITCH, 0.8), 2.0)
		else:
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-3), 12, 3), 7, 5), Color(Palette.INK_SOFT, 0.55), 3.0)
