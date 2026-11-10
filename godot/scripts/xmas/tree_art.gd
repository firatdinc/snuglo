extends RefCounted
## Keçe ağaç: prosedürel çizimler ve çizim düğümleri. PieceView dili: gölge, koyu alt kenar,
## kumaş dokusu (Fabrics, "classic" set), kenarda yastık gölgesi, krem kesikli dikiş.
## Görsel dosya varsa (art/xmas/tree/<ad>.png) o kullanılır.

const Art := preload("res://scripts/xmas/tree_art.gd")
const SET := "classic"
const BOX := 150.0
const KINDS: Array[String] = ["ball_red", "ball_gold", "ball_green", "star_top", "candy_cane", "bell",
	"ball_blue", "gingerbread_orn", "snowflake_orn", "bow_orn", "heart_orn", "ball_pink"]
## Kumaş indeksi (art/fabric/classic): 0 terrakota, 1 hardal, 2 adaçayı, 3 denim, 4 erik, 5 şeftali,
## 6 deniz yeşili örgü, 7 gül, 8 zeytin, 9 lavanta, 10 karamel, 11 gökyüzü.
const FAB := {"ball_red": 0, "ball_gold": 1, "ball_green": 2, "ball_blue": 3, "ball_pink": 7, "star_top": 1,
	"bell": 1, "gingerbread_orn": 10, "snowflake_orn": 11, "bow_orn": 4, "heart_orn": 0, "candy_cane": 0}
static var _tex_cache := {}

