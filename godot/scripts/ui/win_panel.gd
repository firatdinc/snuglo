class_name WinPanel
extends Control
## Kazanma kartı zemini (geçici; ChatGPT dikişli kumaş kart gelecek).

func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(64)
	sb.anti_aliasing = true
	sb.bg_color = Palette.SHADOW
	draw_style_box(sb, Rect2(Vector2(0, 16), size))
	sb.bg_color = Palette.CREAM
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var q := Rect2(Vector2.ZERO, size).grow(-22)
	var pts := PackedVector2Array([q.position, Vector2(q.end.x, q.position.y), q.end, Vector2(q.position.x, q.end.y)])
	draw_multiline(PieceShape.dashes(pts, 22.0, 14.0), Color(Palette.BOARD_EDGE, 0.6), 4.0)
