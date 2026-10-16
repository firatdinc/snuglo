class_name JuicyButton
extends Control
## Kendi çizdiği "şeker" buton: alt kalınlık, basınca çöker, bırakınca yaylanır.

signal tapped

@export var text := ""
@export var color := Palette.piece(0)
@export var font_size := 44
var radius := 36.0
var _press := 0.0
var _spring := 1.0
var _vs := 0.0
var _down := false
var _font: Font = preload("res://art/fonts/fredoka_bold.tres")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		if e.pressed:
			_down = true
			Juice.haptic("tick")
			Sfx.play("click", 1.25, -10.0)
		elif _down:
			_down = false
			_vs += 5.0
			if Rect2(Vector2.ZERO, size).has_point(e.position):
				Sfx.play("click", 0.95, -4.0)
				tapped.emit()
		accept_event()

func _process(dt: float) -> void:
	_press = move_toward(_press, 1.0 if _down else 0.0, dt * 14.0)
	var target := 0.94 if _down else 1.0
	_vs += (target - _spring) * 400.0 * dt - _vs * 18.0 * dt
	_spring += _vs * dt
	scale = Vector2(_spring, _spring)
	queue_redraw()

func _draw() -> void:
	var depth := 12.0
	var dy := depth * _press
	var r := Rect2(Vector2(0, dy), size - Vector2(0, depth))
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	sb.bg_color = Palette.SHADOW
	draw_style_box(sb, Rect2(Vector2(0, depth + 6), size - Vector2(0, depth)))
	sb.bg_color = color.darkened(0.3)
	draw_style_box(sb, Rect2(Vector2(0, depth), size - Vector2(0, depth)))
	sb.bg_color = color
	draw_style_box(sb, r)
	sb.bg_color = Color(1, 1, 1, 0.18)
	draw_style_box(sb, Rect2(r.position + Vector2(10, 6), Vector2(r.size.x - 20, r.size.y * 0.42)))
	var ts := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var p := r.get_center() + Vector2(-ts.x / 2.0, font_size * 0.36)
	draw_string(_font, p + Vector2(0, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color.darkened(0.45))
	draw_string(_font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.CREAM)
