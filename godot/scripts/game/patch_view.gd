class_name PatchView
extends Control
## Tek yorgan yaması: Quilt kaydından çözülmüş tahtayı minyatür yastık parçalarla çizer.
## Kenar: 3★ altın dikiş, sezon/günlük/kule kendi renginde, yoksa krem.

signal tapped

var patch: Dictionary = {}
var show_trim := true
var stitch_in := 1.0        ## 0..1 dikiş animasyonu (yorgana yeni dikilen yama)
var _pieces: Array = []
var _press := false

func set_patch(p: Dictionary) -> void:
	patch = p
	_pieces = Quilt.decode(p)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)

func trim_color() -> Color:
	match Quilt.trim_of(patch):
		"gold":
			return Palette.GOLD
		"season":
			return Color("9cc3d9")
		"daily":
			return Palette.TERRACOTTA
		"tower":
			return Palette.SAGE
	return Palette.STITCH

## Kenar dikişinin köşe yolu (kapalı, 5 nokta) — PatchView ve dikiş sahnesi aynı yolu kullanır.
static func trim_path(side: float) -> PackedVector2Array:
	var e := side * 0.035
	return PackedVector2Array([Vector2(e, e), Vector2(side - e, e), Vector2(side - e, side - e),
		Vector2(e, side - e), Vector2(e, e)])

func _fab_tex(idx: int, set_id: String) -> Texture2D:
	return Fabrics.get_tex(idx, set_id)

## Birim kare çokgenini dokuyla çiz; doku bölgesi yama boyuna bağlı (küçükte de desen görünsün).
func _fab_poly(poly: PackedVector2Array, idx: int, set_id: String, inner: Rect2, shade := 0.0) -> void:
	var tex := _fab_tex(idx, set_id)
	var pts := PackedVector2Array()
	for q in poly:
		pts.append(inner.position + q * inner.size.x)
	if tex == null:
		draw_colored_polygon(pts, Palette.piece(idx).darkened(shade))
		return
	var uv := PackedVector2Array()
	var off := Vector2(0.18 + fposmod(idx * 0.137, 0.2), 0.18 + fposmod(idx * 0.211, 0.2))
	for q in pts:
		uv.append((q - inner.position) / (inner.size.x * 1.7) + off)
	draw_colored_polygon(pts, Color(1, 1, 1).darkened(shade), uv, tex)

func _draw_shaped(side: float) -> void:
	var pt := String(patch.get("pt", ""))
	var set_id := String(patch.get("cs", ""))
	var a := int(patch.get("ci", 0))
	var b := int(patch.get("ai", a + 3))
	var pad := 0.0
	var inner := Rect2(Vector2(pad, pad), Vector2(side - pad * 2.0, side - pad * 2.0))
	var dash := maxf(3.0, side * 0.04)
	for sh: Dictionary in PatchShapes.shapes(pt):
		var idx := b if int(sh.who) == 1 else a
		var poly: PackedVector2Array = sh.poly
		if sh.get("appl", false):
			# Aplike: altına yumuşak gölge.
			var sp := PackedVector2Array()
			for q in poly:
				sp.append(inner.position + q * inner.size.x + Vector2(0, side * 0.018))
			draw_colored_polygon(sp, Palette.SHADOW)
		_fab_poly(poly, idx, set_id, inner)
		if int(sh.who) == 1 or sh.get("appl", false):
			var px := PackedVector2Array()
			for q in poly:
				px.append(inner.position + q * inner.size.x)
			if sh.get("appl", false):
				var off := Geometry2D.offset_polygon(px, -side * 0.025, Geometry2D.JOIN_ROUND)
				if not off.is_empty():
					px = off[0]
			var d := PieceShape.dashes(px, dash, dash * 0.7)
			if d.size() > 1:
				draw_multiline(d, Color(Palette.STITCH, 0.85), maxf(1.0, side * 0.014))

