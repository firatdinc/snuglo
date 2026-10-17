class_name Game
extends Node2D
## Tek bölüm oturumu: tahta, tepsi, sürükle-bırak, ipucu/geri al, çözüm sekansı.

## Çözüm algılandı (kutlama başlıyor; done=true). Kayıt burada yapılmalı.
signal solve_started
## Kutlama sekansı bitti (sonuç kartı zamanı).
signal solved(stars: int, seconds: float)
## Parça yerleşti (by_player: oyuncu sürükledi; fresh: bu parça bu denemede ilk kez yerleşti —
## tahtadaki parçayı oynatmak kombo/coin üretmesin).
signal placed(by_player: bool, fresh: bool)
## Tahtaya bırakıldı ama sığmadı (kombo kırılır).
signal invalid_drop
## Oyuncu bir parçayı tuttu (öğretici kapanır).
signal picked

const LIFT := 1.25               # parça parmağın kaç hücre üstünde yüzer
const SNAP_TOL := 0.62           # hücre cinsinden mıknatıs mesafesi

var lvl: LevelData
var board: Board
var fx: Fx
var world: Node2D                 # sarsıntı kökü
var pieces := {}                  # pid → PieceView
var placements := {}              # pid → Vector2i
var history: Array[String] = []
var cs := 100.0
var tray_rect := Rect2()
var elapsed := 0.0
var done := false
var hints_used := 0
## Bu denemede en az bir kez yerleşmiş parçalar (kombo istismarına karşı).
var _landed_once := {}
## Göz at: çözüm hayaleti katmanı.
var _peek: Node2D
## Duraklatıldı: süre durur, dokunma yok (sheet açık / üstte başka ekran).
var paused := false
## Ekran düzeni: tahta alanının üst ve alt sınırı (HUD ve güç barı dışarıda).
var area_top := 280.0
var area_bottom := -1.0
## false → arka plan ekran tarafından çizilir (sahne manzarası).
var use_backdrop := true

var _drag: PieceView
var _drag_from_board := Vector2i(-1, -1)
var _finger := Vector2.ZERO
var _last_finger := Vector2.ZERO
var _vel := Vector2.ZERO
var _snap := Vector2i(-99, -99)

## restore: {pid: Vector2i} yarım kalan oturumdan yerleşimler (animasyonsuz konur).
func start(level: LevelData, restore := {}) -> void:
	lvl = level
	var vp := get_viewport_rect().size
	if area_bottom < 0.0:
		area_bottom = vp.y - 40.0
	world = Node2D.new()
	add_child(world)
	Juice.shake_root = world

	if use_backdrop:
		world.add_child(Backdrop.new())

	# Ahşap çerçeve (iç alan 840/1024): çerçeve kenarı ≈ (n+0.36)·cs·1.219. Genişliğe sığsın ve
	# tahta alanın en çok %60'ını kaplasın (kalanı tepsi) → uzun telefonlarda tepsi büyür.
	var k := (lvl.width + 0.36) * 1024.0 / 840.0
	var area_h := area_bottom - area_top
	cs = floorf(minf((minf(vp.x, 1080.0) - 70.0) / k, area_h * 0.6 / k))
	board = Board.new()
	board.setup(lvl, cs)
	var gp := board.grid_px()
	var frame_h := k * cs
	board.position = Vector2((vp.x - gp.x) / 2.0, area_top + frame_h / 2.0 - gp.y / 2.0)
	world.add_child(board)

	var tray_top := board.position.y + gp.y + cs * 0.75
	var tw := minf(vp.x, 1080.0) - 80.0
	tray_rect = Rect2((vp.x - tw) / 2.0, tray_top, tw, area_bottom - tray_top)
	var tray := Tray.new()
	tray.rect = tray_rect
	world.add_child(tray)

	var layer := Node2D.new()
	world.add_child(layer)
	for p in lvl.pieces:
		var v := PieceView.new()
		v.setup(p, cs)
		layer.add_child(v)
		pieces[p.id] = v
	_layout_tray(true)

	fx = Fx.new()
	world.add_child(fx)
	for pid in restore:
		if pieces.has(pid):
			_restore_piece(pieces[pid], restore[pid])
	_intro()

func _restore_piece(v: PieceView, o: Vector2i) -> void:
	board.place(v.data, o)
	placements[v.data.id] = o
	history.append(v.data.id)
	_landed_once[v.data.id] = true
	v.state = PieceView.State.PLACED
	v.z_index = _placed_z(v)
	v.position = board.position + (Vector2(o) + Vector2(v.data.size) / 2.0) * cs
	v.set_scale_now(1.0)

