extends SceneTree
## Godot motoru Swift SnugloEngine ile birebir aynı level'ları üretiyor mu?
## godot --headless --path godot -s tests/parity_test.gd

func _init() -> void:
	var ref: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/parity/swift_levels.json"))
	var fails := 0
	for e: Dictionary in ref:
		var lvl: LevelData
		if e.has("date"):
			var d: PackedStringArray = (e.date as String).split("-")
			var idx := int((e.id as String).get_slice("-", 1))
			lvl = DailyPuzzle.for_date(int(d[0]), int(d[1]), int(d[2]), idx)
		else:
			var id: String = e.id
			var cut := id.rfind("-")
			lvl = LevelGenerator.generate(id.left(cut), int(id.substr(cut + 1)), int(e.w))
		if _enc(lvl) != _ref(e):
			fails += 1
			if fails <= 3:
				print("FARK ", e.get("date", ""), " ", e.id, "\n  swift: ", _ref(e), "\n  godot: ", _enc(lvl))
	print("parity: %d/%d eşleşti" % [ref.size() - fails, ref.size()])
	quit(1 if fails else 0)

func _enc(l: LevelData) -> String:
	var s := "%s %dx%d" % [l.id, l.width, l.height]
	for p in l.pieces:
		s += " | %s @%s:" % [p.id, l.solution[p.id]]
		for c in p.cells:
			s += " %d,%d" % [c.x, c.y]
	return s

func _ref(e: Dictionary) -> String:
	var s := "%s %dx%d" % [e.id, e.w, e.h]
	var sol := {}
	for x: Dictionary in e.solution:
		sol[x.id] = Vector2i(x.o[0], x.o[1])
	for p: Dictionary in e.pieces:
		s += " | %s @%s:" % [p.id, sol[p.id]]
		for c: Array in p.cells:
			s += " %d,%d" % [c[0], c[1]]
	return s
