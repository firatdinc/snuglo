class_name StarBadge
extends Control
## İşlemeli yıldız arması (art/ui/ic_star). filled=false → soluk, gri-kahve.

var filled := true:
	set(v):
		filled = v
		queue_redraw()

func _draw() -> void:
	var t := UiArt.tex("ic_star")
	if t == null:
		return
	var k := minf(size.x / t.get_width(), size.y / t.get_height())
	var d := t.get_size() * k
	var r := Rect2((size - d) / 2.0, d)
	draw_texture_rect(t, Rect2(r.position + Vector2(0, 8), r.size), false, Color(0.3, 0.15, 0.05, 0.25))
	draw_texture_rect(t, r, false, Color.WHITE if filled else Color(0.5, 0.45, 0.42, 0.5))
