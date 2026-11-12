extends RefCounted
## Kurabiye mini oyunu çizim yardımcıları: oyunun keçe/kumaş dili (kumaş dokusu, gölge,
## koyu alt kenar, krem kesikli dikiş). Hiçbir görsel dosya gerekmez.

## Kumaş indeksleri (Palette.PIECES / Fabrics).
const F_TERRA := 0
const F_MUSTARD := 1
const F_SAGE := 2
const F_DENIM := 3
const F_PLUM := 4
const F_PEACH := 5
const F_SEA := 6
const F_ROSE := 7
const F_TWEED := 8
const F_LAV := 9
const F_CARAMEL := 10
const F_SKY := 11

const ING_BLOB: Array[Color] = [Color(0.97, 0.94, 0.88), Color(0.98, 0.9, 0.9), Color(0.95, 0.72, 0.28), Color(0.96, 0.85, 0.45)]
const ICING: Array[Color] = [Color(1.0, 0.98, 0.93), Color(0.84, 0.27, 0.23), Color(0.36, 0.6, 0.36)]
const SPR: Array[Color] = [Color(0.88, 0.4, 0.36), Color(0.45, 0.66, 0.42), Color(0.95, 0.75, 0.3), Color(0.45, 0.6, 0.78), Color(0.9, 0.62, 0.7)]

## true: fırın/tepsi yer tutucusu (kumaş dokusu ve dikiş yok; emaye/metal).
static var flat := false
static var _poly := {}
static var _inset := {}

# ------------------------------------------------------------------ Geometri

static func ell(c: Vector2, rx: float, ry: float, n := 40) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		o.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return o

