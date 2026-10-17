class_name Badge
extends Control
## Küçük kumaş rozet (bildirim sayısı / "!" / "NEW"). Konum: sağ-üst köşeye yerleştirilir.

var text := "!"
var col := Palette.BAD
var fs := 30

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := maxf(48.0, Ui.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 28.0)
	size = Vector2(w, 48)
	pivot_offset = size / 2.0
	if not Ui.reduce_motion():
		var tw := create_tween().set_loops()
		tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var felt := UiArt.tex("badge")
	if felt and col == Palette.BAD and text.length() <= 2:
		draw_texture_rect(felt, Rect2(Vector2(size.x / 2.0 - size.y / 2.0, 0), Vector2(size.y, size.y)).grow(6), false)
		var t2 := Ui.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var p2 := Vector2((size.x - t2.x) / 2.0, size.y / 2.0 + fs * 0.36)
		draw_string_outline(Ui.FONT, p2, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Palette.INK)
		draw_string(Ui.FONT, p2, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)
		return
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(24)
	sb.anti_aliasing = true
	sb.bg_color = col.darkened(0.3)
	draw_style_box(sb, Rect2(Vector2(0, 4), size))
	sb.bg_color = col
	draw_style_box(sb, r)
	var q := r.grow(-6)
	draw_multiline(PieceShape.dashes(Ui.rrect(q, 18), 7, 5), Color(Palette.STITCH, 0.8), 2.0)
	var ts := Ui.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(Ui.FONT, Vector2((size.x - ts.x) / 2.0, size.y / 2.0 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)