## Tepsi: parçaları satırlara diz, sığmazsa ölçeği küçült.
func _layout_tray(initial := false) -> void:
	var ids: Array = lvl.pieces.map(func(p): return p.id)
	var s := 0.62
	var rows: Array = []
	while s > 0.2:
		rows = _pack_rows(ids, s)
		var h := 0.0
		for r in rows:
			h += r.h
		if h + (rows.size() - 1) * 24.0 <= tray_rect.size.y - 40:
			break
		s -= 0.04
	var y := tray_rect.position.y + 20.0
	var total_h := 0.0
	for r in rows:
		total_h += r.h
	y += (tray_rect.size.y - 40 - total_h - (rows.size() - 1) * 24.0) / 2.0
	for r in rows:
		var x: float = tray_rect.position.x + (tray_rect.size.x - r.w) / 2.0
		for pid: String in r.ids:
			var v: PieceView = pieces[pid]
			var w := v.size_px().x * s
			v.home = Vector2(x + w / 2.0, y + r.h / 2.0)
			v.tray_scale = s
			if initial:
				v.position = v.home
				v.set_scale_now(s)
			x += w + 36.0
		y += r.h + 24.0

func _pack_rows(ids: Array, s: float) -> Array:
	var rows: Array = []
	var cur := {ids = [], w = 0.0, h = 0.0}
	for pid: String in ids:
		var sz: Vector2 = pieces[pid].size_px() * s
		var add := sz.x + (36.0 if not cur.ids.is_empty() else 0.0)
		if cur.w + add > tray_rect.size.x - 40 and not cur.ids.is_empty():
			rows.append(cur)
			cur = {ids = [], w = 0.0, h = 0.0}
			add = sz.x
		cur.ids.append(pid)
		cur.w += add
		cur.h = maxf(cur.h, sz.y)
	if not cur.ids.is_empty():
		rows.append(cur)
	return rows

