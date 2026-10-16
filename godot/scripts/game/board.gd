class_name Board
extends Node2D
## Tahta: çerçeve + hücre yuvaları + yerleşim hayaleti + hücre dalgası.
## Doluluk durumu burada tutulur (cell → pid). Orijin = grid'in sol-üst köşesi.

var lvl: LevelData
var cs := 100.0
var occ := {}                      # Vector2i → pid
var ghost_piece: PieceData
var ghost_origin := Vector2i(-99, -99)
var _ghost_t := 0.0
var _bump := {}                    # Vector2i → [offset, vel] (yuva zıplaması)
var _wave := {}                    # Vector2i → parlama 0..1 (çözüm dalgası)
var _clock := 0.0

func setup(level: LevelData, cell_size: float) -> void:
	lvl = level
	cs = cell_size
	occ.clear()
	queue_redraw()

func grid_px() -> Vector2:
	return Vector2(lvl.width, lvl.height) * cs

func cell_center(c: Vector2i) -> Vector2:
	return position + (Vector2(c) + Vector2(0.5, 0.5)) * cs

func fits(p: PieceData, o: Vector2i, ignore := "") -> bool:
	for c in p.cells:
		var a := c + o
		if a.x < 0 or a.y < 0 or a.x >= lvl.width or a.y >= lvl.height:
			return false
		if occ.has(a) and occ[a] != ignore:
			return false
	return true

func place(p: PieceData, o: Vector2i) -> void:
	for c in p.cells:
		occ[c + o] = p.id

func remove(pid: String) -> void:
	for k in occ.keys():
		if occ[k] == pid:
			occ.erase(k)
	queue_redraw()

func filled_ratio() -> float:
	return float(occ.size()) / float(lvl.width * lvl.height)

func set_ghost(p: PieceData, o: Vector2i) -> void:
	if p != ghost_piece or o != ghost_origin:
		_ghost_t = 0.0
	ghost_piece = p
	ghost_origin = o
	queue_redraw()

func clear_ghost() -> void:
	ghost_piece = null
	ghost_origin = Vector2i(-99, -99)
	queue_redraw()

## Merkezden dışa yayılan yuva zıplaması (yerleşim darbesi).
func ripple(center: Vector2, strength := 1.0) -> void:
	for y in lvl.height:
		for x in lvl.width:
			var c := Vector2i(x, y)
			var d := (Vector2(c) + Vector2(0.5, 0.5)).distance_to(center)
			if d > 3.5:
				continue
			var v: float = -strength * cs * 1.4 * (1.0 - d / 3.5)
			var b: Array = _bump.get(c, [0.0, 0.0])
			b[1] += v
			_bump[c] = b

func wave(c: Vector2i, amount := 1.0) -> void:
	_wave[c] = amount

func _process(dt: float) -> void:
	_clock += dt
	_ghost_t += dt
	var dirty := ghost_piece != null
	for c in _bump.keys():
		var b: Array = _bump[c]
		b[1] += -b[0] * 420.0 * dt - b[1] * 13.0 * dt
		b[0] += b[1] * dt
		if absf(b[0]) < 0.05 and absf(b[1]) < 0.5:
			_bump.erase(c)
		dirty = true
	for c in _wave.keys():
		_wave[c] -= dt * 1.4
		if _wave[c] <= 0.0:
			_wave.erase(c)
		dirty = true
	if dirty:
		queue_redraw()

func _draw() -> void:
	if lvl == null:
		return
	var g := grid_px()
	var pad := cs * 0.32
	var frame := Rect2(-Vector2(pad, pad), g + Vector2(pad, pad) * 2)
	# Çerçeve: alt kalınlık + yüz + iç gölge. (Sonra ChatGPT ahşap kasnak dokusu gelecek.)
	_rrect(frame.grow(4).grow_individual(0, 0, 0, cs * 0.12), Palette.SHADOW, pad)
	_rrect(frame.grow_individual(0, 0, 0, cs * 0.1), Palette.BOARD_EDGE, pad)
	_rrect(frame, Palette.BOARD, pad)
	_rrect(Rect2(Vector2(-cs * 0.06, -cs * 0.06), g + Vector2(cs, cs) * 0.12), Palette.SLOT_SHADE, cs * 0.22)
	for y in lvl.height:
		for x in lvl.width:
			var c := Vector2i(x, y)
			if occ.has(c):
				continue
			var b: float = _bump.get(c, [0.0, 0.0])[0]
			var r := Rect2(Vector2(c) * cs, Vector2(cs, cs)).grow(-cs * 0.06)
			r.position.y += b
			_rrect(r.grow_individual(0, 0, 0, cs * 0.04), Palette.SLOT_SHADE.darkened(0.06), cs * 0.16)
			_rrect(r, Palette.SLOT, cs * 0.16)
			var w: float = _wave.get(c, 0.0)
			if w > 0.0:
				_rrect(r, Color(Palette.CREAM, w), cs * 0.16)
	if ghost_piece != null:
		var sh := PieceShape.build(ghost_piece.cells, cs)
		var col := Palette.piece(ghost_piece.color_index)
		var pulse := 0.5 + 0.5 * sin(_clock * 7.0)
		var pop := minf(_ghost_t / 0.12, 1.0)
		var o := Vector2(ghost_origin) * cs
		var ctr := o + Vector2(ghost_piece.size) * cs * 0.5
		var s := lerpf(0.9, 1.0, ease(pop, 0.4))
		draw_set_transform(ctr - (Vector2(ghost_piece.size) * cs * 0.5) * s, 0.0, Vector2(s, s))
		draw_colored_polygon(sh.outer, Color(col, 0.5 + 0.15 * pulse))
		var d := PieceShape.dashes(sh.stitch, cs * 0.09, cs * 0.06)
		if d.size() > 1:
			draw_multiline(d, Color(col.darkened(0.2), 0.75), maxf(2.0, cs * 0.03))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _rrect(r: Rect2, c: Color, rad: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	draw_style_box(sb, r)
