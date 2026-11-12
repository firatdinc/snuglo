class_name SolutionChecker
extends RefCounted
## Yerleşimleri doğrular. Board her yerleşimde zaten çakışmayı engellediği için
## burada yalnız tam kaplama + sınır kontrolü yapılır.

static func is_solved(lvl: LevelData, placements: Dictionary) -> bool:
	if placements.size() != lvl.pieces.size():
		return false
	var seen := {}
	for pid: String in placements:
		var p := lvl.piece(pid)
		if p == null:
			return false
		var o: Vector2i = placements[pid]
		for c in p.cells:
			var a := c + o
			if a.x < 0 or a.y < 0 or a.x >= lvl.width or a.y >= lvl.height or seen.has(a):
				return false
			seen[a] = true
	return seen.size() == lvl.width * lvl.height
