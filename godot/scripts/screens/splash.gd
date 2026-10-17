extends Screen
## Açılış: logo "dikiş dikiş" belirir — iğne soldan sağa diker, arkasında kesikli iplik izi kalır,
## her dikişte nota yükselir; bitince logo zıplar, tembel hayvan el sallar. ~2.4 sn ya da dokun → geç.

const DUR := 1.5

var _clip: Control
var _logo: TextureRect
var _needle: TextureRect
var _thread: ThreadTrail
var _mascot: TextureRect
var _fx: Fx
var _p := 0.0
var _last_step := -1
var _done := false
var _lw := 0.0

func build() -> void:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("island")
	bg.size = size
	bg.wash_top = 0.75
	bg.wash_bottom = 0.85
	bg.zoom = 1.14
	add_child(bg)
	var wash := ColorRect.new()
	wash.color = Color(Palette.BG_TOP, 0.5)
	wash.size = size
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	var tex := UiArt.tex("logo")
	_lw = minf(W - 120.0, 900.0)
	var lh := _lw * tex.get_height() / tex.get_width()
	var ly := H * 0.30 - lh / 2.0
	# İplik izi (logonun altında)
	_thread = ThreadTrail.new()
	put(_thread, Vector2(X0 + (W - _lw) / 2.0, ly + lh * 0.95), Vector2(_lw, 30))
	# Kırpılan logo: genişlik dikiş ilerledikçe açılır.
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(_clip, Vector2(X0 + (W - _lw) / 2.0, ly), Vector2(0, lh))
	_logo = Ui.tex_rect(tex, Vector2(_lw, lh))
	_logo.position = Vector2.ZERO
	_clip.add_child(_logo)
	_needle = Ui.icon("ic_hint", Vector2(150, 168))
	put(_needle, Vector2(_clip.position.x - 75, ly - 40))
	_needle.rotation = -0.5
	# Maskot
	var ms := minf(W * 0.48, 520.0)
	_mascot = Ui.icon("wave", Vector2(ms, ms), "mascot")
	put(_mascot, Vector2(X0 + (W - ms) / 2.0, H * 0.52))
	_mascot.pivot_offset = Vector2(ms / 2.0, ms * 0.9)
	_mascot.scale = Vector2.ZERO
	var tag := Ui.label(tr("app.tagline"), 46, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	tag.add_theme_color_override("font_outline_color", Palette.CREAM)
	tag.add_theme_constant_override("outline_size", 14)
	put(tag, Vector2(X0, H * 0.52 + ms + 20), Vector2(W, 70))
	tag.modulate.a = 0.0
	tag.name = "tag"
	var fxn := Node2D.new()
	add_child(fxn)
	_fx = Fx.new()
	fxn.add_child(_fx)
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_method(_sew, 0.0, 1.0, DUR if not Ui.reduce_motion() else 0.2)
	tw.tween_callback(_finish_logo)
	tw.tween_interval(1.1)
	tw.tween_callback(_leave)
	get_tree().create_timer(0.9).timeout.connect(_mascot_in)

func _sew(p: float) -> void:
	_p = p
	# Dikiş dikiş: 14 adım, her adım hızla açılır.
	var steps := 14
	var s := floorf(p * steps)
	var frac := clampf((p * steps - s) * 3.0, 0.0, 1.0)
	var w := _lw * minf(1.0, (s + frac) / steps)
	_clip.size.x = w
	_thread.reveal = w / _lw
	_thread.queue_redraw()
	_needle.position.x = _clip.position.x + w - 60.0
	_needle.position.y = _clip.position.y - 40.0 + sin(p * steps * PI) * 36.0
	if int(s) != _last_step and s < steps:
		_last_step = int(s)
		Sfx.note(_last_step % 12, "place", -12.0)
		Juice.haptic("tick")
		_fx.puff(Vector2(_needle.position.x + 40, _clip.position.y + _clip.size.y * 0.9), 2, Palette.CREAM, 10.0)

func _finish_logo() -> void:
	_clip.size.x = _lw
	_thread.reveal = 1.0
	Ui.punch(_clip, 0.12)
	_clip.pivot_offset = _clip.size / 2.0
	Sfx.play("solve", 1.1, -6.0, 0.0)
	Juice.haptic("medium")
	_fx.sparks(_clip.position + _clip.size / 2.0, 22, Palette.GOLD, 900.0)
	var tw := _needle.create_tween().set_parallel()
	tw.tween_property(_needle, "position", _needle.position + Vector2(260, -380), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(_needle, "rotation", 1.6, 0.45)
	tw.tween_property(_needle, "modulate:a", 0.0, 0.45)
	var tag := get_node("tag") as Control
	create_tween().tween_property(tag, "modulate:a", 1.0, 0.4)

func _mascot_in() -> void:
	var tw := _mascot.create_tween()
	tw.tween_property(_mascot, "scale", Vector2(1.15, 0.85), 0.18).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_mascot, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Sfx.play("snap", 1.2, -8.0)
	if not Ui.reduce_motion():
		var wv := _mascot.create_tween().set_loops(3)
		wv.tween_property(_mascot, "rotation", 0.08, 0.18).set_trans(Tween.TRANS_SINE)
		wv.tween_property(_mascot, "rotation", -0.06, 0.18).set_trans(Tween.TRANS_SINE)
		wv.finished.connect(func() -> void: _mascot.rotation = 0.0)

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch and e.pressed and not _done and _p > 0.2:
		_leave()

func _leave() -> void:
	if _done:
		return
	_done = true
	Main.goto("menu" if bool(Settings.get_value("onboarded")) else "onboarding")

## Logonun altında açılan kesikli iplik.
class ThreadTrail extends Control:
	var reveal := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var w := size.x * reveal
		if w <= 2.0:
			return
		var pts := PackedVector2Array()
		var n := 40
		for i in n + 1:
			var x := w * i / n
			pts.append(Vector2(x, size.y / 2.0 + sin(x * 0.03) * 6.0))
		var segs := PackedVector2Array()
		var on := true
		for i in pts.size() - 1:
			if on:
				segs.append(pts[i])
				segs.append(pts[i + 1])
			on = not on
		draw_multiline(segs, Color(Palette.INK, 0.25), 7.0)
		draw_multiline(segs, Palette.TERRACOTTA, 5.0)
