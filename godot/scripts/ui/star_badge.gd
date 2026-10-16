class_name StarBadge
extends Control
## Yıldız rozeti (geçici vektör; ChatGPT işlemeli yıldız gelecek).

var filled := true

func _draw() -> void:
	var c := size / 2.0
	var pts := PackedVector2Array()
	for i in 10:
		var r := (size.x * 0.5) if i % 2 == 0 else (size.x * 0.22)
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var base := Palette.GOLD if filled else Palette.SLOT_SHADE
	var shadow := pts.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(0, 10)
	draw_colored_polygon(shadow, base.darkened(0.3))
	draw_colored_polygon(pts, base)
	var inner := Geometry2D.offset_polygon(pts, -size.x * 0.07, Geometry2D.JOIN_ROUND)
	if inner.size() > 0:
		draw_colored_polygon(inner[0], base.lightened(0.18))
