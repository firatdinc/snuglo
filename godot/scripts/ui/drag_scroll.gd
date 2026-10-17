class_name DragScroll
extends Control
## Parmakla kaydırılan, ataletli + lastik bantlı kaydırma alanı. Butonların üstünden başlayan
## sürükleme de kaydırır (_input ile izlenir); sürükleme eşiği aşılınca basılı butonlar iptal olur.
## Kullanım: var s := DragScroll.new(); s.size = ...; s.content.add_child(...); s.set_length(h)

const THRESHOLD := 18.0

static var _active := false
static var _released_at := -10.0

## Şu an (ya da az önce) bir kaydırma sürüklemesi oldu mu: buton dokunuşlarını iptal etmek için.
static func recently_dragged() -> bool:
	return _active or Time.get_ticks_msec() / 1000.0 - _released_at < 0.08

var horizontal := false
var content := Control.new()
var length := 0.0
var offset := 0.0
var pad_end := 0.0
var _vel := 0.0
var _track := false
var _drag := false
var _start := Vector2.ZERO
var _last := 0.0
var _last_t := 0.0

func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

func set_length(l: float) -> void:
	length = l
	if horizontal:
		content.size = Vector2(l, size.y)
	else:
		content.size = Vector2(size.x, l)

func view_len() -> float:
	return size.x if horizontal else size.y

func max_offset() -> float:
	return maxf(0.0, length + pad_end - view_len())

func scroll_to(o: float, animate := true) -> void:
	o = clampf(o, 0.0, max_offset())
	_vel = 0.0
	if animate and not Ui.reduce_motion():
		create_tween().tween_method(_set_offset, offset, o, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_set_offset(o)

func _set_offset(o: float) -> void:
	offset = o
	_apply()

func _apply() -> void:
	if horizontal:
		content.position = Vector2(-offset, 0)
	else:
		content.position = Vector2(0, -offset)

func _axis(v: Vector2) -> float:
	return v.x if horizontal else v.y

func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventScreenTouch and e.index == 0:
		if e.pressed:
			if get_global_rect().has_point(e.position) and _topmost():
				_track = true
				_drag = false
				_start = e.position
				_last = _axis(e.position)
				_last_t = Time.get_ticks_msec() / 1000.0
				_vel = 0.0
		elif _track:
			_track = false
			if _drag:
				_drag = false
				_active = false
				_released_at = Time.get_ticks_msec() / 1000.0
	elif e is InputEventMouseButton and e.pressed and get_global_rect().has_point(e.position):
		if e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_vel = 2200.0
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_vel = -2200.0
	elif e is InputEventScreenDrag and e.index == 0 and _track:
		var tot: Vector2 = e.position - _start
		if not _drag:
			var along := absf(_axis(tot))
			var across := absf(tot.y if horizontal else tot.x)
			if along > THRESHOLD and along > across:
				_drag = true
				_active = true
				_last = _axis(e.position)
			elif across > THRESHOLD * 2.0:
				_track = false
			return
		var a := _axis(e.position)
		var d := a - _last
		var now := Time.get_ticks_msec() / 1000.0
		var dt := maxf(now - _last_t, 0.001)
		_vel = lerpf(_vel, -d / dt, 0.4)
		_last = a
		_last_t = now
		var over := offset < 0.0 or offset > max_offset()
		offset -= d * (0.45 if over else 1.0)
		_apply()

## Bir sheet/örtü üstteyse alttaki ekran kaydırmasın.
func _topmost() -> bool:
	var layer := _layer_of(self)
	return Main.is_layer_on_top(layer)

static func _layer_of(n: Node) -> CanvasLayer:
	var p := n.get_parent()
	while p and not (p is CanvasLayer):
		p = p.get_parent()
	return p as CanvasLayer

func _process(dt: float) -> void:
	if _drag:
		return
	var mo := max_offset()
	if offset < 0.0:
		offset = lerpf(offset, 0.0, 1.0 - exp(-14.0 * dt))
		_vel = 0.0
		if absf(offset) < 0.5:
			offset = 0.0
		_apply()
	elif offset > mo:
		offset = lerpf(offset, mo, 1.0 - exp(-14.0 * dt))
		_vel = 0.0
		if absf(offset - mo) < 0.5:
			offset = mo
		_apply()
	elif absf(_vel) > 5.0:
		offset += _vel * dt
		_vel *= pow(0.04, dt)
		_apply()
