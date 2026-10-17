class_name JuicyButton
extends Control
## Kendi çizdiği "şeker" buton: alt kalınlık, basınca çöker, bırakınca yaylanır.

signal tapped
## disabled iken dokunulursa (hata sesi + sallanma zaten oynar).
signal denied

@export var text := "":
	set(v):
		text = v
		queue_redraw()
@export var color := Palette.piece(0)
@export var font_size := 44
## Kumaş buton dokusu (art/ui/btn_*.png). Uçlar sabit, orta şerit döşenir → esneme yok.
var skin: Texture2D
var icon: Texture2D
var icon_scale := 0.62
## false → zemin çizilmez (yalnız çocuklar + basma yayı; örn. XP halkası).
var draw_flat_bg := true
## İkinci satır (küçük, yarı saydam) — örn. "Bölüm 12 · 5 ⚡".
var sub := "":
	set(v):
		sub = v
		queue_redraw()
var disabled := false:
	set(v):
		disabled = v
		queue_redraw()
## Metin rengi (null → kumaşa göre otomatik).
var text_col: Variant = null
var radius := 36.0
var _press := 0.0
var _spring := 1.0
var _vs := 0.0
var _down := false
var _font: Font = preload("res://art/fonts/fredoka_bold.tres")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		if e.pressed:
			_down = true
			Juice.haptic("tick")
			Sfx.play("click", 1.25, -10.0)
		elif _down:
			_down = false
			_vs += 5.0
			if Rect2(Vector2.ZERO, size).has_point(e.position) and not DragScroll.recently_dragged():
				if disabled:
					Sfx.play("error", 1.0, -10.0)
					Juice.haptic("light")
					denied.emit()
				else:
					Sfx.play("click", 0.95, -4.0)
					tapped.emit()
		accept_event()

func _process(dt: float) -> void:
	if _down and DragScroll.recently_dragged():
		_down = false
	if not _down and _press == 0.0 and absf(_spring - 1.0) < 0.0005 and absf(_vs) < 0.001:
		if scale != Vector2.ONE:
			scale = Vector2.ONE
		return
	_press = move_toward(_press, 1.0 if _down else 0.0, dt * 14.0)
	var target := 0.94 if _down else 1.0
	_vs += (target - _spring) * 400.0 * dt - _vs * 18.0 * dt
	_spring += _vs * dt
	scale = Vector2(_spring, _spring)
	queue_redraw()

func _draw() -> void:
	if not draw_flat_bg and skin == null:
		return
	if skin:
		_draw_skin()
		return
	_draw_flat()

func _draw_skin() -> void:
	var dy := 8.0 * _press
	var r := Rect2(Vector2(0, dy), size)
	draw_set_transform(Vector2(0, 10), 0.0, Vector2.ONE)
	_pill(r, Color(0.3, 0.15, 0.05, 0.25 * (1.0 - _press)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_pill(r, (Color(0.7, 0.68, 0.66) if disabled else Color(1, 1, 1)).darkened(0.08 * _press))
	var c := r.get_center()
	if icon:
		var ih := r.size.y * icon_scale
		var isz := Vector2(icon.get_width() * ih / icon.get_height(), ih)
		var at := c - isz / 2.0 if text == "" else Vector2(r.position.x + r.size.y * 0.35, c.y - isz.y / 2.0)
		draw_texture_rect(icon, Rect2(at, isz), false)
	if text != "":
		var fs := font_size
		var avail := r.size.x - (r.size.y * 1.1 if icon else r.size.y * 0.5)
		var ts := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		while ts.x > avail and fs > 18:
			fs -= 2
			ts = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var x := c.x - ts.x / 2.0 + (r.size.y * 0.3 if icon else 0.0)
		var cy := c.y - (fs * 0.32 if sub != "" else 0.0)
		var p := Vector2(x, cy + fs * 0.34)
		var square := skin == UiArt.tex("btn_square")
		var col: Color = text_col if text_col != null else (Palette.INK if square else Palette.CREAM)
		if not square:
			draw_string_outline(_font, p + Vector2(0, 3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(0.25, 0.12, 0.05, 0.35))
			draw_string(_font, p + Vector2(0, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.25, 0.12, 0.05, 0.55))
		draw_string(_font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if sub != "":
			var sfs := int(fs * 0.5)
			var ss := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs)
			var sp := Vector2(c.x - ss.x / 2.0 + (r.size.y * 0.3 if icon else 0.0), cy + fs * 0.34 + sfs * 1.25)
			draw_string(_font, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, Color(col, 0.85))

## Uç kapakları en-boy oranı korunarak, orta şerit yatay döşenerek çizilir.
func _pill(r: Rect2, mod: Color) -> void:
	var tw := float(skin.get_width())
	var th := float(skin.get_height())
	var k := r.size.y / th
	var cap := minf(th * 0.5, tw * 0.5)
	var capw := cap * k
	if r.size.x <= capw * 2.0:
		draw_texture_rect(skin, r, false, mod)
		return
	draw_texture_rect_region(skin, Rect2(r.position, Vector2(capw, r.size.y)), Rect2(0, 0, cap, th), mod)
	draw_texture_rect_region(skin, Rect2(Vector2(r.end.x - capw, r.position.y), Vector2(capw, r.size.y)), Rect2(tw - cap, 0, cap, th), mod)
	var mid_src := Rect2(cap, 0, tw - cap * 2.0, th)
	var step := mid_src.size.x * k
	var x := r.position.x + capw
	var end := r.end.x - capw
	while x < end - 0.5:
		var w := minf(step, end - x)
		draw_texture_rect_region(skin, Rect2(Vector2(x, r.position.y), Vector2(w, r.size.y)), Rect2(mid_src.position, Vector2(w / k, th)), mod)
		x += w

func _draw_flat() -> void:
	var depth := 12.0
	var dy := depth * _press
	var r := Rect2(Vector2(0, dy), size - Vector2(0, depth))
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	sb.bg_color = Palette.SHADOW
	draw_style_box(sb, Rect2(Vector2(0, depth + 6), size - Vector2(0, depth)))
	sb.bg_color = color.darkened(0.3)
	draw_style_box(sb, Rect2(Vector2(0, depth), size - Vector2(0, depth)))
	sb.bg_color = color
	draw_style_box(sb, r)
	sb.bg_color = Color(1, 1, 1, 0.18)
	draw_style_box(sb, Rect2(r.position + Vector2(10, 6), Vector2(r.size.x - 20, r.size.y * 0.42)))
	var ts := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var p := r.get_center() + Vector2(-ts.x / 2.0, font_size * 0.36)
	draw_string(_font, p + Vector2(0, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color.darkened(0.45))
	draw_string(_font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.CREAM)
