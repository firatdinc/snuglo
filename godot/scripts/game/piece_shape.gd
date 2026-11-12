class_name PieceShape
extends RefCounted
## Polyomino hücrelerinden yumuşak köşeli "yastık" poligonları üretir.
## Birleşim → içe çek (MITER) → dışa yuvarla (ROUND) → kapat (iç köşe fileto).

static var _cache := {}

## Dönen: {"outer": PackedVector2Array, "inner": PackedVector2Array, "stitch": PackedVector2Array}
static func build(cells: Array[Vector2i], cs: float) -> Dictionary:
	var key := "%s|%d" % [str(cells), int(cs)]
	if _cache.has(key):
		return _cache[key]
	var base := PackedVector2Array()
	for c in _bfs(cells):
		var q := PackedVector2Array([Vector2(c) * cs, Vector2(c.x + 1, c.y) * cs, Vector2(c.x + 1, c.y + 1) * cs, Vector2(c.x, c.y + 1) * cs])
		if base.is_empty():
			base = q
			continue
		# BFS sırası: her yeni kare mevcut birleşime komşu → tek dış çevre.
		for m: PackedVector2Array in Geometry2D.merge_polygons(base, q):
			if not Geometry2D.is_polygon_clockwise(m):
				base = m
	var gap := cs * 0.045
	var r := cs * 0.2
	var outer := _off(base, -(gap + r), Geometry2D.JOIN_MITER)
	outer = _off(outer, r, Geometry2D.JOIN_ROUND)
	var f := cs * 0.08
	outer = _off(_off(outer, f, Geometry2D.JOIN_ROUND), -f, Geometry2D.JOIN_ROUND)
	var res := {
		"outer": outer,
		"inner": _off(outer, -cs * 0.13, Geometry2D.JOIN_ROUND),
		"stitch": _off(outer, -cs * 0.075, Geometry2D.JOIN_ROUND),
		"hi": _off(outer, -cs * 0.25, Geometry2D.JOIN_ROUND),
	}
	_cache[key] = res
	return res

static func _bfs(cells: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = [cells[0]]
	var i := 0
	while i < out.size():
		for d in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var n: Vector2i = out[i] + d
			if cells.has(n) and not out.has(n):
				out.append(n)
		i += 1
	return out

static func _off(p: PackedVector2Array, d: float, join: int) -> PackedVector2Array:
	if p.is_empty():
		return p
	var r := Geometry2D.offset_polygon(p, d, join)
	var best := PackedVector2Array()
	for x: PackedVector2Array in r:
		if not Geometry2D.is_polygon_clockwise(x) and x.size() > best.size():
			best = x
	return best

## Çevre boyunca kesikli dikiş segmentleri.
static func dashes(poly: PackedVector2Array, dash: float, gap: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if poly.size() < 2:
		return out
	var pts := poly.duplicate()
	pts.append(poly[0])
	var on := true
	var left := dash
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		var t := 0.0
		while t < seg:
			var step := minf(left, seg - t)
			if on:
				out.append(a.lerp(b, t / seg))
				out.append(a.lerp(b, (t + step) / seg))
			t += step
			left -= step
			if left <= 0.0001:
				on = not on
				left = dash if on else gap
	return out
