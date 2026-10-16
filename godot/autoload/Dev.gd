extends Node
## Geliştirme kancaları: otomatik oynatma ve ekran görüntüsü (ortam değişkenleri).

func attach(g: Game) -> void:
	var auto := OS.get_environment("SNUG_AUTO")
	if auto != "":
		_autoplay(g, int(auto))
	var dr := OS.get_environment("SNUG_DRAG")
	if dr != "":
		drag_test(g, dr == "drop")
	var shot := OS.get_environment("SNUG_SHOT")
	if shot != "":
		var t := float(shot.get_slice(":", 0))
		var path := shot.get_slice(":", 1)
		await get_tree().create_timer(t, true, false, true).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path)
		get_tree().quit()

func _autoplay(g: Game, n: int) -> void:
	await get_tree().create_timer(1.0).timeout
	var k := 0
	for p in g.lvl.pieces:
		if k >= n:
			break
		g._place(g.pieces[p.id], g.lvl.solution[p.id], true)
		k += 1
		await get_tree().create_timer(0.35).timeout

## SNUG_DRAG=1: ilk parçayı gerçek dokunma olaylarıyla çözüm yerine sürükler (bırakmadan durur).
func drag_test(g: Game, release: bool) -> void:
	await get_tree().create_timer(1.2).timeout
	var p: PieceData = g.lvl.pieces[0]
	var v: PieceView = g.pieces[p.id]
	var start := v.position + (Vector2(p.cells[0]) - Vector2(p.size) / 2.0 + Vector2(0.5, 0.5)) * v.cs * v.tray_scale
	var o: Vector2i = g.lvl.solution[p.id]
	var dest := g.board.position + (Vector2(o) + Vector2(p.size) / 2.0) * g.cs + Vector2(0, Game.LIFT * g.cs) + Vector2(14, 10)
	_touch(start, true)
	for i in 30:
		await get_tree().process_frame
		var d := InputEventScreenDrag.new()
		d.position = get_viewport().get_final_transform() * start.lerp(dest, ease(i / 29.0, 0.5))
		Input.parse_input_event(d)
	if release:
		await get_tree().create_timer(0.3).timeout
		_touch(dest, false)

func _touch(at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = get_viewport().get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)
