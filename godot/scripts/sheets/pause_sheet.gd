extends Sheet
## Duraklat (alt sheet): süre, hızlı anahtarlar (müzik/efekt/titreşim), Devam, İpucu, Yeniden
## başlat (enerji; zen/endless/kule ücretsiz), Ayarlar, Ana menü. args: level, screen (GameScreen).

func _init() -> void:
	style = "bottom"
	panel_size = Vector2(-1, 1180)

func build() -> void:
	var scr = args.get("screen")
	var id := String(args.get("level", ""))
	var w := pw()
	var y := banner_title(tr("pause.title")) + 30.0
	if scr and is_instance_valid(scr.game):
		var secs: float = scr.game.elapsed if scr.limit <= 0 else maxf(0.0, scr.limit - scr.game.elapsed)
		var t := Ui.label(Ui.fmt_time(secs), 44, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		add(t, Vector2(0, y - 10), Vector2(w, 50))
		y += 50
	y += 20
	# Hızlı anahtarlar
	var toggles := [["ic_sound", "pause.sound", "music_enabled"], ["ic_hint", "settings.sound.effects", "sfx_enabled"], ["ic_heart", "pause.haptics", "haptics"]]
	var cw := (w - 120 - 40) / 3.0
	for i in toggles.size():
		var tg: Array = toggles[i]
		var card := QuiltCard.new()
		card.fill = Palette.CREAM
		card.radius = 36
		card.depth = 6
		add(card, Vector2(60 + i * (cw + 20), y), Vector2(cw, 200))
		var ic := Ui.icon(tg[0], Vector2(72, 72))
		Ui.place(ic, Vector2((cw - 72) / 2.0, 12), Vector2(72, 72))
		card.add_child(ic)
		var l := Ui.label(tr(tg[1]), 28, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		Ui.place(l, Vector2(8, 84), Vector2(cw - 16, 40))
		card.add_child(l)
		var sw := Widgets.Toggle.new()
		sw.on = bool(Settings.get_value(tg[2]))
		Ui.place(sw, Vector2((cw - 110) / 2.0, 130), Vector2(110, 52))
		card.add_child(sw)
		var key: String = tg[2]
		sw.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
		Ui.pop_in(card, 0.1 + i * 0.05, 0.6)
	y += 240
	var resume := Ui.button(tr("pause.resume"), "sage", Vector2(w - 140, 150))
	add(resume, Vector2(70, y))
	resume.tapped.connect(close)
	y += 175
	var bw := (w - 160) / 2.0
	var can_hint: bool = scr != null and scr.mode != "endless" and Wallet.hints > 0 and scr.game.can_hint()
	var hint := Ui.button("%s ×%d" % [tr("pause.hint"), Wallet.hints], "mustard", Vector2(bw, 130), "ic_hint")
	hint.disabled = not can_hint
	add(hint, Vector2(70, y))
	hint.tapped.connect(func() -> void:
		close()
		var paid := Wallet.pay_powerup("hint")
		if not scr.game.hint():
			Wallet.refund_powerup("hint", paid))
	var free: bool = scr == null or scr.mode in ["endless", "tower"] or scr.relaxed or Energy.unlimited()
	var restart := Ui.button(tr("pause.restart"), "terracotta", Vector2(bw, 130), "ic_restart")
	if not free:
		var cost := Ui.badge("−%d" % Energy.COST, Palette.TEA)
		cost.position = Vector2(bw - 70, -22)
		restart.add_child(cost)
		var cup := Ui.icon("ic_energy", Vector2(56, 56))
		cup.position = Vector2(bw - 118, -26)
		restart.add_child(cup)
	add(restart, Vector2(90 + bw, y))
	restart.tapped.connect(func() -> void:
		close()
		if scr:
			scr.restart(not free))
	y += 155
	var settings := Ui.button(tr("pause.settings"), "mustard", Vector2(bw, 130), "ic_settings")
	add(settings, Vector2(70, y))
	settings.tapped.connect(func() -> void:
		close()
		Main.push("settings"))
	var home := Ui.button(tr("pause.home"), "terracotta", Vector2(bw, 130), "ic_home")
	add(home, Vector2(90 + bw, y))
	home.tapped.connect(func() -> void:
		close()
		if scr:
			scr.quit()
		else:
			Main.home())
	panel.size.y = y + 170
	_place_panel()
	if id == "":
		pass