static func shift(p: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var o := PackedVector2Array()
	o.resize(p.size())
	for i in p.size():
		o[i] = p[i] + d
	return o

static func xf(p: PackedVector2Array, c: Vector2, s: float, rot := 0.0) -> PackedVector2Array:
	var o := PackedVector2Array()
	o.resize(p.size())
	for i in p.size():
		o[i] = c + (p[i] * s).rotated(rot)
	return o

static func _largest(r: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	for x: PackedVector2Array in r:
		if not Geometry2D.is_polygon_clockwise(x) and x.size() > best.size():
			best = x
	return best

static func off(p: PackedVector2Array, d: float) -> PackedVector2Array:
	if p.size() < 3:
		return p
	return _largest(Geometry2D.offset_polygon(p, d, Geometry2D.JOIN_ROUND))

static func _union(polys: Array) -> PackedVector2Array:
	var base: PackedVector2Array = polys[0]
	for i in range(1, polys.size()):
		var q: PackedVector2Array = polys[i]
		var best := PackedVector2Array()
		for m: PackedVector2Array in Geometry2D.merge_polygons(base, q):
			if not Geometry2D.is_polygon_clockwise(m) and m.size() > best.size():
				best = m
		if best.size() > 2:
			base = best
	return base

static func _cap(a: Vector2, b: Vector2, r: float) -> PackedVector2Array:
	var ang := (b - a).angle()
	var pts := PackedVector2Array()
	for i in 13:
		pts.append(b + Vector2.from_angle(ang - PI / 2 + PI * i / 12.0) * r)
	for i in 13:
		pts.append(a + Vector2.from_angle(ang + PI / 2 + PI * i / 12.0) * r)
	return pts

## Kalıp şekli 0 yıldız, 1 ağaç, 2 kalp, 3 adam, 4 çan. Birim kutuya (±0.5) sığar.
static func shape(id: int) -> PackedVector2Array:
	if _poly.has(id):
		return _poly[id]
	var p := PackedVector2Array()
	match id:
		0:
			for i in 10:
				p.append(Vector2.from_angle(-PI / 2 + TAU * i / 10.0) * (0.5 if i % 2 == 0 else 0.23))
		1:
			var a := PackedVector2Array([Vector2(0, -0.5), Vector2(-0.22, -0.2), Vector2(0.22, -0.2)])
			var b := PackedVector2Array([Vector2(0, -0.34), Vector2(-0.32, 0.06), Vector2(0.32, 0.06)])
			var c := PackedVector2Array([Vector2(0, -0.14), Vector2(-0.44, 0.3), Vector2(0.44, 0.3)])
			var t := PackedVector2Array([Vector2(-0.07, 0.25), Vector2(0.07, 0.25), Vector2(0.07, 0.5), Vector2(-0.07, 0.5)])
			p = _union([a, b, c, t])
		2:
			for i in 48:
				var t := TAU * i / 48.0
				var x := 16.0 * pow(sin(t), 3.0)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				p.append(Vector2(x, y) / 34.0)
		3:
			var parts: Array = [
				ell(Vector2(0, -0.33), 0.15, 0.15, 24),
				PackedVector2Array([Vector2(-0.14, -0.2), Vector2(0.14, -0.2), Vector2(0.14, 0.2), Vector2(-0.14, 0.2)]),
				_cap(Vector2(-0.1, -0.14), Vector2(-0.38, -0.02), 0.07), _cap(Vector2(0.1, -0.14), Vector2(0.38, -0.02), 0.07),
				_cap(Vector2(-0.07, 0.14), Vector2(-0.15, 0.42), 0.08), _cap(Vector2(0.07, 0.14), Vector2(0.15, 0.42), 0.08)]
			p = _union(parts)
		_:
			var half := [Vector2(0, -0.45), Vector2(0.1, -0.43), Vector2(0.19, -0.34), Vector2(0.23, -0.16), Vector2(0.27, 0.08), Vector2(0.36, 0.26), Vector2(0.45, 0.32)]
			var bell := PackedVector2Array()
			for v: Vector2 in half:
				bell.append(v)
			for i in range(half.size() - 1, -1, -1):
				bell.append(Vector2(-half[i].x, half[i].y))
			bell.append(Vector2(-0.45, 0.32))
			var bb := PackedVector2Array([Vector2(-0.45, 0.32), Vector2(0.45, 0.32), Vector2(0.45, 0.36), Vector2(-0.45, 0.36)])
			p = _union([bell, bb, ell(Vector2(0, 0.42), 0.075, 0.075, 16)])
	p = off(off(p, -0.015), 0.035)
	var r := Rect2(p[0], Vector2.ZERO)
	for v in p:
		r = r.expand(v)
	var k := 0.96 / maxf(r.size.x, r.size.y)
	var c0 := r.get_center()
	for i in p.size():
		p[i] = (p[i] - c0) * k
	_poly[id] = p
	return p

static func inset(id: int) -> PackedVector2Array:
	if not _inset.has(id):
		var q := off(shape(id), -0.05)
		_inset[id] = q if q.size() > 2 else shape(id)
	return _inset[id]

# ------------------------------------------------------------------ Keçe temel çizimi

static func dashes(poly: PackedVector2Array, dash: float, gap: float) -> PackedVector2Array:
	return PieceShape.dashes(poly, dash, gap)

static func ring(p: PackedVector2Array) -> PackedVector2Array:
	var r := p.duplicate()
	r.append(p[0])
	return r

## Dikiş: gölgeli koyu çizgi + krem iplik. d: segmentler (dashes).
static func stitch(ci: CanvasItem, p: PackedVector2Array, w: float, col := Palette.CREAM, dash := 0.0, gap := 0.0) -> void:
	if p.size() < 3:
		return
	var dd := PieceShape.dashes(p, dash if dash > 0.0 else w * 3.2, gap if gap > 0.0 else w * 2.2)
	if dd.size() < 2:
		return
	ci.draw_multiline(shift(dd, Vector2(w * 0.35, w * 0.5)), Color(0.25, 0.12, 0.05, 0.4), w)
	ci.draw_multiline(dd, col, w)

## Keçe parça: gölge, koyu alt kenar, kumaş dokusu (tex>=0), sıcak kenar halkası, krem dikiş.
## uv_seed: kumaş kaydırma. sti: dikiş poligonu (boşsa içeri çekilerek üretilir; null → yok).
static func felt(ci: CanvasItem, p: PackedVector2Array, col: Color, tex_i := -1, depth := 8.0, tint := Color.WHITE,
		stitch_in := 14.0, uv_seed := 0, shadow := true, sti: PackedVector2Array = PackedVector2Array()) -> void:
	if p.size() < 3:
		return
	if flat:
		tex_i = -1
		stitch_in = 0.0
	if shadow:
		ci.draw_colored_polygon(shift(p, Vector2(0, depth * 0.6 + 6.0)), Palette.SHADOW)
	if depth > 0.0:
		ci.draw_colored_polygon(shift(p, Vector2(0, depth)), col.darkened(0.28))
	var tex: Texture2D = Fabrics.get_tex(tex_i) if tex_i >= 0 else null
	if tex:
		ci.draw_colored_polygon(p, tint, Fabrics.uvs(p, tex, tex_i * 7 + uv_seed), tex)
	else:
		ci.draw_colored_polygon(p, col.lerp(tint, 0.0) * tint)
	var rg := ring(p)
	var u := maxf(6.0, depth * 1.1)
	ci.draw_polyline(rg, Color(0.3, 0.14, 0.06, 0.26), u, true)
	ci.draw_polyline(rg, Color(0.3, 0.14, 0.06, 0.16), u * 0.45, true)
	if stitch_in > 0.0 or sti.size() > 2:
		var s := sti if sti.size() > 2 else off(p, -stitch_in)
		stitch(ci, s, maxf(2.0, stitch_in * 0.22), Palette.CREAM if tex else col.lightened(0.45))

static func felt_rr(ci: CanvasItem, r: Rect2, rad: float, col: Color, tex_i := -1, depth := 8.0, tint := Color.WHITE,
		stitch_in := 14.0, uv_seed := 0, shadow := true) -> void:
	felt(ci, Ui.rrect(r, rad, 8), col, tex_i, depth, tint, stitch_in, uv_seed, shadow)

# ------------------------------------------------------------------ Kurabiye

static func dough_tint(bake: float, jit := 0.0) -> Color:
	var b := clampf(bake + jit, 0.0, 1.0)
	return Color(1.0, 0.97, 0.9).lerp(Color(0.8, 0.55, 0.32), smoothstep(0.0, 1.0, b))

## id şekli c merkezine s boyutunda (kutu), bake 0 hamur → 1 altın kahve.
static func cookie(ci: CanvasItem, id: int, c: Vector2, s: float, bake := 0.0, jit := 0.0) -> void:
	var sc := s * (1.0 + 0.05 * bake)
	var body := xf(shape(id), c, sc)
	var base := Palette.PIECES[F_PEACH].lerp(Palette.PIECES[F_CARAMEL], bake)
	var d := sc * (0.045 + 0.02 * bake)
	felt(ci, body, base, F_PEACH, d, dough_tint(bake, jit), 0.0, id * 13)
	var inn := xf(inset(id), c + Vector2(-sc * 0.01, -sc * 0.012), sc)
	ci.draw_colored_polygon(inn, Color(1, 0.96, 0.85, 0.12 + 0.06 * (1.0 - bake)))
	stitch(ci, xf(inset(id), c, sc), maxf(2.5, sc * 0.016), Palette.CREAM.lerp(Color(0.95, 0.8, 0.55), bake) )

# ------------------------------------------------------------------ Kâse ve malzemeler

static func bowl_back(ci: CanvasItem, c: Vector2, R: float) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var t := PI * i / 24.0
		pts.append(c + Vector2(cos(t) * R, sin(t) * R * 0.95))
	for i in range(1, 24):
		var t := PI + PI * i / 24.0
		pts.append(c + Vector2(cos(t) * R, sin(t) * R * 0.3))
	felt(ci, pts, Palette.PIECES[F_DENIM], F_DENIM, R * 0.05, Color.WHITE, 0.0, 3)
	# dikiş bandı
	var band := PackedVector2Array()
	for i in 25:
		var t := PI * i / 24.0
		band.append(c + Vector2(cos(t) * R * 0.97, 0.22 * R + sin(t) * R * 0.62))
	var bd := PieceShape.dashes(band, 16.0, 11.0)
	ci.draw_multiline(bd, Color(0.25, 0.12, 0.05, 0.35), 6.0)
	ci.draw_multiline(shift_ms(bd, Vector2(0, -2)), Palette.CREAM, 5.0)
	# iç
	var ic := ell(c + Vector2(0, R * 0.02), R * 0.9, R * 0.26, 56)
	ci.draw_colored_polygon(ic, Palette.PIECES[F_DENIM].darkened(0.55))
	ci.draw_colored_polygon(ell(c + Vector2(0, R * 0.05), R * 0.86, R * 0.22, 56), Palette.PIECES[F_DENIM].darkened(0.42))

static func shift_ms(p: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	return shift(p, d)

static func bowl_lip(ci: CanvasItem, c: Vector2, R: float) -> void:
	var f := PackedVector2Array()
	for i in 41:
		var t := PI * i / 40.0
		f.append(c + Vector2(cos(t) * R * 0.995, sin(t) * R * 0.3))
	ci.draw_polyline(shift(f, Vector2(0, 6)), Color(0.1, 0.07, 0.1, 0.35), R * 0.06, true)
	ci.draw_polyline(f, Palette.PIECES[F_DENIM].lightened(0.12), R * 0.05, true)
	var ds := PieceShape.dashes(shift(f, Vector2(0, -R * 0.0)), 14.0, 10.0)
	ci.draw_multiline(ds, Palette.CREAM, 4.0)

## k: 0 un, 1 şeker, 2 yumurta, 3 tereyağı. s: kutu boyutu.
static func ingredient(ci: CanvasItem, k: int, c: Vector2, s: float) -> void:
	match k:
		0:
			var r := Rect2(c + Vector2(-0.32, -0.42) * s, Vector2(0.64, 0.84) * s)
			felt_rr(ci, r, s * 0.1, Palette.CARD, F_PEACH, s * 0.05, Color(1, 0.98, 0.94), s * 0.07)
			var z := PackedVector2Array()
			for i in 9:
				z.append(c + Vector2(-0.32 + 0.08 * i, -0.42 + (0.0 if i % 2 == 0 else 0.06)) * s)
			ci.draw_polyline(z, Palette.PIECES[F_DENIM].darkened(0.2), s * 0.025, true)
			ci.draw_colored_polygon(ell(c + Vector2(0, 0.08) * s, s * 0.2, s * 0.2, 28), Palette.PIECES[F_DENIM])
			stitch(ci, ell(c + Vector2(0, 0.08) * s, s * 0.16, s * 0.16, 28), s * 0.016)
			for i in 3:
				var a := -0.5 + 0.5 * i
				ci.draw_line(c + Vector2(0, 0.17) * s, c + Vector2(sin(a) * 0.12, 0.17 - cos(a) * 0.17) * s, Palette.CREAM, s * 0.02, true)
		1:
			for o: Vector3 in [Vector3(-0.17, 0.14, 0), Vector3(0.17, 0.14, 1), Vector3(0.0, -0.14, 2)]:
				felt_rr(ci, Rect2(c + Vector2(o.x - 0.15, o.y - 0.15) * s, Vector2.ONE * 0.3 * s), s * 0.05, Palette.PIECES[F_LAV], F_LAV, s * 0.04, Color(1.1, 1.08, 1.12), s * 0.045, int(o.z))
			var sp := c + Vector2(0.28, -0.3) * s
			ci.draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -0.1) * s, sp + Vector2(0.03, -0.03) * s, sp + Vector2(0.1, 0) * s, sp + Vector2(0.03, 0.03) * s, sp + Vector2(0, 0.1) * s, sp + Vector2(-0.03, 0.03) * s, sp + Vector2(-0.1, 0) * s, sp + Vector2(-0.03, -0.03) * s]), Palette.CREAM)
		2:
			var e := ell(c, 0.3 * s, 0.38 * s, 36)
			felt(ci, e, Palette.PIECES[F_PEACH], F_PEACH, s * 0.045, Color(1.0, 0.92, 0.8), s * 0.05, 2)
			ci.draw_colored_polygon(ell(c + Vector2(-0.1, -0.13) * s, 0.06 * s, 0.1 * s, 14), Color(1, 1, 1, 0.3))
		_:
			var r := Rect2(c + Vector2(-0.42, -0.22) * s, Vector2(0.84, 0.44) * s)
			felt_rr(ci, r, s * 0.07, Palette.PIECES[F_MUSTARD], F_MUSTARD, s * 0.05, Color(1.12, 1.08, 0.9), s * 0.055, 5)
			var w := Rect2(c + Vector2(-0.42, -0.22) * s, Vector2(0.34, 0.44) * s)
			felt_rr(ci, w, s * 0.06, Palette.CARD, F_SEA if false else F_PEACH, s * 0.02, Color(1, 0.98, 0.94), 0.0, 6, false)
			ci.draw_line(c + Vector2(0.1, -0.22) * s, c + Vector2(0.1, 0.22) * s, Color(0.3, 0.14, 0.06, 0.25), s * 0.015, true)

