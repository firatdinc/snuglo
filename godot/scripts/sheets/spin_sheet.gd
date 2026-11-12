extends Sheet
## Günlük çark: nakış kasnağı çark (art/ui/wheel.png, 8 eşit dilim, dilim k merkezi 22.5°+45°k
## saat yönünde tepeden), üstte ahşap iğne (wheel_pointer) her dilim sınırında "tık"lar ve çırpar.
## Döndür: Spin.choose_index() → 6 tam tur + hedef, yavaşlayarak (~3.3 sn) → Spin.commit → ödül.
## Dev: SNUG_AUTOSPIN=1 açılınca kendiliğinden döndürür.

const TURNS := 6
const DUR := 3.3

var _spinner: Control
var _pointer: TextureRect
var _btn: JuicyButton
var _timer_l: Label
var _rot := 0.0
var _last_b := 0
var _spinning := false
var _flap := 0.0
var _acc := 0.0

func _init() -> void:
	panel_size = Vector2(-1, 1400)
	dismissible = true

func build() -> void:
	var w := pw()
	var y := banner_title(tr("spin.title")) + 30
	var sub := Ui.label(tr("spin.available") if Spin.can_spin() else tr("spin.comeBack"), 36, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(sub, Vector2(40, y - 6), Vector2(w - 80, 50))
	y += 225
	var ws := minf(w - 120, 700.0)
	var rays := Rays.new()
	rays.alpha = 0.25
	add(rays, Vector2((w - ws * 1.3) / 2.0, y - ws * 0.15), Vector2(ws * 1.3, ws * 1.3))
	_spinner = Control.new()
	_spinner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add(_spinner, Vector2((w - ws) / 2.0, y + 30), Vector2(ws, ws))
	_spinner.pivot_offset = Vector2(ws, ws) / 2.0
	var shadow := Ui.tex_rect(UiArt.tex("wheel"), Vector2(ws, ws))
	shadow.modulate = Color(0.3, 0.15, 0.05, 0.3)
	add(shadow, Vector2((w - ws) / 2.0, y + 44))
	panel.move_child(shadow, _spinner.get_index())
	var wheel := Ui.tex_rect(UiArt.tex("wheel"), Vector2(ws, ws))
	_spinner.add_child(wheel)
	var c := Vector2(ws, ws) / 2.0
	for k in Spin.SEGMENTS.size():
		var seg: Dictionary = Spin.SEGMENTS[k]
		var a := deg_to_rad(22.5 + 45.0 * k)
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.size = Vector2(130, 150)
		holder.pivot_offset = holder.size / 2.0
		var at := c + Vector2(sin(a), -cos(a)) * ws * 0.30
		holder.position = at - holder.size / 2.0
		holder.rotation = a
		_spinner.add_child(holder)
		var ic := Ui.icon(Ui.currency_icon(String(seg.currency)), Vector2(78, 78))
		ic.position = Vector2(26, 0)
		holder.add_child(ic)
		var l := Ui.title(str(seg.amount), 40, Palette.CREAM)
		Ui.place(l, Vector2(0, 74), Vector2(130, 56))
		holder.add_child(l)
	# İğne (aşağıyı gösterir), tepeye
	var ph := ws * 0.34
	var pwid := ph * 282.0 / 525.0
	_pointer = Ui.tex_rect(UiArt.tex("wheel_pointer"), Vector2(pwid, ph))
	add(_pointer, Vector2((w - pwid) / 2.0, y + 30 - ph * 0.8))
	_pointer.pivot_offset = Vector2(pwid / 2.0, ph * 0.12)
	y += ws + 70
	_btn = Ui.button(tr("spin.spin"), "terracotta", Vector2(w - 200, 160), "", 64)
	add(_btn, Vector2(100, y))
	_btn.tapped.connect(_spin)
	_btn.denied.connect(func() -> void: Ui.shake(_btn, 12.0))
	_timer_l = Ui.label("", 34, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(_timer_l, Vector2(40, y + 170), Vector2(w - 80, 50))
	if not Spin.can_spin():
		_btn.disabled = true
		_tick_timer()
	panel.size.y = y + 240
	_place_panel()
	panel.position.y += 20
	close_x()
	if Dev.env("SNUG_AUTOSPIN") != "" and Spin.can_spin():
		get_tree().create_timer(0.6).timeout.connect(_spin)

func _tick_timer() -> void:
	if Spin.can_spin():
		_timer_l.text = ""
		return
	var d: Dictionary = Time.get_datetime_dict_from_system()
	var left := 86400 - (int(d.hour) * 3600 + int(d.minute) * 60 + int(d.second))
	_timer_l.text = "%s · %s" % [tr("spin.comeBack"), Ui.fmt_time(left)]

func _process(dt: float) -> void:
	_acc += dt
	if _acc > 0.5 and not _spinning:
		_acc = 0.0
		_tick_timer()
	_flap = move_toward(_flap, 0.0, dt * 4.0)
	if _pointer:
		_pointer.rotation = -_flap * 0.35

func _spin() -> void:
	if _spinning or not Spin.can_spin():
		return
	_spinning = true
	_btn.disabled = true
	dismissible = false
	var idx := Spin.choose_index()
	var start := _rot
	var target := -(22.5 + 45.0 * idx)
	var delta := fposmod(target - start, 360.0)
	var end := start + 360.0 * TURNS + delta
	# Hafif jitter: dilimin içinde rastgele (kenara yapışmasın)
	end += randf_range(-14.0, 14.0)
	_last_b = int(floor(start / 45.0))
	Sfx.play("click", 0.8, -4.0)
	Juice.haptic("medium")
	var tw := create_tween()
	if Ui.reduce_motion():
		tw.tween_method(_set_rot, start, end, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		# Geri çekme (anticipation) + uzun yavaşlama
		tw.tween_method(_set_rot, start, start - 12.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_method(_set_rot, start - 12.0, end, DUR).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: _land(idx))

func _set_rot(r: float) -> void:
	_rot = r
	_spinner.rotation_degrees = r
	var b := int(floor(r / 45.0))
	if b != _last_b:
		_last_b = b
		_flap = 1.0
		Sfx.play("click", 1.3 + randf() * 0.2, -10.0, 0.0)
		Juice.haptic("tick")

func _land(idx: int) -> void:
	var seg := Spin.commit(idx)
	_spinning = false
	Sfx.play("levelUp", 1.0, -2.0, 0.0)
	Juice.haptic("heavy")
	Juice.add_trauma(0.3)
	Ui.punch(_spinner, 0.06)
	if seg.is_empty():
		dismissible = true
		return
	get_tree().create_timer(0.45).timeout.connect(func() -> void:
		var r := {String(seg.currency): int(seg.amount)}
		var m := Main.reward(tr("spin.reward"), r, {"double": true, "pose": "cheer", "cta": tr("spin.collect")})
		if m:
			m.closed.connect(close)
		else:
			close())
