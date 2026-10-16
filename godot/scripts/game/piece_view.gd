class_name PieceView
extends Node2D
## Bir parçanın görseli + yay (spring) tabanlı ölçek/eğim. Orijin = parçanın merkezi,
## böylece squash/stretch ve eğim merkezden olur.

enum State { TRAY, DRAG, FLYING, PLACED }

var data: PieceData
var cs := 100.0                  # tahta hücre boyutu (px)
var state := State.TRAY
var home := Vector2.ZERO         # tepsideki yeri
var tray_scale := 0.5
var lift := 0.0                  # 0 yerde, 1 havada → gölge büyür
var flash := 0.0                 # beyaz parlama (yerleşim / ipucu)
var invalid := 0.0               # kırmızı uyarı

# Yaylar: hedefe doğru sönümlü salınım. Darbeler hıza eklenir.
var target_scale := 1.0
var _sx := 1.0
var _sy := 1.0
var _vsx := 0.0
var _vsy := 0.0
var target_rot := 0.0
var _vrot := 0.0
var squash := 0.0                # >0: yassı (x geniş y kısa)

var _font: Font

func _init() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR

func setup(p: PieceData, cell_size: float) -> void:
	data = p
	cs = cell_size
	_font = preload("res://art/fonts/fredoka_bold.tres")
	queue_redraw()

func size_px() -> Vector2:
	return Vector2(data.size) * cs

## Dünya koordinatındaki nokta parçanın dolu bir hücresine denk geliyor mu?
func hit(world: Vector2, pad := 0.18) -> bool:
	var local := (to_local(world) + size_px() / 2.0) / cs
	for c in data.cells:
		if Rect2(Vector2(c) - Vector2(pad, pad), Vector2.ONE * (1.0 + pad * 2)).has_point(local):
			return true
	return false

func set_scale_now(s: float) -> void:
	target_scale = s
	_sx = s
	_sy = s
	_vsx = 0.0
	_vsy = 0.0
	scale = Vector2(s, s)

func punch(sx: float, sy: float) -> void:
	_vsx += sx
	_vsy += sy

func wobble(v: float) -> void:
	_vrot += v

func _process(dt: float) -> void:
	dt = minf(dt, 1.0 / 30.0)
	var k := 320.0
	var d := 16.0
	_vsx += (target_scale - _sx) * k * dt - _vsx * d * dt
	_vsy += (target_scale - _sy) * k * dt - _vsy * d * dt
	_sx += _vsx * dt
	_sy += _vsy * dt
	_vrot += (target_rot - rotation) * 260.0 * dt - _vrot * 14.0 * dt
	rotation += _vrot * dt
	scale = Vector2(_sx, _sy)
	var fl := flash
	var inv := invalid
	flash = move_toward(flash, 0.0, dt * 3.0)
	invalid = move_toward(invalid, 0.0, dt * 2.5)
	if fl != flash or inv != invalid or state == State.DRAG or abs(_vsx) > 0.01:
		queue_redraw()

func _draw() -> void:
	if data == null:
		return
	var sh := PieceShape.build(data.cells, cs)
	var off := -size_px() / 2.0
	var col := Palette.piece(data.color_index)
	if invalid > 0.0:
		col = col.lerp(Palette.BAD, invalid * 0.6)
	var depth := cs * 0.085
	draw_set_transform(off + Vector2(0, depth * 0.6 + lift * cs * 0.22), 0.0, Vector2.ONE * (1.0 + lift * 0.04))
	draw_colored_polygon(sh.outer, Color(Palette.SHADOW, Palette.SHADOW.a * (0.7 + lift * 0.6)))
	draw_set_transform(off + Vector2(0, depth), 0.0, Vector2.ONE)
	draw_colored_polygon(sh.outer, col.darkened(0.28))
	draw_set_transform(off, 0.0, Vector2.ONE)
	var tex := Fabrics.get_tex(data.color_index)
	if tex:
		var tint := Color.WHITE.lerp(Palette.BAD, invalid * 0.6)
		draw_colored_polygon(sh.outer, tint, Fabrics.uvs(sh.outer, tex, data.color_index), tex)
	else:
		draw_colored_polygon(sh.outer, col)
	# Yastık şişkinliği: kenarda sıcak gölge (kenar içe kıvrılmış), üst-solda yumuşak ışık.
	var ring: PackedVector2Array = sh.outer.duplicate()
	ring.append(sh.outer[0])
	draw_polyline(ring, Color(0.3, 0.14, 0.06, 0.28), cs * 0.09, true)
	draw_polyline(ring, Color(0.3, 0.14, 0.06, 0.18), cs * 0.04, true)
	if sh.hi.size() > 2:
		draw_set_transform(off + Vector2(-cs * 0.03, -cs * 0.035), 0.0, Vector2.ONE)
		draw_colored_polygon(sh.hi, Color(1, 0.97, 0.9, 0.1 if tex else 0.14))
		draw_set_transform(off, 0.0, Vector2.ONE)
	# Dikiş: krem iplik + altında gölgesi (kumaşa batan iplik hissi).
	var d := PieceShape.dashes(sh.stitch, cs * 0.09, cs * 0.06)
	if d.size() > 1:
		var w := maxf(2.0, cs * 0.032)
		draw_set_transform(off + Vector2(w * 0.35, w * 0.5), 0.0, Vector2.ONE)
		draw_multiline(d, Color(0.25, 0.12, 0.05, 0.45), w)
		draw_set_transform(off, 0.0, Vector2.ONE)
		draw_multiline(d, Palette.CREAM if tex else col.lightened(0.45), w)
	# Alan sayısı: işlenmiş rakam.
	var c0 := Vector2(data.cells[0]) * cs + Vector2(cs, cs) * 0.5
	var fs := int(cs * 0.42)
	var txt := str(data.cells.size())
	var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var p := c0 + Vector2(-tw.x / 2.0, fs * 0.36)
	draw_string(_font, p + Vector2(0, cs * 0.025), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col.darkened(0.35))
	draw_string(_font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)
	if flash > 0.0:
		draw_colored_polygon(sh.outer, Color(1, 1, 1, flash * 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