# ------------------------------------------------------------------ Tezgâh ve araçlar

## Merdane: yatay, c merkez, w gövde uzunluğu.
static func pin(ci: CanvasItem, c: Vector2, w: float) -> void:
	for sx in [-1.0, 1.0]:
		felt_rr(ci, Rect2(c + Vector2(w * 0.5 * sx - (0.0 if sx > 0 else 90.0), -26), Vector2(90, 52)), 24.0, Palette.PIECES[F_CARAMEL].darkened(0.1), F_CARAMEL, 5.0, Color(0.9, 0.85, 0.8), 0.0, 3, sx > 0)
	felt_rr(ci, Rect2(c - Vector2(w * 0.5, 50), Vector2(w, 100)), 44.0, Palette.PIECES[F_CARAMEL], F_CARAMEL, 9.0, Color.WHITE, 0.0, 0, true)
	ci.draw_line(c + Vector2(-w * 0.45, -26), c + Vector2(w * 0.45, -26), Color(1, 0.95, 0.85, 0.28), 8.0, true)
	var dd := PieceShape.dashes(off(Ui.rrect(Rect2(c - Vector2(w * 0.5 - 16, 34), Vector2(w - 32, 68)), 30.0, 8), 0.0), 16.0, 12.0)
	ci.draw_multiline(dd, Color(0.25, 0.12, 0.05, 0.3), 3.5)
	ci.draw_multiline(shift_ms(dd, Vector2(0, -2)), Palette.CREAM, 3.5)