func _draw() -> void:
	if patch.is_empty():
		return
	var w := maxi(1, int(patch.get("w", 1)))
	var side := minf(size.x, size.y)
	var chosen := patch.has("ci")
	var shaped := PatchShapes.is_shaped(String(patch.get("pt", "")))
	var pad := side * (0.1 if chosen and not shaped else 0.045)
	var cs := (side - pad * 2.0) / float(w)
	var fset := String(patch.get("f", ""))
	# Zemin: patiska kare + yumuşak gölge.
	var r := Rect2(Vector2.ZERO, Vector2(side, side))
	draw_rect(Rect2(r.position + Vector2(0, side * 0.03), r.size), Palette.SHADOW)
	draw_rect(r, Palette.CARD)
	if shaped:
		_draw_shaped(side)
		_draw_trim(side)
		return
	if chosen:
		# Seçilen kumaş çerçeve olur; tahta içine yamalı.
		_fab_poly(PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), int(patch.ci),
			String(patch.get("cs", "")), Rect2(Vector2.ZERO, Vector2(side, side)))
		draw_rect(Rect2(Vector2(pad, pad), Vector2(side - pad * 2.0, side - pad * 2.0)).grow(side * 0.012), Palette.SHADOW)
		draw_rect(Rect2(Vector2(pad, pad), Vector2(side - pad * 2.0, side - pad * 2.0)), Palette.CARD)
	draw_set_transform(Vector2(pad, pad), 0.0, Vector2.ONE)
	for pc: Dictionary in _pieces:
		var cells: Array[Vector2i] = []
		cells.assign(pc.cells)
		if cells.is_empty():
			continue
		var sh := PieceShape.build(cells, cs)
		var ci := int(pc.color)
		var tex := Fabrics.get_tex(ci, fset)
		draw_colored_polygon(sh.outer, Palette.piece(ci).darkened(0.25))
		if tex:
			draw_colored_polygon(sh.outer, Color.WHITE, Fabrics.uvs(sh.outer, tex, ci), tex)
		else:
			draw_colored_polygon(sh.outer, Palette.piece(ci))
		if cs >= 10.0:
			var d := PieceShape.dashes(sh.stitch, cs * 0.12, cs * 0.08)
			if d.size() > 1:
				draw_multiline(d, Color(Palette.STITCH, 0.8), maxf(1.0, cs * 0.04))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_trim(side)

## Kenar dikişinin çevre boyunca [from_len, to_len] aralığındaki kesikli parçaları.
static func trim_segments(side: float, from_len: float, to_len: float) -> PackedVector2Array:
	var path := trim_path(side)
	var dash := maxf(3.0, side * 0.05)
	var gap := dash * 0.7
	var segs := PackedVector2Array()
	var walked := 0.0
	for i in 4:
		var a := path[i]
		var b := path[i + 1]
		var L := a.distance_to(b)
		var t := 0.0
		while t < L and walked + t < to_len:
			var t2 := minf(t + dash, L)
			var s0 := maxf(t, from_len - walked)
			var s1 := minf(t2, to_len - walked)
			if s1 > s0:
				segs.append(a.lerp(b, s0 / L))
				segs.append(a.lerp(b, s1 / L))
			t += dash + gap
		walked += L
	return segs

static func trim_total(side: float) -> float:
	return (side - 2.0 * side * 0.035) * 4.0

func _draw_trim(side: float) -> void:
	if not show_trim:
		return
	# Kenar dikişi: stitch_in ile çevre boyunca ilerleyen kesikli iplik.
	var segs := trim_segments(side, 0.0, trim_total(side) * clampf(stitch_in, 0.0, 1.0))
	if segs.size() > 1:
		var wd := maxf(1.5, side * 0.022)
		if side > 200.0:
			var sh := PackedVector2Array()
			for q in segs:
				sh.append(q + Vector2(1.5, 3.0))
			draw_multiline(sh, Color(Palette.SHADOW, 0.45), wd)
		draw_multiline(segs, trim_color(), wd)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		if e.pressed:
			_press = true
		elif _press:
			_press = false
			tapped.emit()
