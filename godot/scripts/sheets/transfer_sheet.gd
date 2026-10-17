extends Sheet
## Yedekle & taşı (Swift SaveTransferSheet): kopyalanabilir yedek kodu + yapıştırıp geri yükle.

var _input: LineEdit

func _init() -> void:
	panel_size = Vector2(-1, 1200)

func build() -> void:
	var w := pw()
	close_x()
	var y := heading(tr("transfer.title"), 60, 60)
	# Yedek kodu
	var code := Save.export_code()
	var t1 := Ui.label(tr("transfer.backup.title"), 42, Palette.INK)
	add(t1, Vector2(70, y + 10), Vector2(w - 140, 56))
	y += 70
	y = body(tr("transfer.backup.desc"), y, 30)
	var box := QuiltCard.new()
	box.fill = Palette.CREAM
	box.radius = 30
	box.depth = 4
	add(box, Vector2(60, y + 10), Vector2(w - 120, 130))
	var cl := Ui.label(code.left(60) + "…", 26, Palette.INK_SOFT)
	cl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(cl, Vector2(30, 0), Vector2(w - 180, 130))
	box.add_child(cl)
	y += 160
	var copy := Ui.button(tr("transfer.copy"), "mustard", Vector2(w - 160, 120), "", 40)
	add(copy, Vector2(80, y))
	copy.tapped.connect(func() -> void:
		DisplayServer.clipboard_set(Save.export_code())
		Ui.punch(copy, 0.12)
		Main.toast(tr("transfer.copy") + " ✓", "ic_hint", Palette.SAGE))
	y += 150
	# Geri yükle
	var t2 := Ui.label(tr("transfer.restore.title"), 42, Palette.INK)
	add(t2, Vector2(70, y), Vector2(w - 140, 56))
	y += 60
	y = body(tr("transfer.restore.desc"), y, 30)
	_input = LineEdit.new()
	_input.placeholder_text = "SNUG2:…"
	_input.add_theme_font_override("font", Ui.FONT)
	_input.add_theme_font_size_override("font_size", 32)
	_input.add_theme_color_override("font_color", Palette.INK)
	_input.add_theme_color_override("font_placeholder_color", Color(Palette.INK_SOFT, 0.6))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.CREAM
	sb.set_corner_radius_all(28)
	sb.border_color = Palette.CARD_EDGE
	sb.set_border_width_all(4)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	_input.add_theme_stylebox_override("normal", sb)
	_input.add_theme_stylebox_override("focus", sb)
	add(_input, Vector2(60, y + 10), Vector2(w - 120, 110))
	y += 140
	var bw := (w - 180) / 2.0
	var paste := Ui.button(tr("transfer.paste"), "sage", Vector2(bw, 120), "", 40)
	add(paste, Vector2(70, y))
	paste.tapped.connect(func() -> void: _input.text = DisplayServer.clipboard_get().strip_edges())
	var rest := Ui.button(tr("transfer.restore.action"), "terracotta", Vector2(bw, 120), "", 40)
	add(rest, Vector2(110 + bw, y))
	rest.tapped.connect(_restore)
	y += 150
	var note := Ui.wrap(Ui.label(tr("transfer.note"), 26, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER), w - 140)
	add(note, Vector2(70, y))
	y += 90
	panel.size.y = y + 20
	_place_panel()

func _restore() -> void:
	var c := _input.text.strip_edges()
	Main.confirm(tr("transfer.restore.title"), tr("transfer.note"), tr("transfer.restore.action"), func() -> void:
		if Save.import_code(c):
			Main.toast(tr("transfer.restored.title"), "ic_heart", Palette.SAGE)
			close()
			Main.goto("menu")
		else:
			Main.toast(tr("transfer.invalid.title"), "ic_lock", Palette.TERRACOTTA)
			Ui.shake(_input), true)
