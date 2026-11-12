class_name Rays
extends Control
## Dönen güneş ışını (ödül anları): sıcak krem/altın dilimler, yavaş döner, yumuşak kenar.

var col := Palette.GOLD
var count := 14
var speed := 0.35
var alpha := 0.35
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(dt: float) -> void:
	_t += dt * (0.0 if Ui.reduce_motion() else speed)
	queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var r := size.x / 2.0
	for i in count:
		var a := _t + i * TAU / count
		var w := TAU / count * 0.32
		var pts := PackedVector2Array([c, c + Vector2.from_angle(a - w) * r, c + Vector2.from_angle(a + w) * r])
		var cols := PackedColorArray([Color(col, alpha), Color(col, 0.0), Color(col, 0.0)])
		draw_polygon(pts, cols)
	for k in 6:
		draw_circle(c, r * (0.42 - k * 0.06), Color(Palette.CREAM, 0.07 + k * 0.025))
