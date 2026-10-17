class_name Widgets
extends RefCounted
## Küçük çizimli bileşenler (sanat gelene kadar kumaş dilinde vektör): XP halkası, alev, çark ikonu,
## dikişli ilerleme çubuğu, açma/kapama anahtarı.

## XP seviye halkası: kumaş disk + dikişli ilerleme yayı + seviye numarası.
class XpRing extends Control:
	var level := 1
	var frac := 0.0
	var _shown := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		create_tween().tween_property(self, "_shown", frac, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.3)
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		draw_circle(c + Vector2(0, 6), r, Palette.SHADOW)
		draw_circle(c, r, Palette.SAGE.darkened(0.25))
		draw_circle(c, r - 14, Palette.CARD)
		draw_arc(c, r - 7, -PI / 2, -PI / 2 + TAU * _shown, 48, Palette.MUSTARD, 12.0, true)
		draw_arc(c, r - 22, 0, TAU, 40, Color(Palette.STITCH_DARK, 0.4), 2.0, true)
		var t := str(level)
		var fs := int(r * (0.9 if t.length() < 3 else 0.7))
		var ts := Ui.FONT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(Ui.FONT, c + Vector2(-ts.x / 2.0, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.INK)

## Keçe alev (seri). lit=false → soluk.
class Flame extends Control:
	var lit := true
	var _t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var sway := sin(_t * 5.0) * w * 0.04 if lit and not Ui.reduce_motion() else 0.0
		var outer := _shape(w, h, sway, 1.0)
		var col := Palette.FLAME if lit else Palette.LOCKED
		draw_colored_polygon(_shift(outer, Vector2(0, 4)), col.darkened(0.35))
		draw_colored_polygon(outer, col)
		var inner := _shape(w, h, sway * 1.4, 0.55)
		draw_colored_polygon(inner, Palette.MUSTARD if lit else Palette.CARD)
		draw_multiline(PieceShape.dashes(_shape(w, h, sway, 0.82), 6, 5), Color(Palette.STITCH, 0.7), 2.0)
	func _shape(w: float, h: float, sway: float, k: float) -> PackedVector2Array:
		var c := Vector2(w / 2.0, h * 0.68)
		var r := w * 0.42 * k
		var tip := Vector2(w / 2.0 + sway, h * 0.68 - h * 0.66 * k)
		var pts := PackedVector2Array()
		for i in 13:
			pts.append(c + Vector2.from_angle(float(i) / 12.0 * PI) * r)
		var l := c + Vector2(-r, 0)
		var cl := c + Vector2(-r * 1.05, -r * 1.3)
		for i in range(1, 11):
			var t := i / 10.0
			pts.append(l.lerp(cl, t).lerp(cl.lerp(tip, t), t))
		var rp := c + Vector2(r, 0)
		var cr := c + Vector2(r * 0.55, -r * 0.9)
		for i in range(1, 10):
			var t := i / 10.0
			pts.append(tip.lerp(cr, t).lerp(cr.lerp(rp, t), t))
		return pts
	func _shift(p: PackedVector2Array, d: Vector2) -> PackedVector2Array:
		var o := PackedVector2Array()
		for q in p:
			o.append(q + d)
		return o

## Ahşap çark ikonu (dilimli disk + dikiş).
class WheelIcon extends Control:
	var spin := true
	var _a := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(dt: float) -> void:
		if spin and not Ui.reduce_motion():
			_a += dt * 0.8
			queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		var r := size.x * 0.44
		draw_circle(c + Vector2(0, 5), r + 6, Palette.SHADOW)
		draw_circle(c, r + 6, Palette.BOARD_EDGE.darkened(0.2))
		for i in 8:
			var a0 := _a + i * TAU / 8.0
			var pts := PackedVector2Array([c])
			for k in 7:
				pts.append(c + Vector2.from_angle(a0 + k * TAU / 8.0 / 6.0) * r)
			draw_colored_polygon(pts, Palette.piece(i * 3))
		draw_arc(c, r - 6, 0, TAU, 40, Color(Palette.STITCH, 0.7), 2.0, true)
		draw_circle(c, r * 0.18, Palette.MUSTARD)
		draw_circle(c, r * 0.08, Palette.INK)

## Dikişli ilerleme çubuğu (yuva + kumaş dolgu, yumuşak dolum animasyonu).
class StitchBar extends Control:
	var value := 0.0:
		set(v):
			value = clampf(v, 0.0, 1.0)
			if is_inside_tree():
				create_tween().tween_property(self, "_shown", value, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			else:
				_shown = value
	var col := Palette.SAGE
	var track := Color(Palette.INK, 0.12)
	var _shown := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := _shown
		_shown = 0.0
		create_tween().tween_property(self, "_shown", v, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.2)
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var h := size.y
		draw_colored_polygon(Ui.rrect(Rect2(Vector2.ZERO, size), h / 2.0), track)
		if _shown > 0.001:
			var w := maxf(h, size.x * _shown)
			var r := Rect2(Vector2.ZERO, Vector2(w, h))
			draw_colored_polygon(Ui.rrect(r, h / 2.0), col)
			if w - h * 0.6 > h * 0.35:
				draw_colored_polygon(Ui.rrect(Rect2(Vector2(h * 0.3, h * 0.15), Vector2(w - h * 0.6, h * 0.3)), h * 0.15), Color(1, 1, 1, 0.22))
			if h >= 18:
				draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-h * 0.22), h * 0.28), 8, 6), Color(Palette.STITCH, 0.6), 2.0)

## Kumaş açma/kapama anahtarı.
class Toggle extends Control:
	signal toggled(on: bool)
	var on := false
	var _k := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		_k = 1.0 if on else 0.0
	func set_on(v: bool, animate := true) -> void:
		on = v
		if animate:
			create_tween().tween_property(self, "_k", 1.0 if on else 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			_k = 1.0 if on else 0.0
	func _gui_input(e: InputEvent) -> void:
		if (e is InputEventScreenTouch and not e.pressed) or (e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
			if DragScroll.recently_dragged():
				return
			set_on(not on)
			Sfx.play("click", 1.4 if on else 1.0, -6.0)
			Juice.haptic("light")
			toggled.emit(on)
			accept_event()
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var h := size.y
		var col := Palette.LOCKED.lerp(Palette.SAGE, _k)
		draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 4), size), h / 2.0), col.darkened(0.3))
		draw_colored_polygon(Ui.rrect(Rect2(Vector2.ZERO, size), h / 2.0), col)
		draw_multiline(PieceShape.dashes(Ui.rrect(Rect2(Vector2.ZERO, size).grow(-7), h / 2.0 - 7), 8, 6), Color(Palette.STITCH, 0.6), 2.0)
		var x := lerpf(h / 2.0, size.x - h / 2.0, _k)
		draw_circle(Vector2(x, h / 2.0 + 4), h / 2.0 - 6, Color(Palette.INK, 0.2))
		draw_circle(Vector2(x, h / 2.0), h / 2.0 - 6, Palette.CREAM)
		draw_circle(Vector2(x, h / 2.0), h / 2.0 - 16, Palette.CARD_EDGE)