static func spoon(ci: CanvasItem, tip: Vector2) -> void:
	var dir := Vector2(0.45, -0.89).normalized()
	ci.draw_line(tip + Vector2(6, 10), tip + dir * 380.0 + Vector2(6, 10), Palette.SHADOW, 26.0, true)
	ci.draw_line(tip, tip + dir * 380.0, Palette.PIECES[F_CARAMEL].darkened(0.25), 28.0, true)
	ci.draw_line(tip, tip + dir * 380.0, Palette.PIECES[F_CARAMEL].lightened(0.1), 20.0, true)
	var hd := xf(ell(Vector2.ZERO, 0.5, 0.38, 24), tip, 92.0, 0.5)
	felt(ci, hd, Palette.PIECES[F_CARAMEL], F_CARAMEL, 6.0, Color(0.95, 0.9, 0.85), 0.0)

static func tray(ci: CanvasItem, sz: Vector2) -> void:
	var r := Rect2(-sz / 2.0, sz)
	var steel := Color(0.7, 0.72, 0.76)
	var was := flat
	flat = true
	felt_rr(ci, r, 46.0, steel, -1, 14.0, Color.WHITE, 0.0, 4)
	var i := Rect2(r.position + Vector2(34, 34), sz - Vector2(68, 68))
	ci.draw_colored_polygon(Ui.rrect(i, 30.0, 8), Color(0.3, 0.3, 0.34, 0.25))
	ci.draw_polyline(ring(Ui.rrect(i, 30.0, 8)), Color(1, 1, 1, 0.35), 4.0, true)
	for sx in [-1.0, 1.0]:
		felt_rr(ci, Rect2(Vector2(sx * (sz.x / 2.0 + 20.0) - 24.0, -26.0), Vector2(48, 52)), 20.0, steel.darkened(0.1), -1, 6.0, Color.WHITE, 0.0, 1, false)
	flat = was

