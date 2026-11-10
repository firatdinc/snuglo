extends XmasGame
## Yeni Yıl Dileği: krem kâğıda el yazısıyla dilek yaz (HandFont), "Dileğimi as" ile kâğıt sarılır,
## kurdele + balmumu mührü vurulur. 31 Aralık'a kadar tomara dokunup okunur/düzenlenir; Ocak'ta
## "Mutlu yıllar" başlığıyla açık kalır (salt okunur). Kayıt: Xmas.wish() = {text, date, sealed, draft}.
## Dev: SNUG_WISH="metin" (kayıtlı/mühürlü dilek), SNUG_WISH_MODE=type (yazma kipi, metin hazır) |
## open (tomar kendiliğinden açılır), SNUG_NEWYEAR=1 (Ocak kipi), SNUG_LANG=<dil>.

const PAD := 64.0
const HEAD_H := 132.0

var paper: _Paper
var body: Control            ## klavye açılınca yukarı kayar
var edit: TextEdit
var read: Label
var pencil: _Pencil
var seal_btn: JuicyButton
var edit_btn: JuicyButton
var hint: Label
var mode := ""               ## type | writing | sealing | rolled | read
var fs := 66
var step := 84.0
var max_len := 120
var rows := 8
var _rev := 0.0
var _rev_n := -1
var _after_reveal := Callable()
var _kb := 0.0
var _btn_bottom := 0.0

func _init() -> void:
	GAME = "wish"
	TITLE_KEY = "wish.title"
	BG_SCENE = "christmas"

