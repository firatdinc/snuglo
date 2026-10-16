class_name Backdrop
extends Node2D
## Geçici arka plan: dikey gradyan + yavaş süzülen yumuşak benekler.
## ChatGPT'den gelecek "battaniye/oda" arka planı bunun yerini alacak.

var _t := 0.0
var _dots: Array = []

func _ready() -> void:
	var vp := get_viewport_rect().size
	for i in 18:
		_dots.append({p = Vector2(randf() * vp.x, randf() * vp.y), r = randf_range(30, 110), s = randf_range(6, 18), ph = randf() * TAU})

func _process(dt: float) -> void:
	_t += dt
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	var ext := Rect2(-60, -60, vp.x + 120, vp.y + 120)
	draw_polygon(PackedVector2Array([ext.position, Vector2(ext.end.x, ext.position.y), ext.end, Vector2(ext.position.x, ext.end.y)]),
		PackedColorArray([Palette.BG_TOP, Palette.BG_TOP, Palette.BG_BOTTOM, Palette.BG_BOTTOM]))
	for d: Dictionary in _dots:
		var p: Vector2 = d.p + Vector2(sin(_t * 0.2 + d.ph), cos(_t * 0.17 + d.ph)) * d.s
		draw_circle(p, d.r, Color(Palette.CREAM, 0.18))
