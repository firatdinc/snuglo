class_name SceneBackdrop
extends Control
## Aplike yorgan manzarası arka plan: kapla-doldur, yavaş Ken Burns sürüklenmesi, alt/üst sıcak
## yıkama (okunurluk) ve önde süzülen pamuk tüyleri (paralaks: tüyler sahneden hızlı akar).
## parallax(v): kaydırma ofseti verilirse sahne 0.15×, tüyler 0.5× kayar.

var tex: Texture2D
var wash_top := 0.0      ## 0..1 üstte krem yıkama gücü
var wash_bottom := 0.55  ## 0..1 altta krem yıkama gücü
var darken := 0.0
var motes := 16
var zoom := 1.08
var _t := 0.0
var _scroll := 0.0
var _m: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Ui.vp()
	if size == Vector2.ZERO:
		size = v
	for i in motes:
		_m.append({"p": Vector2(randf() * size.x, randf() * size.y), "r": randf_range(4, 11), "s": randf_range(10, 34), "ph": randf() * TAU, "d": randf_range(0.3, 1.0)})

func parallax(v: float) -> void:
	_scroll = v
	queue_redraw()

func _process(dt: float) -> void:
	_t += dt * (0.0 if Ui.reduce_motion() else 1.0)
	for m in _m:
		m.p.y -= m.s * dt
		m.p.x += sin(_t * 0.6 + m.ph) * 8.0 * dt
		if m.p.y < -20:
			m.p = Vector2(randf() * size.x, size.y + 20)
	queue_redraw()

func _draw() -> void:
	if tex:
		var ts := tex.get_size()
		var k := maxf(size.x / ts.x, size.y / ts.y) * zoom
		var d := ts * k
		var drift := Vector2(sin(_t * 0.07) * 18.0, cos(_t * 0.05) * 12.0 - _scroll * 0.15)
		draw_texture_rect(tex, Rect2((size - d) / 2.0 + drift, d), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.BG_TOP)
	if darken > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.NIGHT, darken))
	if wash_top > 0.0:
		var h := size.y * 0.3
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, h), Vector2(0, h)]),
			PackedColorArray([Color(Palette.BG_TOP, wash_top), Color(Palette.BG_TOP, wash_top), Color(Palette.BG_TOP, 0), Color(Palette.BG_TOP, 0)]))
	if wash_bottom > 0.0:
		var y0 := size.y * 0.35
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(size.x, y0), Vector2(size.x, size.y), Vector2(0, size.y)]),
			PackedColorArray([Color(Palette.BG_BOTTOM, 0), Color(Palette.BG_BOTTOM, 0), Color(Palette.BG_BOTTOM, wash_bottom), Color(Palette.BG_BOTTOM, wash_bottom)]))
	for m in _m:
		var p: Vector2 = m.p - Vector2(0, _scroll * 0.5 * m.d)
		p.y = fposmod(p.y, size.y + 40) - 20
		draw_circle(p, m.r, Color(Palette.CREAM, 0.55 * m.d))
		draw_circle(p, m.r * 0.5, Color(1, 1, 1, 0.5 * m.d))