static func plate(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 96:
		var a := TAU * i / 96.0
		pts.append(c + Vector2.from_angle(a) * r * (1.0 + 0.014 * cos(a * 20.0)))
	felt(ci, pts, Palette.CARD, F_PEACH, r * 0.03, Color(1.0, 0.97, 0.92), 0.0, 1)
	ci.draw_colored_polygon(ell(c, r * 0.84, r * 0.84, 80), Color(0.5, 0.3, 0.15, 0.1))
	ci.draw_arc(c, r * 0.84, 0, TAU, 80, Color(0.3, 0.14, 0.06, 0.2), 6.0, true)
	stitch(ci, ell(c, r * 0.92, r * 0.92, 90), 5.0, Palette.PIECES[F_TERRA].lightened(0.3))

# ------------------------------------------------------------------ Fırın

const OVEN_SIZE := Vector2(940, 880)
const WIN := Rect2(-330, -170, 660, 400)

## glow 0..1 (iç ışık), prog 0..1 (kadran), flash 0..1.
static func oven_body(ci: CanvasItem, glow: float, prog: float, w := WIN) -> void:
	felt_rr(ci, Rect2(-470, -440, 940, 880), 70.0, Palette.PIECES[F_TERRA], F_TERRA, 16.0, Color.WHITE, 22.0, 2)
	# üst panel + düğmeler
	felt_rr(ci, Rect2(-420, -400, 840, 150), 40.0, Palette.PIECES[F_TERRA].darkened(0.08), F_TERRA, 8.0, Color(0.88, 0.8, 0.78), 12.0, 5, false)
	# kapak
	felt_rr(ci, Rect2(-440, -228, 880, 636), 44.0, Palette.PIECES[F_TERRA].lightened(0.1), F_TERRA, 10.0, Color(1.1, 1.05, 1.05), 0.0, 8, false)
	felt_rr(ci, Rect2(-290, -208, 580, 30), 15.0, Palette.PIECES[F_MUSTARD], F_MUSTARD, 5.0, Color.WHITE, 0.0, 3, false)
	# ayaklar
	for sx in [-1.0, 1.0]:
		felt_rr(ci, Rect2(sx * 360 - 50, 430, 100, 36), 16.0, Palette.PIECES[F_TERRA].darkened(0.3), F_TERRA, 4.0, Color(0.7, 0.6, 0.6), 0.0, 1, false)
	# pencere içi
	ci.draw_colored_polygon(Ui.rrect(w, 38.0, 8), Color(0.2, 0.09, 0.06))
	for i in 9:
		var g := glow * (0.07 + 0.012 * i)
		ci.draw_colored_polygon(Ui.rrect(w.grow(-20.0 - i * 18.0), maxf(8.0, 36.0 - i * 3.0), 8), Color(1.0, 0.55 + 0.04 * i, 0.2, g))

static func oven_glass(ci: CanvasItem, t: float, flash: float, door := 0.0, w := WIN) -> void:
	if door > 0.02:
		# yer tutucu: açık kapak = pencerenin altına inmiş panel
		felt_rr(ci, Rect2(w.position + Vector2(-20, w.size.y * 0.55 + (1.0 - door) * -w.size.y * 0.5), Vector2(w.size.x + 40, 150.0 * door + 40.0)), 30.0, Palette.PIECES[F_TERRA].lightened(0.1), F_TERRA, 8.0, Color.WHITE, 0.0, 8)
	var rr := Ui.rrect(w, 38.0, 8)
	ci.draw_colored_polygon(rr, Color(1.0, 0.6, 0.25, 0.08 + 0.12 * flash))
	# ısı dalgaları
	for i in 6:
		var pts := PackedVector2Array()
		var x0 := w.position.x + 70.0 + i * 104.0
		for j in 14:
			var y := w.end.y - 20.0 - j * 28.0
			pts.append(Vector2(x0 + sin(t * 2.2 + j * 0.7 + i) * 8.0, y))
		ci.draw_polyline(pts, Color(1.0, 0.88, 0.6, 0.12), 6.0, true)
	# cam parlaması
	ci.draw_colored_polygon(PackedVector2Array([w.position + Vector2(40, 8), w.position + Vector2(120, 8), w.position + Vector2(40, 130)]), Color(1, 1, 1, 0.1))
	# çerçeve (keçe halka): pencere kenarını örten kalın şerit
	var ringp := Ui.rrect(w.grow(8.0), 44.0, 8)
	ci.draw_polyline(ring(ringp), Palette.PIECES[F_TERRA].darkened(0.25), 34.0, true)
	ci.draw_polyline(ring(Ui.rrect(w.grow(26.0), 52.0, 8)), Palette.PIECES[F_TERRA].lightened(0.05), 8.0, true)
	stitch(ci, Ui.rrect(w.grow(-4.0), 40.0, 8), 4.0)

# ------------------------------------------------------------------ Süsleme araçları

static func bag(ci: CanvasItem, c: Vector2, s: float, k: int, sel: bool) -> void:
	var lift := -16.0 if sel else 0.0
	c += Vector2(0, lift)
	var col := ICING[k]
	var tx: int = [F_PEACH, F_ROSE, F_SAGE][k]
	var tri := PackedVector2Array([c + Vector2(-0.3, -0.45) * s, c + Vector2(0.3, -0.45) * s, c + Vector2(0.06, 0.4) * s, c + Vector2(-0.06, 0.4) * s])
	tri = off(tri, s * 0.03)
	felt(ci, tri, col, tx, s * 0.04, Color(1, 0.99, 0.96) if k == 0 else Color.WHITE, s * 0.045, k)
	var tip := PackedVector2Array([c + Vector2(-0.07, 0.38) * s, c + Vector2(0.07, 0.38) * s, c + Vector2(0.0, 0.52) * s])
	ci.draw_colored_polygon(tip, Palette.CARD)
	if sel:
		ci.draw_arc(c + Vector2(0, 0.02 * s), s * 0.62, 0, TAU, 40, Color(Palette.CREAM, 0.9), 5.0, true)

static func jar(ci: CanvasItem, c: Vector2, s: float, sel: bool) -> void:
	c += Vector2(0, -16.0 if sel else 0.0)
	felt_rr(ci, Rect2(c + Vector2(-0.3, -0.3) * s, Vector2(0.6, 0.72) * s), s * 0.12, Palette.CARD, F_PEACH, s * 0.04, Color(1, 0.98, 0.94), s * 0.05, 3)
	for i in 14:
		var a := i * 2.4
		var q := c + Vector2(cos(a) * 0.17, 0.08 + sin(a * 1.3) * 0.2) * s
		ci.draw_line(q - Vector2(1, 0.4) * s * 0.03, q + Vector2(1, 0.4) * s * 0.03, SPR[i % SPR.size()], s * 0.045, true)
	felt_rr(ci, Rect2(c + Vector2(-0.33, -0.44) * s, Vector2(0.66, 0.16) * s), s * 0.06, Palette.PIECES[F_TERRA], F_TERRA, s * 0.03, Color.WHITE, 0.0, 2, false)
	if sel:
		ci.draw_arc(c + Vector2(0, 0.02 * s), s * 0.62, 0, TAU, 40, Color(Palette.CREAM, 0.9), 5.0, true)

## Krema çizgisi: koyu kenar + kabarık gövde + parlama. pts piksel.
static func icing(ci: CanvasItem, pts: PackedVector2Array, k: int, w := 22.0) -> void:
	if pts.is_empty():
		return
	var col := ICING[k]
	var edge := col.darkened(0.3) if k > 0 else Color(0.78, 0.7, 0.6)
	var hi := col.lightened(0.45) if k > 0 else Color(1, 1, 1)
	_poly_stroke(ci, shift(pts, Vector2(0, 4)), Color(0.25, 0.12, 0.05, 0.28), w + 10.0)
	_poly_stroke(ci, pts, edge, w + 8.0)
	_poly_stroke(ci, pts, col, w)
	_poly_stroke(ci, shift(pts, Vector2(-w * 0.14, -w * 0.18)), Color(hi, 0.75), w * 0.3)

static func _poly_stroke(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	if pts.size() > 1:
		ci.draw_polyline(pts, col, w, true)
	ci.draw_circle(pts[0], w * 0.5, col)
	ci.draw_circle(pts[pts.size() - 1], w * 0.5, col)

static func sprinkle(ci: CanvasItem, p: Vector2, ang: float, k: int, sc := 1.0) -> void:
	var d := Vector2.from_angle(ang) * 9.0 * sc
	ci.draw_line(p - d + Vector2(1.5, 2.5), p + d + Vector2(1.5, 2.5), Color(0.25, 0.12, 0.05, 0.3), 9.0 * sc, true)
	ci.draw_line(p - d, p + d, SPR[k % SPR.size()].darkened(0.2), 9.0 * sc, true)
	ci.draw_line(p - d * 0.95 + Vector2(0, -1.5), p + d * 0.9 + Vector2(0, -1.5), SPR[k % SPR.size()], 5.5 * sc, true)

## Yuvarlak, keçe hamur topu / kütle.
static func dough_ball(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := ell(c, r, r * 0.92, 48)
	felt(ci, pts, Palette.PIECES[F_PEACH], F_PEACH, r * 0.1, Color(1, 0.96, 0.86), r * 0.12, 1)
	ci.draw_colored_polygon(ell(c + Vector2(-r * 0.25, -r * 0.3), r * 0.28, r * 0.18, 20), Color(1, 1, 1, 0.14))
