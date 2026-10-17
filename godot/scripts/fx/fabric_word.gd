class_name FabricWord
extends Control
## Kumaş yamalı övgü yazısı (logo gibi): her harf ayrı Label, farklı kumaş dokusu (shader),
## krem keçe kontür + koyu kabartma gölgesi. Harfler sırayla yaylanır, sonra süzülüp söner.
## Kullanım: FabricWord.show_at(parent, "Harika!", merkez, font_boyu, {sub = "×3", hold = 0.9})

const SHADER := preload("res://scripts/fx/fabric_letter.gdshader")
const SENTINEL := Color(1, 0, 1)   # kontür işaret rengi (shader keçeye çevirir)

static var _current: WeakRef

var _letters: Array[Control] = []

static func show_at(parent: Node, text: String, center: Vector2, fs: int, opts := {}) -> FabricWord:
	# Ekranda tek övgü: eskisi hızla söner.
	if _current and _current.get_ref():
		(_current.get_ref() as FabricWord).dismiss(0.12)
	var w := FabricWord.new()
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.z_index = 100   # yerleşmiş parçalar (z 1..39) ve sürüklenenin (50) üstünde
	parent.add_child(w)
	w._build(text, fs, String(opts.get("sub", "")))
	w.position = center - w.size / 2.0
	w.pivot_offset = w.size / 2.0
	w._play(float(opts.get("hold", 0.9)))
	_current = weakref(w)
	return w

## Yazının ölçüsü (yerleştirme hesabı için).
static func measure(text: String, fs: int) -> Vector2:
	var f: Font = Ui.FONT
	var wsum := 0.0
	for ch in text:
		wsum += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.96
	return Vector2(wsum + fs * 0.4, fs * 1.35)

func _build(text: String, fs: int, sub: String) -> void:
	var f: Font = Ui.FONT
	var outline := maxi(6, int(fs * 0.16))
	var x := fs * 0.2
	var start := randi() % 12
	var k := 0
	for ch in text:
		var cw := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		if ch == " ":
			x += cw
			continue
		var box := Control.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.size = Vector2(cw + outline * 2, fs * 1.35)
		box.position = Vector2(x - outline, 0)
		box.pivot_offset = Vector2(box.size.x / 2.0, box.size.y * 0.75)
		add_child(box)
		# Kabartma gölgesi (koyu, aşağı kaymış)
		var dark := Color(0.23, 0.13, 0.08)
		var sh := _label(ch, fs, outline + int(fs * 0.05), Color(dark, 0.5), Color(dark, 0.5))
		sh.size = box.size
		sh.position = Vector2(0, fs * 0.1)
		box.add_child(sh)
		var edge := _label(ch, fs, outline + int(fs * 0.045), dark, dark)
		edge.size = box.size
		box.add_child(edge)
		# Kumaş harf
		var l := _label(ch, fs, outline, Color.WHITE, SENTINEL)
		var m := ShaderMaterial.new()
		m.shader = SHADER
		var tex := Fabrics.get_tex(start + k * 5)
		if tex:
			m.set_shader_parameter("fabric", tex)
		m.set_shader_parameter("tile", fs * 2.4)
		m.set_shader_parameter("offset", Vector2(randf(), randf()))
		var asc := f.get_ascent(fs)
		var top_y := (box.size.y - f.get_height(fs)) / 2.0 + asc - fs * 0.72
		m.set_shader_parameter("top", top_y)
		m.set_shader_parameter("bottom", top_y + fs * 0.78)
		l.material = m
		l.size = box.size
		box.add_child(l)
		_letters.append(box)
		x += cw * 0.96
		k += 1
	size = Vector2(x + fs * 0.2, fs * 1.35)
	if sub != "":
		var s := Ui.title(sub, maxi(30, int(fs * 0.5)), Palette.MUSTARD.lightened(0.25))
		s.size = Vector2(size.x, fs * 0.6)
		s.position = Vector2(0, size.y - fs * 0.3)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)
		s.pivot_offset = s.size / 2.0
		_letters.append(s)

func _label(ch: String, fs: int, outline: int, col: Color, ocol: Color) -> Label:
	var l := Label.new()
	l.text = ch
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", Ui.FONT)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", ocol)
	l.add_theme_constant_override("outline_size", outline * 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func _play(hold: float) -> void:
	var rm := Ui.reduce_motion()
	var n := _letters.size()
	for i in n:
		var b := _letters[i]
		if rm:
			b.modulate.a = 0.0
			b.create_tween().tween_property(b, "modulate:a", 1.0, 0.15)
			continue
		b.scale = Vector2.ZERO
		b.rotation = randf_range(-0.35, 0.35)
		var tw := b.create_tween()
		tw.tween_interval(i * 0.045)
		tw.tween_property(b, "scale", Vector2(1.22, 1.22), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(b, "rotation", randf_range(-0.07, 0.07), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# hafif sürekli sallantı (dikişli yama gibi)
		tw.tween_property(b, "rotation", b.rotation * -1.0 if b.rotation != 0.0 else 0.04, 0.35).set_trans(Tween.TRANS_SINE)
	var total := (0.15 if rm else n * 0.045 + 0.35) + hold
	var t2 := create_tween()
	t2.tween_interval(total)
	t2.tween_callback(func() -> void: dismiss(0.4))

## Sön: yukarı süzül + kaybol.
func dismiss(dur := 0.4) -> void:
	if is_queued_for_deletion() or has_meta("dying"):
		return
	set_meta("dying", true)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position:y", position.y - (0.0 if Ui.reduce_motion() else 70.0), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(queue_free)
