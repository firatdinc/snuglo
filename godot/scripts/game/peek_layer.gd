class_name PeekLayer
extends Node2D
## "Göz at" güçlendirmesi: yerinde olmayan parçaların çözümdeki silüetleri — kumaş renginde yarı
## saydam yama + dikiş. Orijin = grid'in sol-üst köşesi. Game.peek() açar/söndürür.

var _items: Array = []   # [shape, color, center]
var _clock := 0.0
var _cs := 100.0

func setup(lvl: LevelData, placements: Dictionary, cs: float) -> void:
	_cs = cs
	for p: PieceData in lvl.pieces:
		var o: Vector2i = lvl.solution[p.id]
		if placements.get(p.id, Vector2i(-99, -99)) == o:
			continue
		_items.append({"sh": PieceShape.build(p.cells, cs), "col": Palette.piece(p.color_index),
			"at": Vector2(o) * cs, "n": _items.size()})

func _process(dt: float) -> void:
	_clock += dt
	queue_redraw()

func _draw() -> void:
	for it in _items:
		# Sırayla belir: her parça 60 ms arayla, hafif nabız.
		var t := clampf((_clock - it.n * 0.06) / 0.2, 0.0, 1.0)
		if t <= 0.0:
			continue
		var pulse := 0.5 + 0.5 * sin(_clock * 5.0 + it.n)
		var col: Color = it.col
		draw_set_transform(it.at)
		draw_colored_polygon(it.sh.outer, Color(col, (0.42 + 0.1 * pulse) * t))
		var d := PieceShape.dashes(it.sh.stitch, _cs * 0.09, _cs * 0.06)
		if d.size() > 1:
			draw_multiline(d, Color(Palette.CREAM, 0.85 * t), maxf(2.0, _cs * 0.035))
	draw_set_transform(Vector2.ZERO)
