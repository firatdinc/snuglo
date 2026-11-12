class_name Tray
extends Node2D
## Tepsi zemini: tahtanın altında yumuşak kumaş sepet.

var rect := Rect2()

func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(48)
	sb.anti_aliasing = true
	sb.bg_color = Palette.SHADOW
	draw_style_box(sb, Rect2(rect.position + Vector2(0, 10), rect.size))
	sb.bg_color = Palette.TRAY
	draw_style_box(sb, rect)
	var d := PieceShape.dashes(_inset(rect, 16.0), 18.0, 12.0)
	draw_multiline(d, Color(Palette.BOARD_EDGE, 0.5), 3.0)

func _inset(r: Rect2, i: float) -> PackedVector2Array:
	var q := r.grow(-i)
	return PackedVector2Array([q.position, Vector2(q.end.x, q.position.y), q.end, Vector2(q.position.x, q.end.y)])