func setup_game(r: Rect2) -> void:
	var lang := TranslationServer.get_locale().substr(0, 2)
	max_len = Xmas.WISH_MAX if lang not in ["ja", "ko"] else 70
	body = Control.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size = size
	add_child(body)
	# Kâğıt görseli (ChatGPT) oranı 467x666; satır çizgileri görselin içinde: ilk çizgi %23.9, aralık %8.36.
	var pw := minf(W - 80.0, (r.size.y - 14.0 - 330.0) / 1.426)
	var ph := pw * 1.426
	rows = 7
	step = ph * 0.0836
	fs = int(step * 0.8 * HandFont.scale_for_lang())
	var rule0 := ph * 0.239
	var head_h := rule0 + step * 0.2
	var pad := pw * 0.15
	paper = _Paper.new()
	paper.step = step
	paper.rows = rows
	paper.max_len = max_len
	paper.pad = pad
	paper.head_h = head_h
	paper.rule0 = rule0
	paper.setup_font(fs)
	paper.position = Vector2(X0 + (W - pw) / 2.0, r.position.y + 14.0)
	paper.size = Vector2(pw, ph)
	body.add_child(paper)
	var font := HandFont.get_font()
	var lsp := int(step - font.get_height(fs))
	var tw := pw - pad * 2.0
	var th := step * rows
	edit = TextEdit.new()
	edit.position = Vector2(pad, head_h)
	edit.size = Vector2(tw, th)
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.context_menu_enabled = false
	edit.caret_blink = true
	edit.placeholder_text = tr("wish.ph%d" % (1 + randi() % 3))
	for sb in ["normal", "focus", "read_only"]:
		edit.add_theme_stylebox_override(sb, StyleBoxEmpty.new())
	edit.add_theme_font_override("font", font)
	edit.add_theme_font_size_override("font_size", fs)
	edit.add_theme_constant_override("line_spacing", lsp)
	edit.add_theme_color_override("font_color", Color("3d3a5c"))
	edit.add_theme_color_override("font_placeholder_color", Color("3d3a5c", 0.35))
	edit.add_theme_color_override("caret_color", Palette.TERRACOTTA)
	edit.add_theme_color_override("selection_color", Color(Palette.GOLD, 0.45))
	edit.text_changed.connect(_on_text_changed)
	paper.add_child(edit)
	read = Label.new()
	read.position = edit.position
	read.size = edit.size
	read.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	read.add_theme_font_override("font", font)
	read.add_theme_font_size_override("font_size", fs)
	read.add_theme_constant_override("line_spacing", lsp)
	read.add_theme_color_override("font_color", Color("3d3a5c"))
	read.mouse_filter = Control.MOUSE_FILTER_IGNORE
	read.visible = false
	paper.add_child(read)
	pencil = _Pencil.new()
	pencil.visible = false
	pencil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(pencil)
	paper.tapped.connect(_on_paper_tapped)
	# Düğmeler + ipucu (kâğıdın altı)
	var by := paper.position.y + ph + 36.0
	hint = Ui.title("", 38, Palette.CREAM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	put(hint, Vector2(X0 + 60.0, by), Vector2(W - 120.0, 90.0), body)
	seal_btn = Ui.button(tr("wish.seal"), "terracotta", Vector2(640, 130), "", 44)
	put(seal_btn, Vector2(X0 + (W - 640.0) / 2.0, by + 100.0), seal_btn.size, body)
	seal_btn.tapped.connect(_do_seal)
	edit_btn = Ui.button(tr("wish.edit"), "mustard", Vector2(560, 120), "", 40)
	put(edit_btn, Vector2(X0 + (W - 560.0) / 2.0, by + 100.0), edit_btn.size, body)
	edit_btn.tapped.connect(_do_edit)
	_btn_bottom = by + 100.0 + 140.0
	Ui.pop_in(paper, 0.05, 0.9)
	_enter_state()

func _enter_state() -> void:
	var w := Xmas.wish()
	var ny := Xmas.wish_new_year()
	var dev := Dev.env("SNUG_WISH")
	if dev != "":
		if Dev.env("SNUG_WISH_MODE") == "type":
			edit.text = dev
			_to_type()
			return
		w.text = dev.substr(0, max_len)
		w.sealed = true
	paper.head = tr("wish.hny" if ny and Xmas.wish_sealed() else "wish.head") % Xmas.wish_year()
	if Xmas.wish_sealed():
		read.text = String(w.text)
		if ny or Dev.env("SNUG_WISH_MODE") == "open":
			paper.roll = 0.0
			_start_reveal(Callable(self, "_to_read"), ny)
		else:
			paper.roll = 1.0
			_to_rolled()
	else:
		edit.text = String(w.get("draft", ""))
		_to_type()

# ---------------------------------------------------------------- kipler
func _to_type() -> void:
	mode = "type"
	paper.roll = 0.0
	paper.show_rules = true
	paper.count = edit.text.length()
	edit.visible = true
	edit.editable = true
	edit.modulate.a = 1.0
	read.visible = false
	pencil.visible = false
	edit_btn.visible = false
	seal_btn.visible = true
	seal_btn.disabled = edit.text.strip_edges() == ""
	hint.text = tr("wish.tapWrite")
	paper.queue_redraw()

func _to_rolled() -> void:
	mode = "rolled"
	edit.visible = false
	read.visible = false
	pencil.visible = false
	seal_btn.visible = false
	edit_btn.visible = false
	hint.text = tr("wish.tapRead")
	paper.roll = 1.0
	paper.queue_redraw()

func _to_read() -> void:
	mode = "read"
	read.visible_characters = -1
	pencil.visible = false
	seal_btn.visible = false
	edit_btn.visible = Xmas.wish_editable()
	hint.text = tr("wish.lockedNote") if not Xmas.wish_editable() else ""
	paper.count = -1
	paper.queue_redraw()

# ---------------------------------------------------------------- yazma
func _on_text_changed() -> void:
	var t := edit.text
	if t.length() > max_len:
		edit.text = t.substr(0, max_len)
		var ln := edit.get_line_count() - 1
		edit.set_caret_line(ln)
		edit.set_caret_column(edit.get_line(ln).length())
		Juice.haptic("error")
	var n := edit.text.length()
	if n > paper.count:
		Asmr.stroke(self, "type", 30.0, 28.0, "rustle", "tick", 1.1)
	paper.count = n
	paper.queue_redraw()
	seal_btn.disabled = edit.text.strip_edges() == ""
	Xmas.wish()["draft"] = edit.text
	Save.mark_dirty()

func _on_paper_tapped() -> void:
	if mode == "type":
		edit.grab_focus()
	elif mode == "rolled":
		_unroll()
	elif mode == "writing":
		_rev = float(read.get_total_character_count())   # dokununca hemen bitir

func _input(e: InputEvent) -> void:
	if mode != "type" or not edit.has_focus():
		return
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		var p: Vector2 = e.position
		if not edit.get_global_rect().has_point(p) and not seal_btn.get_global_rect().has_point(p):
			edit.release_focus()

## Yazma animasyonu: harfler tek tek belirir, kalem ucu izler, çıtırtı + hafif titreşim.
func _start_reveal(done: Callable, celebrate_ny := false) -> void:
	mode = "writing"
	paper.show_rules = true
	paper.count = -1
	edit.visible = false
	read.visible = true
	read.visible_characters = 0
	pencil.visible = true
	seal_btn.visible = false
	edit_btn.visible = false
	hint.text = ""
	_rev = 0.0
	_rev_n = -1
	_after_reveal = done
	if celebrate_ny:
		XmasKit.celebrate(self, Vector2(size.x / 2.0, paper.position.y + 120.0))

func _process(dt: float) -> void:
	if mode == "writing":
		var total := read.get_total_character_count()
		_rev += dt * (13.0 if total < 90 else 20.0)
		var n := mini(int(_rev), total)
		if n != _rev_n:
			_rev_n = n
			read.visible_characters = n
			Asmr.stroke(self, "write", 30.0, 28.0, "rustle", "tick", 1.0 + 0.1 * sin(n * 0.7))
		if n > 0 and n <= total:
			var b := read.get_character_bounds(clampi(n - 1, 0, total - 1))
			pencil.position = read.position + b.end - Vector2(6, 6)
			if (_rev - floorf(_rev)) > 0.0:
				pencil.rotation = -0.2 + 0.08 * sin(_rev * 3.0)
		if n >= total:
			pencil.visible = false
			var cb := _after_reveal
			_after_reveal = Callable()
			mode = "read"
			if cb.is_valid():
				cb.call()
	# Klavye açıkken gövdeyi yukarı kaydır: "Dileğimi as" düğmesi görünür kalsın.
	var kb_px := float(DisplayServer.virtual_keyboard_get_height()) if OS.get_name() in ["iOS", "Android"] else 0.0
	var win_h := float(maxi(1, DisplayServer.window_get_size().y))
	var target := 0.0
	if kb_px > 0.0 and edit.has_focus():
		var kb_design := kb_px / win_h * size.y
		target = clampf(_btn_bottom + 20.0 - (size.y - kb_design), 0.0, 520.0)
	_kb = lerpf(_kb, target, clampf(dt * 10.0, 0.0, 1.0))
	body.position.y = -_kb

# ---------------------------------------------------------------- mühürle / aç / düzenle
func _do_seal() -> void:
	var t := edit.text.strip_edges()
	if t == "" or mode != "type":
		Ui.shake(seal_btn)
		Juice.haptic("error")
		return
	edit.release_focus()
	Xmas.seal_wish(t)
	mode = "sealing"
	read.text = t
	read.visible_characters = -1
	read.visible = true
	edit.visible = false
	seal_btn.visible = false
	hint.text = ""
	paper.show_rules = true
	Asmr.hit("rustle", "light")
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(paper, "roll", 0.85, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(read, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tw.tween_callback(func() -> void:
		read.visible = false
		read.modulate.a = 1.0
		Asmr.hit("stitch", "light"))
	tw.tween_property(paper, "roll", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		Asmr.hit("felt_pop", "success", "reward")
		Asmr.play("chime", "", 1.1, -4.0)
		XmasKit.celebrate(self, paper.global_position - global_position + paper.size / 2.0)
		Main.toast(tr("wish.sealedToast"), "ic_gift", Palette.SAGE)
		_to_rolled()
		Ui.punch(paper, 0.06))

func _unroll() -> void:
	mode = "sealing"
	hint.text = ""
	Asmr.hit("rustle", "light", "", 0.9)
	read.text = String(Xmas.wish().get("text", ""))
	paper.show_rules = true
	var tw := create_tween()
	tw.tween_property(paper, "roll", 0.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_start_reveal(Callable(self, "_to_read")))

func _do_edit() -> void:
	if not Xmas.wish_editable():
		return
	Xmas.unseal_wish()
	edit.text = String(Xmas.wish().get("draft", ""))
	paper.head = tr("wish.head") % Xmas.wish_year()
	Asmr.hit("rustle", "light")
	_to_type()
	edit.grab_focus()
	edit.set_caret_line(edit.get_line_count() - 1)
	edit.set_caret_column(edit.get_line(edit.get_line_count() - 1).length())

func on_back() -> bool:
	if mode == "type" and edit.has_focus():
		edit.release_focus()
		return true
	return false

# ---------------------------------------------------------------- görünüm
class _Paper extends Control:
	signal tapped
	var roll := 0.0:
		set(v):
			roll = v
			queue_redraw()
	var head := ""
	var step := 84.0
	var rows := 8
	var pad := 64.0
	var head_h := 132.0
	var rule0 := 200.0
	var max_len := 120
	var count := 0
	var show_rules := true
	var _fs := 66
	var _t := 0.0
	var _font: Font
	var _tex_paper: Texture2D = load("res://art/xmas/wish/wish_paper.png") if ResourceLoader.exists("res://art/xmas/wish/wish_paper.png") else null
	var _tex_scroll: Texture2D = load("res://art/xmas/wish/wish_scroll.png") if ResourceLoader.exists("res://art/xmas/wish/wish_scroll.png") else null

	func setup_font(fs: int) -> void:
		_fs = fs
		_font = HandFont.get_font()
		pivot_offset = size / 2.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		pivot_offset = size / 2.0

	func _gui_input(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
			tapped.emit()

	func _process(dt: float) -> void:
		if roll > 0.99:
			_t += dt
			queue_redraw()

	func _draw() -> void:
		var f := _font if _font else HandFont.get_font()
		if roll >= 0.85 and _tex_scroll:
			var kk := clampf((roll - 0.85) / 0.15, 0.0, 1.0)
			var sw := size.x * 0.96
			var sh2 := sw * float(_tex_scroll.get_height()) / _tex_scroll.get_width()
			var cy := size.y / 2.0 + sin(_t * 1.8) * 4.0
			draw_set_transform(Vector2(size.x / 2.0, cy), 0.0, Vector2.ONE * (0.8 + 0.2 * kk))
			draw_texture_rect(_tex_scroll, Rect2(-sw / 2.0, -sh2 / 2.0, sw, sh2), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		if roll >= 0.85:
			var k := clampf((roll - 0.85) / 0.15, 0.0, 1.0)
			var sh := 230.0
			var r := Rect2(Vector2(size.x * 0.04, (size.y - sh) / 2.0 + 40.0 + sin(_t * 1.8) * 4.0 * k), Vector2(size.x * 0.92, sh))
			WishArt.draw_scroll(self, r, k)
			return
		var rr := roll / 0.85
		var cur_h := lerpf(size.y, 230.0, rr * rr * (3.0 - 2.0 * rr))
		var y0 := (size.y - cur_h) / 2.0 + 40.0 * rr
		var r := Rect2(0, y0, size.x, cur_h)
		if _tex_paper:
			draw_texture_rect(_tex_paper, Rect2(r.position + Vector2(5, 14), r.size - Vector2(10, 10)), false, Color(0.2, 0.1, 0.05, 0.28))
			draw_texture_rect(_tex_paper, r, false)
			if rr < 0.2:
				var a2 := 1.0 - rr / 0.2
				var hfs := int(_fs * 0.9)
				while hfs > 20 and f.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs).x > size.x - pad * 1.6:
					hfs -= 2
				draw_string(f, Vector2(0, rule0 - step * 0.12), head, HORIZONTAL_ALIGNMENT_CENTER, size.x, hfs, Color(Palette.TERRACOTTA, a2))
				if count >= 0:
					draw_string(f, Vector2(0, size.y * 0.905), "%d/%d" % [count, max_len], HORIZONTAL_ALIGNMENT_RIGHT, size.x - pad, int(_fs * 0.5), Color(Palette.INK_SOFT, 0.75 * a2))
			return
		draw_colored_polygon(Ui.rrect(Rect2(r.position + Vector2(0, 9), r.size), 30.0), Color(Palette.SHADOW, 0.34))
		draw_colored_polygon(Ui.rrect(r, 30.0), WishArt.PAPER_SHADE)
		draw_colored_polygon(Ui.rrect(Rect2(r.position, r.size - Vector2(0, 6)), 30.0), WishArt.PAPER)
		draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-16), 20.0), 16.0, 10.0), Color(Palette.STITCH_DARK, 0.5), 3.5)
		if rr < 0.2:
			var a := 1.0 - rr / 0.2
			# kenar çizgisi (defter) + satır çizgileri
			draw_line(Vector2(pad - 26, y0 + 40), Vector2(pad - 26, r.end.y - 40), Color(Palette.TERRACOTTA, 0.28 * a), 3.0)
			if show_rules:
				for i in rows:
					var ly := head_h + step * (i + 1) - step * 0.2
					draw_line(Vector2(pad - 8, ly), Vector2(size.x - pad + 8, ly), Color("9db5c9", 0.55 * a), 2.5)
			draw_string(f, Vector2(0, 92), head, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(_fs * 0.92), Color(Palette.TERRACOTTA, a))
			if count >= 0:
				draw_string(f, Vector2(0, size.y - 28), "%d/%d" % [count, max_len], HORIZONTAL_ALIGNMENT_RIGHT, size.x - pad, int(_fs * 0.5), Color(Palette.INK_SOFT, 0.7 * a))
			# keçe bant (üstte)
			var tp := Vector2(size.x / 2.0, y0 + 2.0)
			draw_set_transform(tp, -0.05, Vector2.ONE)
			draw_rect(Rect2(-90, -22, 180, 44), Color(Palette.MUSTARD, 0.9 * a))
			draw_multiline(PackedVector2Array([Vector2(-86, -12), Vector2(86, -12), Vector2(-86, 12), Vector2(86, 12)]), Color(Palette.CREAM, 0.7 * a), 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# yüzdeki balmumu mührü: yazılı kâğıdın sağ altında küçük
		if rr > 0.0 and rr < 0.2:
			pass

## Kalem: ucu (0,0), gövde yukarı-sağa.
class _Pencil extends Control:
	func _draw() -> void:
		var tip := Vector2.ZERO
		draw_colored_polygon(PackedVector2Array([tip, Vector2(10, -28), Vector2(24, -18)]), Color("e8c79a"))
		draw_colored_polygon(PackedVector2Array([tip, Vector2(3, -8), Vector2(7, -5)]), Color("3d3a5c"))
		draw_colored_polygon(PackedVector2Array([Vector2(10, -28), Vector2(24, -18), Vector2(78, -76), Vector2(62, -88)]), Palette.TERRACOTTA)
		draw_colored_polygon(PackedVector2Array([Vector2(62, -88), Vector2(78, -76), Vector2(90, -90), Vector2(74, -102)]), Color("f3a6a0"))
		draw_line(Vector2(17, -23), Vector2(70, -82), Color(1, 1, 1, 0.35), 3.0)