## Giriş: tahta aşağıdan yaylanır, parçalar sırayla tepsiye düşer.
func _intro() -> void:
	board.scale = Vector2(0.85, 0.85)
	var gp := board.grid_px()
	var bp := board.position
	board.position = bp + gp * 0.075
	var tw := create_tween().set_parallel()
	tw.tween_property(board, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(board, "position", bp, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var i := 0
	for pid in pieces:
		var v: PieceView = pieces[pid]
		if placements.has(pid):
			continue
		v.set_scale_now(0.0)
		v.target_scale = 0.0
		get_tree().create_timer(0.25 + i * 0.06).timeout.connect(func():
			v.target_scale = v.tray_scale
			v.punch(6.0, -3.0)
			Sfx.play("click", 1.2 + i * 0.05, -8.0))
		i += 1

func _process(dt: float) -> void:
	if not done and not paused:
		elapsed += dt
	if _drag:
		var target := _finger + Vector2(0, -LIFT * cs)
		_drag.position = _drag.position.lerp(target, 1.0 - exp(-38.0 * dt))
		_vel = _vel.lerp((_finger - _last_finger) / maxf(dt, 0.001), 0.25)
		_last_finger = _finger
		var heavy := 1.0 / sqrt(float(_drag.data.cells.size()))
		_drag.target_rot = clampf(_vel.x * 0.00012 * heavy, -0.09, 0.09)
		_update_snap()

func _unhandled_input(e: InputEvent) -> void:
	if done or paused:
		if _drag and paused:
			_drop()
		return
	if e is InputEventScreenTouch:
		if e.index != 0:
			return
		if e.pressed:
			_pick(e.position)
		else:
			_drop()
	elif e is InputEventScreenDrag and e.index == 0 and _drag:
		_finger = e.position

func _pick(at: Vector2) -> void:
	var w := world.get_global_transform().affine_inverse() * at
	var best: PieceView
	for pid in pieces:
		var v: PieceView = pieces[pid]
		if v.state in [PieceView.State.TRAY, PieceView.State.PLACED] and v.hit(w, 0.18 if v.state == PieceView.State.PLACED else 0.45):
			if best == null or v.z_index >= best.z_index:
				best = v
	if best == null:
		return
	_drag = best
	_finger = w
	_last_finger = w
	_vel = Vector2.ZERO
	_drag_from_board = placements.get(best.data.id, Vector2i(-1, -1))
	if best.state == PieceView.State.PLACED:
		board.remove(best.data.id)
		placements.erase(best.data.id)
	best.state = PieceView.State.DRAG
	best.z_index = 50
	best.target_scale = 1.04
	best.punch(-3.0, 5.0)
	best.lift = 1.0
	best.queue_redraw()
	Sfx.play("click", 1.1, -4.0)
	Juice.haptic("light")
	picked.emit()

func _snap_origin() -> Vector2i:
	var top_left := _drag.position - _drag.size_px() / 2.0 - board.position
	var f := top_left / cs
	return Vector2i(roundi(f.x), roundi(f.y))

func _update_snap() -> void:
	var o := _snap_origin()
	var top_left := _drag.position - _drag.size_px() / 2.0 - board.position
	var near := (top_left / cs - Vector2(o)).length() <= SNAP_TOL
	if near and board.fits(_drag.data, o):
		if o != _snap:
			if _snap == Vector2i(-99, -99):
				Sfx.play("snap", 1.0, -6.0)
				Juice.haptic("medium")
			else:
				Juice.haptic("tick")
				Sfx.play("click", 1.6, -14.0, 0.02)
			_snap = o
			board.set_ghost(_drag.data, o)
	elif _snap != Vector2i(-99, -99):
		_snap = Vector2i(-99, -99)
		board.clear_ghost()

func _drop() -> void:
	if _drag == null:
		return
	var v := _drag
	_drag = null
	board.clear_ghost()
	v.target_rot = 0.0
	v.lift = 0.0
	if _snap != Vector2i(-99, -99):
		_place(v, _snap, true)
	else:
		_return_to_tray(v, _drag_from_board == Vector2i(-1, -1))
	_snap = Vector2i(-99, -99)

func _place(v: PieceView, o: Vector2i, by_player: bool) -> void:
	board.place(v.data, o)
	placements[v.data.id] = o
	history.append(v.data.id)
	v.state = PieceView.State.FLYING
	v.z_index = _placed_z(v)
	v.target_scale = 1.0
	var dest := board.position + (Vector2(o) + Vector2(v.data.size) / 2.0) * cs
	var tw := create_tween()
	tw.tween_property(v, "position", dest, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_on_landed.bind(v, o, by_player))

## "Thunk": yassılma, toz, yuva dalgası, komşu parçalara titreşim, yükselen nota.
func _on_landed(v: PieceView, o: Vector2i, by_player: bool) -> void:
	v.state = PieceView.State.PLACED
	var mass := 1.0 / sqrt(float(v.data.cells.size()) / 3.0)
	v.punch(4.0 * mass, -4.5 * mass)
	v.flash = 0.8
	var step := placements.size() - 1
	Sfx.note(step, "place", -2.0)
	Sfx.play("snap", 0.7, -10.0)
	Juice.haptic("medium")
	Juice.add_trauma(0.18 + 0.02 * v.data.cells.size())
	var ctr := Vector2(o) + Vector2(v.data.size) / 2.0
	board.ripple(ctr, 1.0)
	var bottom := board.position + Vector2(o) * cs
	for c in v.data.cells:
		if not v.data.has_cell(c + Vector2i.DOWN):
			fx.puff(bottom + (Vector2(c) + Vector2(0.5, 1.0)) * cs, 3, Palette.CREAM, cs * 0.16)
	_nudge_neighbors(v.data.id, o)
	var fresh := not _landed_once.has(v.data.id)
	_landed_once[v.data.id] = true
	placed.emit(by_player, fresh)
	if not done and SolutionChecker.is_solved(lvl, placements):
		_win()

func _nudge_neighbors(pid: String, o: Vector2i) -> void:
	var p := lvl.piece(pid)
	var hit := {}
	for c in p.cells:
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + o + d
			if board.occ.has(n) and board.occ[n] != pid:
				hit[board.occ[n]] = true
	for other in hit:
		var nv: PieceView = pieces[other]
		nv.punch(3.0, -2.0)

func _return_to_tray(v: PieceView, _from_tray: bool) -> void:
	v.state = PieceView.State.FLYING
	v.target_scale = v.tray_scale
	# Tahtanın üstüne bırakılıp sığmadıysa: kırmızı + hata sesi; tepsiye bırakıldıysa sessizce döner.
	var over_board := Rect2(board.position, board.grid_px()).grow(cs * 0.5).has_point(v.position)
	if over_board:
		v.invalid = 1.0
		v.wobble(10.0)
		Sfx.play("error", 1.0, -6.0)
		Juice.haptic("light")
		invalid_drop.emit()
	var tw := create_tween()
	tw.tween_property(v, "position", v.home, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		v.state = PieceView.State.TRAY
		v.z_index = 0
		v.wobble(4.0))

## Yerleşmiş parça z sırası: küçükler üstte, hep tahtanın (z 0) üstünde ve sürüklenenin (50) altında.
## (Eski 10 - hücre formülü 10+ hücreli parçaları tahtanın arkasına gömüyordu.)
func _placed_z(v: PieceView) -> int:
	return clampi(40 - v.data.cells.size(), 1, 39)

func can_peek() -> bool:
	return not done and _drag == null and _peek == null and can_hint()

## Göz at: yerinde olmayan parçaların çözüm silüetlerini birkaç saniye tahtada gösterir.
func peek(seconds := 3.0) -> bool:
	if not can_peek():
		return false
	_peek = PeekLayer.new()
	_peek.setup(lvl, placements, cs)
	_peek.position = board.position
	_peek.z_index = 45
	world.add_child(_peek)
	var tw := _peek.create_tween()
	_peek.modulate.a = 0.0
	tw.tween_property(_peek, "modulate:a", 1.0, 0.25)
	tw.tween_interval(seconds)
	tw.tween_property(_peek, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func() -> void:
		_peek.queue_free()
		_peek = null)
	Sfx.play("reward", 1.5, -10.0)
	Juice.haptic("light")
	board.ripple(Vector2(lvl.width, lvl.height) / 2.0, 0.6)
	return true

## Tüm yerleşimleri tepsiye geri gönder (güçlendirme "yeniden başlat"). Uygulanamazsa false.
func reset_board() -> bool:
	if done or _drag or placements.is_empty():
		return false
	var i := 0
	for pid in placements.keys():
		board.remove(pid)
		var v: PieceView = pieces[pid]
		get_tree().create_timer(i * 0.05).timeout.connect(func() -> void:
			v.punch(-4.0, 6.0)
			_return_to_tray(v, true))
		i += 1
	placements.clear()
	history.clear()
	Sfx.play("snap", 0.8, -6.0)
	Juice.add_trauma(0.2)
	return true

## Uçuşta parça var mı (iniş tween'i sürerken çözüm iki kez algılanmasın).
func _flying_any() -> bool:
	for pid in pieces:
		if (pieces[pid] as PieceView).state == PieceView.State.FLYING and placements.has(pid):
			return true
	return false

func can_hint() -> bool:
	if done or _drag:
		return false
	for p in lvl.pieces:
		if placements.get(p.id, Vector2i(-99, -99)) != lvl.solution[p.id]:
			return true
	return false

## İpucu: çözümde yerinde olmayan ilk parçayı doğru yere uçurur; yolundakileri tepsiye yollar.
func hint() -> bool:
	if done or _drag or _flying_any():
		return false
	for p in lvl.pieces:
		var o: Vector2i = lvl.solution[p.id]
		if placements.get(p.id, Vector2i(-99, -99)) == o:
			continue
		hints_used += 1
		if placements.has(p.id):
			board.remove(p.id)
			placements.erase(p.id)
		for c in p.cells:
			var a := c + o
			if board.occ.has(a):
				var other: String = board.occ[a]
				board.remove(other)
				placements.erase(other)
				_return_to_tray(pieces[other], true)
		var v: PieceView = pieces[p.id]
		v.z_index = 50
		v.flash = 1.0
		fx.sparks(v.position, 14, Palette.GOLD)
		Sfx.play("reward", 1.3, -8.0)
		_place(v, o, false)
		return true
	return false

func stars() -> int:
	return Progress.compute_stars(elapsed, lvl.width)

## Çözüm: hit-stop → çapraz parlama dalgası → parçalar sırayla zıplar → konfeti → sonuç.
func _win() -> void:
	if done:
		return
	done = true
	var st := stars()
	solve_started.emit()
	await Juice.hit_stop(0.09, 0.03)
	Juice.add_trauma(0.55)
	Juice.haptic("heavy")
	Sfx.play("solve", 1.0, 0.0, 0.0)
	var gp := board.grid_px()
	fx.ring(board.position + gp / 2.0, gp.x * 0.6, Palette.CREAM, 26.0)
	var order: Array = lvl.pieces.duplicate()
	order.sort_custom(func(a, b): return (placements[a.id].x + placements[a.id].y) < (placements[b.id].x + placements[b.id].y))
	var i := 0
	for p: PieceData in order:
		var v: PieceView = pieces[p.id]
		get_tree().create_timer(0.08 * i).timeout.connect(func():
			v.punch(-2.5, 5.0)
			v.flash = 1.0
			Sfx.note(i, "place", -10.0)
			fx.sparks(v.position, 8, Palette.CREAM, 420.0))
		i += 1
	await get_tree().create_timer(0.08 * i + 0.1).timeout
	var vp := get_viewport_rect().size
	fx.confetti(Vector2(-20, vp.y * 0.62), 70, PI * 0.18, -PI * 0.32, 2100.0)
	fx.confetti(Vector2(vp.x + 20, vp.y * 0.62), 70, PI * 0.18, -PI * 0.68, 2100.0)
	Sfx.play("reward", 1.0, -2.0, 0.0)
	await get_tree().create_timer(0.35).timeout
	solved.emit(st, elapsed)
