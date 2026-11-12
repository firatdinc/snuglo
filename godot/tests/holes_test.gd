extends SceneTree
## Kaç parçada delik (içinde başka parça) var? Çizim bunu desteklemiyor.
func _init() -> void:
	var holes := 0
	var total := 0
	var packs := {"cozy-beginnings": 5, "spice-route": 6, "mambo-nights": 7, "woodland-retreat": 8}
	for pk: String in packs:
		for i in range(1, 61):
			var l := LevelGenerator.generate(pk, i, packs[pk])
			for p in l.pieces:
				total += 1
				var cs := 10.0
				var poly := PackedVector2Array()
				var acc: Array = []
				for c in p.cells:
					acc.append(PackedVector2Array([Vector2(c)*cs, Vector2(c.x+1,c.y)*cs, Vector2(c.x+1,c.y+1)*cs, Vector2(c.x,c.y+1)*cs]))
				var u: PackedVector2Array = acc[0]
				var hole := false
				for c in PieceShape._bfs(p.cells).slice(1):
					var q := PackedVector2Array([Vector2(c)*cs, Vector2(c.x+1,c.y)*cs, Vector2(c.x+1,c.y+1)*cs, Vector2(c.x,c.y+1)*cs])
					for m in Geometry2D.merge_polygons(u, q):
						if Geometry2D.is_polygon_clockwise(m): hole = true
						else: u = m
				if hole:
					holes += 1
					print(l.id, " ", p.id)
	print("delikli: %d / %d" % [holes, total])
	quit()
