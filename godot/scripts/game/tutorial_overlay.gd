extends Control
## İlk bölüm öğreticisi: keçe el, ilk parçayı tepsiden çözüm yerine sürükler (döngü) +
## "Bir parçayı tahtaya sürükle" balonu. Oyuncu bir parça tutunca dismiss().

var _hand: Hand
var _bubble: Control
var _tw: Tween
var _from := Vector2.ZERO
var _to := Vector2.ZERO

func setup(g: Game) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Ui.vp()
	var p: PieceData = g.lvl.pieces[0]
	var v: PieceView = g.pieces[p.id]
	# El, parçanın ilk hücresinden tutar; hedef: aynı hücrenin çözümdeki yeri (+ parmak kaldırma payı).
	var cell := Vector2(p.cells[0]) + Vector2(0.5, 0.5)
	_from = v.home + (cell - Vector2(p.size) / 2.0) * g.cs * v.tray_scale
	var o: Vector2i = g.lvl.solution[p.id]
	_to = g.board.position + (Vector2(o) + cell) * g.cs + Vector2(0, Game.LIFT * g.cs)
	_bubble = QuiltCard.new()
	(_bubble as QuiltCard).fill = Palette.MUSTARD
	(_bubble as QuiltCard).radius = 44
	var text := tr("coach.drag")
	var w := minf(Ui.col_w() - 120, Ui.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x + 90)
	_bubble.size = Vector2(w, 96)
	_bubble.position = Vector2((size.x - w) / 2.0, g.tray_rect.position.y - 70)
	add_child(_bubble)
	var l := Ui.title(text, 40)
	Ui.place(l, Vector2.ZERO, _bubble.size)
	_bubble.add_child(l)
	Ui.pop_in(_bubble, 0.8, 0.4)
	Ui.bob(_bubble, 6.0, 1.8)
	_hand = Hand.new()
	_hand.size = Vector2(150, 190)
	var tex := UiArt.tex("ic_hand")
	if tex:
		_hand.use_art = true
		var tr_ := Ui.tex_rect(tex, Vector2(170, 193))
		tr_.position = Vector2(-20, -10)
		_hand.add_child(tr_)
	add_child(_hand)
	_hand.modulate.a = 0.0
	get_tree().create_timer(1.0).timeout.connect(_loop)

func _loop() -> void:
	if not is_instance_valid(_hand):
		return
	_hand.position = _from
	_hand.scale = Vector2(1.2, 1.2)
	_tw = create_tween()
	_tw.tween_property(_hand, "modulate:a", 1.0, 0.25)
	_tw.parallel().tween_property(_hand, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.tween_property(_hand, "scale", Vector2(0.86, 0.86), 0.15)
	_tw.tween_property(_hand, "position", _to, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tw.tween_property(_hand, "scale", Vector2.ONE, 0.15)
	_tw.tween_property(_hand, "modulate:a", 0.0, 0.3)
	_tw.tween_interval(0.5)
	_tw.tween_callback(_loop)

func dismiss() -> void:
	if _tw:
		_tw.kill()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)

## Keçe işaret eli: parmak ucu düğüm orijininde.
class Hand extends Control:
	var use_art := false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if use_art:
			return
		var finger := Rect2(Vector2(-18, -6), Vector2(40, 92))
		var palm := Rect2(Vector2(-24, 62), Vector2(104, 100))
		var cuff := Rect2(Vector2(-18, 150), Vector2(92, 40))
		draw_set_transform(Vector2(6, 8), 0.0, Vector2.ONE)
		for r: Rect2 in [finger, palm, cuff]:
			draw_colored_polygon(Ui.rrect(r, 20), Palette.SHADOW)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_colored_polygon(Ui.rrect(cuff, 14), Palette.TERRACOTTA)
		draw_colored_polygon(Ui.rrect(palm, 36), Palette.CREAM)
		draw_colored_polygon(Ui.rrect(finger, 20), Palette.CREAM)
		# kıvrık parmak boğumları
		for i in 3:
			draw_colored_polygon(Ui.rrect(Rect2(Vector2(22 + i * 18, 52 + i * 4), Vector2(24, 40)), 12), Palette.CARD)
		draw_polyline(Ui.rrect(palm, 36) + PackedVector2Array([Ui.rrect(palm, 36)[0]]), Color(Palette.INK, 0.5), 3.0, true)
		draw_polyline(Ui.rrect(finger, 20) + PackedVector2Array([Ui.rrect(finger, 20)[0]]), Color(Palette.INK, 0.5), 3.0, true)
		draw_multiline(PieceShape.dashes(Ui.rrect(palm.grow(-10), 28), 8, 6), Color(Palette.STITCH_DARK, 0.6), 2.0)
		draw_multiline(PieceShape.dashes(Ui.rrect(cuff.grow(-7), 9), 8, 6), Color(Palette.STITCH, 0.8), 2.0)
		draw_circle(Vector2(2, 2), 9, Color(Palette.TERRACOTTA, 0.35))
