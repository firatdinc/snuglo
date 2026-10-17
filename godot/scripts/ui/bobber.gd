class_name Bobber
extends Node
## Ebeveyni yavaşça yukarı-aşağı süzdürür (konumu kaydırmadan: position'a ofset ekler).

var amp := 10.0
var period := 2.4
var phase := 0.0
var _t := 0.0
var _last := 0.0

func _process(dt: float) -> void:
	var p := get_parent()
	if not (p is CanvasItem):
		return
	_t += dt
	var y := sin(_t / period * TAU + phase) * amp
	if p is Control:
		(p as Control).position.y += y - _last
	elif p is Node2D:
		(p as Node2D).position.y += y - _last
	_last = y
