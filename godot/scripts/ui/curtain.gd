class_name Curtain
extends Control
## Ekran geçişi: "yorgan perdesi" — kumaş yamalar köşeden çapraz dalgayla dikilir (kapanır),
## ekran değişir, yamalar ters yönde söküler (açılır). Hareketi azalt → krem soluklaşma.

const COLS := 5
const DUR := 0.38

var _p := 0.0          # 0 açık, 1 tam kapalı
var _closing := true
var _rows := 0
var _side := 0.0

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _size() -> void:
	pass
	_side = size.x / COLS
	_rows = int(ceil(size.y / _side)) + 1

## Kapat (await edilebilir).
func cover() -> void:
	_size()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_closing = true
	Sfx.play("snap", 0.6, -12.0)
	var tw := create_tween()
	tw.tween_method(_set_p, 0.0, 1.0, DUR * (0.5 if Ui.reduce_motion() else 1.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

## Aç.
func uncover() -> void:
	_closing = false
	var tw := create_tween()
	tw.tween_method(_set_p, 1.0, 0.0, DUR * (0.5 if Ui.reduce_motion() else 1.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_p(v: float) -> void:
	_p = v
	queue_redraw()

func _draw() -> void:
	if Ui.reduce_motion():
		draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.BG_TOP, _p))
		return
	var n := float(COLS + _rows)
	for r in _rows:
		for c in COLS:
			# Kapanırken sol-üstten, açılırken sağ-alttan başlar → kumaş kayıyor gibi.
			var d := float(c + r) / n
			if not _closing:
				d = 1.0 - d
			var t := clampf((_p * 1.7 - d * 0.7), 0.0, 1.0)
			if t <= 0.0:
				continue
			var e := 1.0 + 2.70158 * pow(t - 1.0, 3) + 1.70158 * pow(t - 1.0, 2)   # back-out
			var s := _side * 1.08 * e
			if s < 6.0:
				continue
			var ctr := Vector2((c + 0.5) * _side, (r + 0.5) * _side)
			var rect := Rect2(ctr - Vector2(s, s) / 2.0, Vector2(s, s))
			var poly := Ui.rrect(rect, s * 0.16, 3)
			var i := (c * 7 + r * 5) % 12
			var tex := Fabrics.get_tex(i)
			if tex:
				var uv := PackedVector2Array()
				var ts := tex.get_size() * 0.75
				for p in poly:
					uv.append(p / ts)
				draw_colored_polygon(poly, Color.WHITE, uv, tex)
			else:
				draw_colored_polygon(poly, Palette.piece(i))
			if t > 0.6:
				draw_multiline(PieceShape.dashes(Ui.rrect(rect.grow(-s * 0.08), s * 0.1, 3), 12.0, 8.0), Color(Palette.STITCH, 0.8 * (t - 0.6) / 0.4), 3.0)
