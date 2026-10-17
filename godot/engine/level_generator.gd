class_name LevelGenerator
extends RefCounted
## Swift `LevelGenerator` portu — seeded Voronoi BFS ile grid'i polyomino'lara böler.
## Aynı (pack_id, level_index, grid_size, seed_base) → Swift ile özdeş Level.

const DEFAULT_SEED_BASE := 6002829118042747185  # 0x534E55474C4F3131 "SNUGLO11"

static func generate(pack_id: String, level_index: int, grid_size: int, seed_base: int = DEFAULT_SEED_BASE) -> LevelData:
	var seed := seed_base ^ SeededRandom.fnv1a(pack_id) ^ (level_index * 1099511628211)
	var rng := SeededRandom.new(seed)
	var count := piece_count(grid_size, level_index)
	var regions := _partition(grid_size, count, rng)

	var lvl := LevelData.new()
	lvl.id = "%s-%d" % [pack_id, level_index]
	lvl.width = grid_size
	lvl.height = grid_size
	for i in regions.size():
		var region: Array = regions[i]
		if region.is_empty():
			continue
		var min_x := 1 << 30
		var min_y := 1 << 30
		for c: Vector2i in region:
			min_x = mini(min_x, c.x)
			min_y = mini(min_y, c.y)
		var cells: Array[Vector2i] = []
		for c: Vector2i in region:
			cells.append(Vector2i(c.x - min_x, c.y - min_y))
		cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
		var pid := "%s-%d-p%d" % [pack_id, level_index, i]
		lvl.pieces.append(PieceData.make(pid, cells, lvl.pieces.size()))
		lvl.solution[pid] = Vector2i(min_x, min_y)
	return lvl

## Her 10. bölüm (10/20/…/60) +1 parça: o bölümlerde Nook parçası kazanılır (canlı 1.2.0 kuralı).
static func piece_count(grid_size: int, level_index: int) -> int:
	var bump := 1 if level_index > 0 and level_index % 10 == 0 else 0
	match grid_size:
		5: return (4 if level_index <= 20 else 5) + bump
		6: return (5 if level_index <= 20 else (6 if level_index <= 40 else 7)) + bump
		7: return (6 if level_index <= 20 else (7 if level_index <= 40 else 8)) + bump
		8: return (8 if level_index <= 20 else (10 if level_index <= 40 else 12)) + bump
	return maxi(3, grid_size * grid_size / 6) + bump

static func _partition(size: int, count: int, rng: SeededRandom) -> Array:
	var total := size * size
	var n := maxi(1, mini(count, total))
	var claims := PackedInt32Array()
	claims.resize(total)
	claims.fill(-1)

	var indices := range(total)
	rng.shuffle(indices)
	var seeds := indices.slice(0, n)
	for p in n:
		claims[seeds[p]] = p

	var cands: Array = []
	for p in n:
		var list: Array = []
		for nb in _neighbors(seeds[p], size):
			if claims[nb] == -1:
				list.append(nb)
		cands.append(list)

	var remaining := total - n
	while remaining > 0:
		var grew := false
		var order := range(n)
		rng.shuffle(order)
		for p: int in order:
			cands[p] = cands[p].filter(func(c: int) -> bool: return claims[c] == -1)
			var list: Array = cands[p]
			if list.is_empty():
				continue
			var pick := SeededRandom.urem(rng.next(), list.size())
			var cell: int = list[pick]
			if claims[cell] != -1:
				list.remove_at(pick)
				continue
			claims[cell] = p
			remaining -= 1
			grew = true
			for nb in _neighbors(cell, size):
				if claims[nb] == -1:
					list.append(nb)
		if not grew:
			for i in total:
				if claims[i] != -1:
					continue
				for nb in _neighbors(i, size):
					if claims[nb] >= 0:
						claims[i] = claims[nb]
						remaining -= 1
						break

	var regions: Array = []
	for p in n:
		regions.append([])
	for i in total:
		regions[maxi(0, claims[i])].append(Vector2i(i % size, i / size))
	return regions

static func _neighbors(i: int, size: int) -> Array:
	var x := i % size
	var y := i / size
	var r: Array = []
	if x > 0: r.append(y * size + x - 1)
	if x < size - 1: r.append(y * size + x + 1)
	if y > 0: r.append((y - 1) * size + x)
	if y < size - 1: r.append((y + 1) * size + x)
	return r
