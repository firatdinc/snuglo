class_name PieceData
extends RefCounted
## Polyomino: origin-relatif hücreler. `color_index` palet/kumaş seçimi için.

var id := ""
var cells: Array[Vector2i] = []
var size := Vector2i.ZERO
var color_index := 0

static func make(pid: String, c: Array[Vector2i], color: int) -> PieceData:
	var p := PieceData.new()
	p.id = pid
	p.cells = c
	p.color_index = color
	for v in c:
		p.size = Vector2i(maxi(p.size.x, v.x + 1), maxi(p.size.y, v.y + 1))
	return p

func has_cell(v: Vector2i) -> bool:
	return cells.has(v)