static func tex(name: String) -> Texture2D:
	if not _tex_cache.has(name):
		var p := "res://art/xmas/tree/%s.png" % name
		_tex_cache[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex_cache[name]

## 9 dilim: dokuyu k ölçeğiyle çizer (kenar payları doku pikseli). tile: yatay/dikey orta bölge döşenir.
static func nine(ci: CanvasItem, name: String, rect: Rect2, m: Vector4, k: float, tile := false) -> bool:
	var t := tex(name)
	if t == null:
		return false
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.texture_margin_left = m.x
	sb.texture_margin_top = m.y
	sb.texture_margin_right = m.z
	sb.texture_margin_bottom = m.w
	if tile:
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	ci.draw_set_transform(rect.position, 0.0, Vector2(k, k))
	ci.draw_style_box(sb, Rect2(Vector2.ZERO, rect.size / k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

## Ip dokusunu çizgi boyunca döşer (kalınlık w).
static func cord(ci: CanvasItem, pts: PackedVector2Array, w: float, mod := Color.WHITE) -> void:
	var t := tex("tree_cord")
	if t == null or pts.size() < 2:
		return
	var tl := w * t.get_width() / t.get_height()
	var s := 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := b - a
		var l := d.length()
		if l < 0.01:
			continue
		var n := d.orthogonal().normalized() * w * 0.5
		var u0 := s / tl
		var u1 := (s + l) / tl
		ci.draw_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), PackedColorArray([mod, mod, mod, mod]),
			PackedVector2Array([Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(u0, 1)]), t)
		s += l

static func anchor(kind: String) -> Vector2:
	match kind:
		"star_top": return Vector2(75, 78)
		"candy_cane": return Vector2(60, 24)
	return Vector2(75, 14)

static func col(i: int) -> Color:
	return Palette.PIECES[i % Palette.PIECES.size()]

# ---------- keçe yardımcıları ----------

static func circle(c: Vector2, r: float, n := 36) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		p.append(c + Vector2.from_angle(TAU * i / n) * r)
	return p

static func rounded(p: PackedVector2Array, r: float) -> PackedVector2Array:
	var a := Geometry2D.offset_polygon(p, -r, Geometry2D.JOIN_ROUND)
	if a.is_empty():
		return p
	var b := Geometry2D.offset_polygon(a[0], r, Geometry2D.JOIN_ROUND)
	return b[0] if not b.is_empty() else p

static func inset(p: PackedVector2Array, d: float) -> PackedVector2Array:
	var a := Geometry2D.offset_polygon(p, -d, Geometry2D.JOIN_ROUND)
	var best := PackedVector2Array()
	for x in a:
		if x.size() > best.size():
			best = x
	return best

## Bir keçe parça: gölge, koyu alt, kumaş dokusu, kenar gölgesi, krem kesikli dikiş.
static func felt(ci: CanvasItem, poly: PackedVector2Array, fab: int, depth := 5.0, stitch := 7.0,
		shadow := true) -> void:
	if poly.size() < 3:
		return
	var c := col(fab)
	if shadow:
		ci.draw_set_transform(Vector2(0, depth * 1.1), 0.0, Vector2.ONE)
		ci.draw_colored_polygon(poly, Palette.SHADOW)
	ci.draw_set_transform(Vector2(0, depth), 0.0, Vector2.ONE)
	ci.draw_colored_polygon(poly, c.darkened(0.28))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var t := Fabrics.get_tex(fab, SET)
	if t:
		ci.draw_colored_polygon(poly, Color.WHITE, Fabrics.uvs(poly, t, fab), t)
	else:
		ci.draw_colored_polygon(poly, c)
	var ring := poly.duplicate()
	ring.append(poly[0])
	ci.draw_polyline(ring, Color(0.3, 0.14, 0.06, 0.28), depth * 1.5, true)
	ci.draw_polyline(ring, Color(0.3, 0.14, 0.06, 0.18), depth * 0.7, true)
	var hi := inset(poly, depth * 1.6)
	if hi.size() > 2:
		ci.draw_set_transform(Vector2(-depth * 0.4, -depth * 0.5), 0.0, Vector2.ONE)
		ci.draw_colored_polygon(hi, Color(1, 0.97, 0.9, 0.09 if t else 0.14))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if stitch > 0.0:
		var sp := inset(poly, stitch)
		if sp.size() > 2:
			var d := PieceShape.dashes(sp, 9.0, 6.0)
			if d.size() > 1:
				var w := maxf(2.2, depth * 0.55)
				ci.draw_set_transform(Vector2(w * 0.35, w * 0.5), 0.0, Vector2.ONE)
				ci.draw_multiline(d, Color(0.25, 0.12, 0.05, 0.45), w)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				ci.draw_multiline(d, Palette.CREAM if t else c.lightened(0.45), w)

## Açık çizgi boyunca kesikli krem dikiş (gölgeli).
static func dline(ci: CanvasItem, pts: PackedVector2Array, w := 3.0) -> void:
	var d := PackedVector2Array()
	var on := true
	var left := 8.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		var t := 0.0
		while t < seg:
			var step := minf(left, seg - t)
			if on:
				d.append(a.lerp(b, t / seg))
				d.append(a.lerp(b, (t + step) / seg))
			t += step
			left -= step
			if left <= 0.0001:
				on = not on
				left = 8.0 if on else 6.0
	if d.size() < 2:
		return
	ci.draw_set_transform(Vector2(w * 0.3, w * 0.45), 0.0, Vector2.ONE)
	ci.draw_multiline(d, Color(0.25, 0.12, 0.05, 0.45), w)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_multiline(d, Palette.CREAM, w)

static func cap_and_string(ci: CanvasItem, top: Vector2, hanging: bool) -> void:
	var a := anchor("")
	if hanging:
		ci.draw_line(a + Vector2(1.5, 1.5), top + Vector2(1.5, 1.5), Color(0.25, 0.12, 0.05, 0.3), 3.5, true)
		ci.draw_line(a, top, Palette.CREAM.darkened(0.12), 3.0, true)
		ci.draw_circle(a, 4.5, Palette.CREAM.darkened(0.2))
	felt(ci, rounded(Ui.rrect(Rect2(top.x - 10, top.y - 2, 20, 12), 4), 1.0), 1, 2.0, 0.0, false)

# ---------- süs çizimleri ----------

static func draw_orn(ci: CanvasItem, kind: String, hanging: bool) -> void:
	var t := tex(kind)
	if t:
		var s := t.get_size()
		var k := minf(BOX / s.x, BOX / s.y)
		var sz := s * k
		ci.draw_texture_rect(t, Rect2((Vector2(BOX, BOX) - sz) / 2.0, sz), false)
		return
	match kind:
		"ball_red", "ball_gold", "ball_green", "ball_blue", "ball_pink":
			_ball(ci, kind, hanging)
		"star_top": _star(ci)
		"candy_cane": _cane(ci)
		"bell": _bell(ci, hanging)
		"gingerbread_orn": _ginger(ci, hanging)
		"snowflake_orn": _flake(ci, hanging)
		"bow_orn": _bow(ci, hanging)
		"heart_orn": _heart(ci, hanging)

static func _ball(ci: CanvasItem, kind: String, hanging: bool) -> void:
	var c := Vector2(75, 88)
	var r := 46.0
	cap_and_string(ci, Vector2(75, c.y - r - 6), hanging)
	felt(ci, circle(c, r), FAB[kind], 5.0, 8.0)
	var cr := Palette.CREAM
	match kind:
		"ball_red":
			var p := PackedVector2Array()
			for i in 17:
				p.append(c + Vector2(lerpf(-r * 0.7, r * 0.7, i / 16.0), sin(i * 1.1) * 6.0))
			dline(ci, p, 3.4)
		"ball_gold":
			for i in 6:
				ci.draw_circle(c + Vector2.from_angle(TAU * i / 6.0) * 17.0, 4.0, cr)
			ci.draw_circle(c, 5.0, cr)
		"ball_green":
			for k in [-0.5, 0.0, 0.5]:
				var p := PackedVector2Array()
				for i in 15:
					var a := lerpf(-PI / 2.0, PI / 2.0, i / 14.0)
					p.append(c + Vector2(k * r * cos(a), sin(a) * r * 0.55))
				dline(ci, p, 3.0)
		"ball_blue":
			for i in 5:
				var x := lerpf(-22.0, 22.0, i / 4.0)
				ci.draw_line(c + Vector2(x - 4, -3), c + Vector2(x + 4, 3), cr, 3.4, true)
				ci.draw_line(c + Vector2(x - 4, 3), c + Vector2(x + 4, -3), cr, 3.4, true)
		"ball_pink":
			for i in 5:
				ci.draw_circle(c + Vector2(lerpf(-22.0, 22.0, i / 4.0), 0), 3.6, cr)
			for i in 4:
				ci.draw_circle(c + Vector2(lerpf(-11.0, 11.0, i / 3.0), 13), 3.0, cr)
				ci.draw_circle(c + Vector2(lerpf(-11.0, 11.0, i / 3.0), -13), 3.0, cr)

static func _star_poly(c: Vector2, ro: float, ri: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 10:
		p.append(c + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * (ro if i % 2 == 0 else ri))
	return p

static func _star(ci: CanvasItem) -> void:
	var c := Vector2(75, 80)
	felt(ci, rounded(_star_poly(c, 68.0, 31.0), 7.0), 1, 6.0, 9.0)
	ci.draw_circle(c + Vector2(0, 4), 5.0, Palette.CREAM)

static func _cane(ci: CanvasItem) -> void:
	var path := PackedVector2Array()
	for y in range(144, 56, -3):
		path.append(Vector2(86, y))
	for i in 25:
		var a := lerpf(0.0, PI * 1.05, i / 24.0)
		path.append(Vector2(60, 56) + Vector2(cos(a), -sin(a)) * 26.0)
	var sh := PackedVector2Array()
	for p in path:
		sh.append(p + Vector2(2, 6))
	ci.draw_polyline(sh, Palette.SHADOW, 25.0, true)
	ci.draw_polyline(path, col(0).darkened(0.35), 26.0, true)
	ci.draw_polyline(path, Palette.CREAM, 20.0, true)
	var i := 0
	var k := 0
	while i < path.size() - 1:
		if k % 2 == 0:
			ci.draw_polyline(path.slice(i, mini(i + 7, path.size())), col(0), 20.0, false)
		i += 6
		k += 1
	ci.draw_polyline(path, Color(0.3, 0.14, 0.06, 0.2), 2.0, true)
	var hl := PackedVector2Array()
	for p in path:
		hl.append(p + Vector2(-5, -2))
	ci.draw_polyline(hl, Color(1, 0.97, 0.9, 0.14), 3.0, true)

static func _bell(ci: CanvasItem, hanging: bool) -> void:
	cap_and_string(ci, Vector2(75, 40), hanging)
	var p := PackedVector2Array()
	for i in 13:
		var a := lerpf(PI, 0.0, i / 12.0)
		p.append(Vector2(75, 66) + Vector2(cos(a) * 26.0, -sin(a) * 26.0))
	p.append_array(PackedVector2Array([Vector2(104, 92), Vector2(116, 118), Vector2(126, 122),
		Vector2(126, 130), Vector2(24, 130), Vector2(24, 122), Vector2(34, 118), Vector2(46, 92)]))
	felt(ci, circle(Vector2(75, 135), 9.0, 18), 8, 2.5, 0.0, false)
	felt(ci, rounded(p, 4.0), 1, 5.0, 8.0)
	dline(ci, PackedVector2Array([Vector2(32, 117), Vector2(118, 117)]), 3.0)

static func _capsule(a: Vector2, b: Vector2, r: float) -> PackedVector2Array:
	var n := (b - a).orthogonal().normalized() * r
	var q := PackedVector2Array([a + n, b + n, b - n, a - n])
	for e in [circle(a, r, 14), circle(b, r, 14)]:
		var m := Geometry2D.merge_polygons(q, e)
		if not m.is_empty():
			q = m[0]
	return q

static func _ginger(ci: CanvasItem, hanging: bool) -> void:
	cap_and_string(ci, Vector2(75, 30), hanging)
	var parts: Array[PackedVector2Array] = [
		_capsule(Vector2(62, 76), Vector2(32, 90), 9.0), _capsule(Vector2(88, 76), Vector2(118, 90), 9.0),
		_capsule(Vector2(66, 104), Vector2(56, 134), 10.0), _capsule(Vector2(84, 104), Vector2(94, 134), 10.0)]
	for p in parts:
		felt(ci, p, 10, 4.0, 0.0, true)
	felt(ci, rounded(Ui.rrect(Rect2(55, 66, 40, 50), 14), 1.0), 10, 4.0, 6.0, true)
	felt(ci, circle(Vector2(75, 50), 21.0, 24), 10, 4.0, 5.0, true)
	for p in [Vector2(75, 82), Vector2(75, 96)]:
		ci.draw_circle(p, 4.2, col(0))
	ci.draw_circle(Vector2(75, 108), 4.2, col(2))
	ci.draw_circle(Vector2(68, 46), 2.6, Palette.INK)
	ci.draw_circle(Vector2(82, 46), 2.6, Palette.INK)
	ci.draw_arc(Vector2(75, 51), 9.0, 0.35, PI - 0.35, 8, Palette.CREAM, 3.0, true)
	dline(ci, PackedVector2Array([Vector2(36, 92), Vector2(42, 80)]))
	dline(ci, PackedVector2Array([Vector2(114, 92), Vector2(108, 80)]))

static func _flake(ci: CanvasItem, hanging: bool) -> void:
	var c := Vector2(75, 88)
	cap_and_string(ci, Vector2(75, c.y - 52), hanging)
	felt(ci, circle(c, 46.0), 11, 5.0, 8.0)
	var cr := Palette.CREAM
	for i in 6:
		var d := Vector2.from_angle(TAU * i / 6.0 - PI / 2.0)
		var o := d.orthogonal()
		ci.draw_line(c + Vector2(1, 1.5), c + d * 25.0 + Vector2(1, 1.5), Color(0.25, 0.12, 0.05, 0.3), 5.0, true)
		ci.draw_line(c, c + d * 25.0, cr, 4.5, true)
		var m := c + d * 15.0
		ci.draw_line(m, m + (d + o).normalized() * 9.0, cr, 3.6, true)
		ci.draw_line(m, m + (d - o).normalized() * 9.0, cr, 3.6, true)
	ci.draw_circle(c, 5.0, cr)

static func _bow(ci: CanvasItem, hanging: bool) -> void:
	cap_and_string(ci, Vector2(75, 66), hanging)
	var l := PackedVector2Array([Vector2(75, 92), Vector2(30, 66), Vector2(22, 96), Vector2(32, 122)])
	var r := PackedVector2Array([Vector2(75, 92), Vector2(120, 66), Vector2(128, 96), Vector2(118, 122)])
	var tl := PackedVector2Array([Vector2(75, 94), Vector2(52, 142), Vector2(70, 138), Vector2(80, 112)])
	var tr_ := PackedVector2Array([Vector2(75, 94), Vector2(98, 142), Vector2(80, 138), Vector2(70, 112)])
	felt(ci, rounded(tl, 2.0), 4, 4.0, 5.0)
	felt(ci, rounded(tr_, 2.0), 4, 4.0, 5.0)
	felt(ci, rounded(l, 6.0), 4, 5.0, 8.0)
	felt(ci, rounded(r, 6.0), 4, 5.0, 8.0)
	felt(ci, circle(Vector2(75, 92), 13.0, 20), 4, 4.0, 0.0)
	ci.draw_circle(Vector2(75, 92), 4.0, Palette.GOLD)

static func _heart(ci: CanvasItem, hanging: bool) -> void:
	cap_and_string(ci, Vector2(75, 52), hanging)
	var p := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		p.append(Vector2(75, 96) + Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * 3.0)
	felt(ci, rounded(p, 3.0), 0, 5.0, 9.0)

static func draw_lock(ci: CanvasItem, c: Vector2) -> void:
	var t := tex("tree_lock")
	if t:
		var h := 52.0
		var w := h * t.get_width() / t.get_height()
		ci.draw_texture_rect(t, Rect2(c - Vector2(w / 2.0, h * 0.62), Vector2(w, h)), false)

# ---------- ağaç ----------

const TIERS := [[0.03, 0.33, 0.25], [0.22, 0.55, 0.35], [0.41, 0.74, 0.44], [0.58, 0.89, 0.52]]

static func tier_poly(sz: Vector2, i: int) -> PackedVector2Array:
	var top: float = TIERS[i][0] * sz.y
	var bot: float = TIERS[i][1] * sz.y
	var hw: float = TIERS[i][2] * sz.x
	var cx := sz.x / 2.0
	var d := sz.y * 0.03
	var yc := bot - d * 0.25
	var p := PackedVector2Array()
	p.append(Vector2(cx, top))
	for k in range(1, 9):
		var t := k / 8.0
		p.append(Vector2(cx + hw * t * (1.0 + 0.07 * sin(PI * t)), lerpf(top, yc, t)))
	var n := 5 + i
	for s in n:
		for k in range(1, 7):
			var u := (s + k / 6.0) / n
			p.append(Vector2(cx + hw - 2.0 * hw * u, yc + d * 0.95 * sin(PI * k / 6.0)))
	for k in range(7, -1, -1):
		var t := k / 8.0
		p.append(Vector2(cx - hw * t * (1.0 + 0.07 * sin(PI * t)), lerpf(top, yc, t)))
	return rounded(p, 8.0)

static func max_hw(y: float) -> float:
	return 0.54 * y / 0.9 * 0.92

static func in_tree(n: Vector2) -> bool:
	if n.y < 0.1 or n.y > 0.9:
		return false
	return absf(n.x - 0.5) <= max_hw(n.y) + 0.02

class TreeView extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	func _draw() -> void:
		var t := Art.tex("tree")
		if t:
			var k := minf(size.x / t.get_size().x, size.y / t.get_size().y)
			var s := t.get_size() * k
			draw_texture_rect(t, Rect2(Vector2((size.x - s.x) / 2.0, size.y - s.y), s), false)
			return
		var cx := size.x / 2.0
		var w := size.x
		var h := size.y
		var mound := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 40.0
			mound.append(Vector2(cx + cos(a) * w * 0.6, h * 0.985 + sin(a) * h * 0.035))
		Art.felt(self, mound, 5, 4.0, 0.0, true)
		var trunk := PackedVector2Array([Vector2(cx - w * 0.045, h * 0.84), Vector2(cx + w * 0.045, h * 0.84), Vector2(cx + w * 0.045, h * 0.95), Vector2(cx - w * 0.045, h * 0.95)])
		Art.felt(self, trunk, 8, 4.0, 0.0, false)
		for i in range(3, -1, -1):
			Art.felt(self, Art.tier_poly(size, i), 6 if i % 2 == 0 else 2, 8.0, 14.0)
		var pot := PackedVector2Array([Vector2(cx - w * 0.14, h * 0.925), Vector2(cx + w * 0.14, h * 0.925), Vector2(cx + w * 0.115, h * 0.995), Vector2(cx - w * 0.115, h * 0.995)])
		Art.felt(self, Art.rounded(pot, 8.0), 0, 7.0, 12.0)
		Art.felt(self, Art.rounded(Ui.rrect(Rect2(cx - w * 0.16, h * 0.9, w * 0.32, h * 0.04), 10.0), 2.0), 0, 5.0, 7.0)

## Işık zinciri: çapraz sarkan tel + ampuller; sırayla yanar, nazikçe yanıp söner.
class Lights extends Control:
	signal stepped(i: int)
	var bulbs: Array[Vector2] = []
	var wire: Array[PackedVector2Array] = []
	var reveal := 0.0
	var running := false
	var t := 0.0
	## Elle çizilen zincirler: {pts: PackedVector2Array, carry: float, bulbs: Array[Vector2], t0: Array[float]}
	var strokes: Array = []
	const COLS := [0, 1, 2, 11]
	const GAP := 124.0
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	func build(sz: Vector2) -> void:
		bulbs.clear()
		wire.clear()
		var ys := [0.09, 0.21, 0.37, 0.53, 0.69, 0.84]
		var anc: Array[Vector2] = [Vector2(0.5, 0.09)]
		for i in range(1, ys.size()):
			var side := 1.0 if i % 2 == 1 else -1.0
			anc.append(Vector2(0.5 + side * Art.max_hw(ys[i]) * 0.85, ys[i]))
		var carry := 0.0
		for i in anc.size() - 1:
			var a := anc[i] * sz
			var b := anc[i + 1] * sz
			var c := (a + b) / 2.0 + Vector2(0, sz.y * 0.07)
			var pts := PackedVector2Array()
			for k in 41:
				var u := k / 40.0
				pts.append(a * (1 - u) * (1 - u) + c * 2.0 * u * (1 - u) + b * u * u)
			wire.append(pts)
			for k in range(1, pts.size()):
				carry += pts[k].distance_to(pts[k - 1])
				if carry >= 132.0:
					carry = 0.0
					bulbs.append(pts[k])
	func stroke_begin(p: Vector2) -> void:
		strokes.append({"pts": PackedVector2Array([p]), "carry": GAP * 0.5, "bulbs": [], "t0": []})
	## Yeni nokta ekler; yeni ampul dizildiyse konumunu döndürür, yoksa Vector2(-1,-1).
	func stroke_add(p: Vector2, instant := false) -> Vector2:
		var st: Dictionary = strokes[strokes.size() - 1]
		var pts: PackedVector2Array = st.pts
		var d := p.distance_to(pts[pts.size() - 1])
		if d < 5.0:
			return Vector2(-1, -1)
		pts.append(p)
		st.pts = pts
		st.carry += d
		if st.carry >= GAP:
			st.carry = 0.0
			st.bulbs.append(p)
			st.t0.append(-1.0 if instant else t)
			return p
		return Vector2(-1, -1)
	func last_stroke_empty() -> bool:
		if strokes.is_empty():
			return false
		return strokes[strokes.size() - 1].bulbs.is_empty()
	func stroke_end() -> void:
		if not strokes.is_empty() and strokes[strokes.size() - 1].pts.size() < 2:
			strokes.pop_back()
	func start(instant: bool) -> void:
		reveal = float(bulbs.size()) if instant else 0.0
		running = not instant
	func _process(dt: float) -> void:
		if not visible:
			return
		t += dt
		if running:
			var before := int(reveal)
			reveal += dt / 0.11
			if int(reveal) != before and int(reveal) <= bulbs.size():
				stepped.emit(int(reveal) - 1)
			if reveal >= bulbs.size():
				running = false
		queue_redraw()
	func _draw() -> void:
		for pts in wire:
			var sh := PackedVector2Array()
			for p in pts:
				sh.append(p + Vector2(1.5, 4))
			draw_polyline(sh, Color(Palette.SHADOW, 0.5), 9.0, true)
			Art.cord(self, pts, 12.0)
		var calm := Ui.reduce_motion()
		for st in strokes:
			var sp: PackedVector2Array = st.pts
			if sp.size() > 1:
				var sh2 := PackedVector2Array()
				for p in sp:
					sh2.append(p + Vector2(1.5, 4))
				draw_polyline(sh2, Color(Palette.SHADOW, 0.5), 9.0, true)
				Art.cord(self, sp, 12.0)
			for i in st.bulbs.size():
				var age: float = 99.0 if float(st.t0[i]) < 0.0 else t - float(st.t0[i])
				_bulb(st.bulbs[i], (i + int(st.bulbs[i].x)) % 4, clampf(age / 0.25, 0.0, 1.0), i + 3, calm)
		for i in bulbs.size():
			_bulb(bulbs[i], i % 4, clampf(reveal - i, 0.0, 1.0), i, calm)
	func _bulb(pos: Vector2, kind: int, on: float, i: int, calm: bool) -> void:
		var bt := Art.tex("tree_bulb_%d" % kind)
		if bt == null:
			return
		var b := 1.0 if calm else 0.78 + 0.22 * sin(t * 1.5 + i * 0.9)
		var h := 80.0
		var w := h * bt.get_width() / bt.get_height()
		var r := Rect2(pos + Vector2(-w / 2.0, -6), Vector2(w, h))
		# yanmamış: soluk, gri-lacivert; yanık: tam renk + katkı parlaması (aynı sprite)
		var dim := Color(0.32, 0.34, 0.42, 1.0).lerp(Color.WHITE, on)
		draw_texture_rect(bt, r, false, dim)
		if on > 0.0:
			var gr := r.grow(6.0 * on)
			gr.position.y += 4.0
			draw_texture_rect(bt, gr, false, Color(1, 1, 1, 0.22 * on * b))

class Orn extends Control:
	var kind := ""
	var hanging := true
	var locked := false
	var ghost := false
	var nx := 0.0
	var ny := 0.0
	func _init(k := "") -> void:
		kind = k
		size = Vector2(Art.BOX, Art.BOX)
		pivot_offset = Art.anchor(k)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	func _draw() -> void:
		if kind == "star_top" and hanging and not locked and not ghost:
			for i in 3:
				draw_circle(Art.anchor(kind), 92.0 - i * 18.0, Color(Palette.GOLD, 0.07 + i * 0.03))
		Art.draw_orn(self, kind, hanging)
		if locked:
			draw_circle(Vector2(75, 90), 62.0, Color(Palette.DIM, 0.45))
			Art.draw_lock(self, Vector2(75, 92))
		if ghost:
			draw_circle(Vector2(75, 90), 62.0, Color(Palette.TRAY, 0.6))

class PriceTag extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		Art.nine(self, "tree_pricetag", Rect2(Vector2.ZERO, size), Vector4(70, 60, 70, 60), 0.4)

class Spark extends Control:
	var items: Array = []
	var life := 0.0
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func burst(at: Vector2, n := 16) -> void:
		for i in n:
			items.append({"p": at, "v": Vector2.from_angle(randf() * TAU) * randf_range(120.0, 360.0),
				"r": randf_range(8.0, 18.0), "ph": randf() * TAU})
	func _process(dt: float) -> void:
		life += dt
		for it in items:
			it.p += it.v * dt
			it.v *= 0.94
		queue_redraw()
		if life > 1.5:
			queue_free()
	func _draw() -> void:
		var a := clampf(1.0 - life / 1.5, 0.0, 1.0)
		var t := Art.tex("tree_spark")
		if t == null:
			return
		for it in items:
			var r: float = it.r * (0.6 + 0.4 * sin(life * 8.0 + it.ph)) * 1.6
			draw_set_transform(it.p, life * 2.0 + it.ph, Vector2.ONE)
			draw_texture_rect(t, Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

class Bubble extends Control:
	func setup(text: String) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		var l := Ui.label(text, 34, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		add_child(l)
		var f := l.get_theme_font("font")
		var ms := l.get_minimum_size()
		if f:
			var ts := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
			ms = Vector2(maxf(ms.x, ts.x + 8.0), maxf(ms.y, ts.y))
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		size = ms + Vector2(64, 36)
		l.position = Vector2(32, 18)
		l.size = ms
		pivot_offset = Vector2(size.x / 2.0, size.y)
	func _draw() -> void:
		var tt := Art.tex("tree_bubble_tail")
		var tl := 0.0
		if tt:
			tl = tt.get_height() * 0.4
		Art.nine(self, "tree_bubble", Rect2(Vector2.ZERO, size), Vector4(90, 90, 90, 90), 0.3)
		if tt:
			var tw := tt.get_width() * 0.4
			draw_texture_rect(tt, Rect2(Vector2((size.x - tw) / 2.0, size.y - tl + 10.0), Vector2(tw, tl)), false)

