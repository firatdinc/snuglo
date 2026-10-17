extends Screen
## İlk açılış öğreticisi (3 sayfa):
##  1) Hoş geldin — el sallayan Snuglo.
##  2) Dene! — gerçek 3×3 mini tahta: üst sıra hazır, oyuncu iki yamayı sürükler. Keçe el
##     işaretçisi sıradaki parçayı tepsiden yuvasına sürükleyip gösterir (döngü). Çözünce konfeti.
##  3) Her gün sıcacık — sevinen Snuglo → "Başlayalım" (onboarded=true) → menü.
## Sağ üstte Geç. Dev: SNUG_ONB_PAGE=<1..3>.

const LIFT := 0.55
const SNAP_TOL := 0.9

var _page := 0
var _pages: Array[Control] = []
var _dots: Dots
var _next: JuicyButton
var _busy := false

# Sayfa 2: mini oyun
var _play: Node2D
var _board: Board
var _fx: Fx
var _hand: Hand
var _lvl: LevelData
var _views := {}
var _placed := {}
var _cs := 180.0
var _drag: PieceView
var _finger := Vector2.ZERO
var _snap_ok := false
var _solved := false
var _praise: Label
var _hand_tw: Tween

func build() -> void:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("flower")
	bg.size = size
	bg.wash_top = 0.6
	bg.wash_bottom = 0.9
	add_child(bg)
	var wash := ColorRect.new()
	wash.color = Color(Palette.BG_TOP, 0.35)
	wash.size = size
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	for i in 3:
		var p := Control.new()
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.size = size
		p.visible = false
		add_child(p)
		_pages.append(p)
	_build_welcome(_pages[0])
	_build_try(_pages[1])
	_build_cozy(_pages[2])
	# Geç
	var skip := Ui.button(tr("common.skip"), "sage", Vector2(230, 100), "", 38)
	put(skip, Vector2(X0 + W - 260, TOP + 30))
	skip.tapped.connect(_finish)
	# Alt: noktalar + İleri
	var by := H - BOTTOM - 210
	_dots = Dots.new()
	put(_dots, Vector2(X0 + (W - 300) / 2.0, by - 90), Vector2(300, 60))
	_next = Ui.button(tr("common.next"), "terracotta", Vector2(minf(W - 200, 720.0), 170), "", 64)
	put(_next, Vector2(X0 + (W - _next.size.x) / 2.0, by))
	_next.tapped.connect(func() -> void:
		if _page == 2:
			_finish()
		else:
			_go(_page + 1))
	var start := clampi(int(OS.get_environment("SNUG_ONB_PAGE")) - 1, 0, 2) if OS.get_environment("SNUG_ONB_PAGE") != "" else 0
	_show_page(start, false)
	if OS.get_environment("SNUG_ONB_SOLVE") != "" and start == 1:
		_dev_drag_all()

# ------------------------------------------------------------------ Sayfalar

func _build_welcome(p: Control) -> void:
	var ms := minf(W * 0.6, 640.0)
	var m := Ui.icon("wave", Vector2(ms, ms), "mascot")
	Ui.place(m, Vector2(X0 + (W - ms) / 2.0, H * 0.18), Vector2(ms, ms))
	m.pivot_offset = Vector2(ms / 2.0, ms * 0.9)
	p.add_child(m)
	Ui.bob(m, 10.0, 2.4)
	p.set_meta("hero", m)
	_text_block(p, H * 0.18 + ms + 30, "onboarding.page1.title", "onboarding.page1.body")

func _build_cozy(p: Control) -> void:
	var ms := minf(W * 0.55, 600.0)
	var m := Ui.icon("cheer", Vector2(ms, ms), "mascot")
	Ui.place(m, Vector2(X0 + (W - ms) / 2.0, H * 0.2), Vector2(ms, ms))
	m.pivot_offset = Vector2(ms / 2.0, ms * 0.9)
	p.add_child(m)
	Ui.bob(m, 12.0, 1.8)
	p.set_meta("hero", m)
	# Küçük dostlar halkası (paketlerin peluşları)
	var friends := ["fox", "owl", "bunny", "frog"]
	for i in friends.size():
		var t := PackArt.friend(friends[i])
		if t == null:
			continue
		var fsz := 150.0
		var f := Ui.tex_rect(t, Vector2(fsz, fsz))
		var left := i < 2
		var row := i % 2
		var fx := (X0 + 30 + row * 50) if left else (X0 + W - 30 - fsz - row * 50)
		Ui.place(f, Vector2(fx, m.position.y + ms * (0.22 + row * 0.42)), Vector2(fsz, fsz))
		p.add_child(f)
		Ui.bob(f, 6.0, 1.6 + i * 0.2, i)
		f.set_meta("delay", 0.15 + i * 0.07)
	_text_block(p, H * 0.2 + ms + 30, "onboarding.page3.title", "onboarding.page3.body")

func _text_block(p: Control, y: float, title_key: String, body_key: String) -> void:
	var t := Ui.title(tr(title_key), 76, Palette.CREAM)
	Ui.place(t, Vector2(X0 + 40, y), Vector2(W - 80, 110))
	p.add_child(t)
	var card := QuiltCard.new()
	card.fill = Palette.CREAM
	card.radius = 44
	var bw := W - 160
	var b := Ui.wrap(Ui.label(tr(body_key), 40, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER), bw - 80)
	Ui.place(card, Vector2(X0 + 80, y + 120), Vector2(bw, 190))
	Ui.place(b, Vector2(40, 20), Vector2(bw - 80, 150))
	card.add_child(b)
	p.add_child(card)

func _build_try(p: Control) -> void:
	var t := Ui.title(tr("onboarding.page2.title"), 76, Palette.CREAM)
	Ui.place(t, Vector2(X0 + 40, TOP + 150), Vector2(W - 80, 110))
	p.add_child(t)
	var hint := Ui.label(tr("coach.drag"), 40, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	hint.add_theme_color_override("font_outline_color", Palette.CREAM)
	hint.add_theme_constant_override("outline_size", 12)
	Ui.place(hint, Vector2(X0 + 40, TOP + 260), Vector2(W - 80, 60))
	p.add_child(hint)
	_lvl = _mini_level()
	var avail_h := (H - BOTTOM - 330) - (TOP + 360)
	_cs = floorf(minf((W - 380) / 3.0, avail_h / 7.0))
	_play = Node2D.new()
	p.add_child(_play)
	_board = Board.new()
	_board.setup(_lvl, _cs)
	var gp := _board.grid_px()
	_board.position = Vector2(X0 + (W - gp.x) / 2.0, TOP + 360 + _cs * 0.45)
	_play.add_child(_board)
	var tray_y := _board.position.y + gp.y + _cs * 1.15
	var tray := Tray.new()
	tray.rect = Rect2(X0 + 100, tray_y - _cs * 0.4, W - 200, _cs * 2.3)
	_play.add_child(tray)
	var layer := Node2D.new()
	_play.add_child(layer)
	var xs := [X0 + W * 0.32, X0 + W * 0.68]
	var k := 0
	for pc in _lvl.pieces:
		var v := PieceView.new()
		v.setup(pc, _cs)
		layer.add_child(v)
		_views[pc.id] = v
		if pc.id == "a":
			var o: Vector2i = _lvl.solution[pc.id]
			_board.place(pc, o)
			_placed[pc.id] = o
			v.state = PieceView.State.PLACED
			v.position = _board.position + (Vector2(o) + Vector2(pc.size) / 2.0) * _cs
			v.set_scale_now(1.0)
		else:
			v.tray_scale = 0.72
			v.home = Vector2(xs[k], tray_y + _cs * 0.75)
			v.position = v.home
			v.set_scale_now(0.72)
			k += 1
	_fx = Fx.new()
	_play.add_child(_fx)
	_hand = Hand.new()
	_hand.size_px = _cs * 1.1
	_hand.visible = false
	_hand.z_index = 60
	_play.add_child(_hand)
	_praise = Ui.title("", 90, Palette.CREAM)
	Ui.place(_praise, Vector2(X0, _board.position.y + gp.y * 0.35), Vector2(W, 130))
	_praise.modulate.a = 0.0
	p.add_child(_praise)

## 3×3: üst sıra (a) hazır; b = L sol-alt, c = ters L sağ-alt.
func _mini_level() -> LevelData:
	var l := LevelData.new()
	l.id = "onboarding-1"
	l.width = 3
	l.height = 3
	var a: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var b: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
	var c: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	l.pieces = [PieceData.make("a", a, 3), PieceData.make("b", b, 0), PieceData.make("c", c, 1)]
	l.solution = {"a": Vector2i(0, 0), "b": Vector2i(0, 1), "c": Vector2i(1, 1)}
	return l

# ------------------------------------------------------------------ Sayfa geçişi

func _show_page(i: int, animate := true) -> void:
	var old := _page
	_page = i
	_dots.active = i
	_dots.queue_redraw()
	_next.text = tr("onboarding.getStarted") if i == 2 else tr("common.next")
	var np := _pages[i]
	np.visible = true
	if animate and not Ui.reduce_motion():
		var op := _pages[old]
		var dir := 1.0 if i > old else -1.0
		np.position.x = size.x * dir
		var tw := create_tween().set_parallel()
		tw.tween_property(op, "position:x", -size.x * dir, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(np, "position:x", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(func() -> void: op.visible = false)
	else:
		for j in _pages.size():
			_pages[j].visible = j == i
			_pages[j].position.x = 0
	if np.has_meta("hero"):
		var h: Control = np.get_meta("hero")
		Ui.pop_in(h, 0.15, 0.3, 0.55)
		get_tree().create_timer(0.5).timeout.connect(func() -> void: _wave(h))
	for c in np.get_children():
		if c.has_meta("delay"):
			Ui.pop_in(c, float(c.get_meta("delay")) + 0.2, 0.2)
	# Deneme sayfasında İleri, çözülene kadar gizli
	_next.visible = i != 1 or _solved
	if i == 1 and not _solved:
		get_tree().create_timer(0.6).timeout.connect(_loop_hand)
	Sfx.play("snap", 0.9 + i * 0.1, -8.0)

func _wave(h: Control) -> void:
	if Ui.reduce_motion() or not is_instance_valid(h):
		return
	var tw := h.create_tween().set_loops(2)
	tw.tween_property(h, "rotation", 0.07, 0.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(h, "rotation", -0.05, 0.2).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func() -> void: h.rotation = 0.0)

func _go(i: int) -> void:
	if _busy:
		return
	_busy = true
	_show_page(i)
	get_tree().create_timer(0.45).timeout.connect(func() -> void: _busy = false)

func on_back() -> bool:
	if _page > 0:
		_go(_page - 1)
	return true

func _finish() -> void:
	Settings.set_value("onboarded", true)
	Main.goto("menu")

# ------------------------------------------------------------------ Keçe el döngüsü

func _target() -> PieceView:
	for pid in ["b", "c"]:
		if not _placed.has(pid):
			return _views[pid]
	return null

func _dest(v: PieceView) -> Vector2:
	var o: Vector2i = _lvl.solution[v.data.id]
	return _board.position + (Vector2(o) + Vector2(v.data.size) / 2.0) * _cs

func _loop_hand() -> void:
	if _hand_tw:
		_hand_tw.kill()
	var v := _target()
	if v == null or _drag or _page != 1 or _solved:
		_hand.visible = false
		return
	var from := v.home
	var to := _dest(v)
	_hand.visible = true
	_hand.position = from
	_hand.modulate.a = 0.0
	_hand.scale = Vector2(1.2, 1.2)
	_hand.trail_from = from
	_hand.trail = 0.0
	_hand_tw = create_tween()
	_hand_tw.tween_property(_hand, "modulate:a", 1.0, 0.2)
	_hand_tw.parallel().tween_property(_hand, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hand_tw.tween_property(_hand, "scale", Vector2(0.86, 0.86), 0.16)
	_hand_tw.tween_callback(func() -> void:
		v.punch(-2.0, 3.0)
		v.target_scale = 0.9)
	_hand_tw.tween_method(func(t: float) -> void:
		_hand.position = from.lerp(to, t) + Vector2(0, -sin(t * PI) * _cs * 0.6)
		_hand.trail = t
		_hand.queue_redraw(), 0.0, 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hand_tw.tween_callback(func() -> void:
		v.target_scale = v.tray_scale
		_board.ripple(Vector2(_lvl.solution[v.data.id]) + Vector2(v.data.size) / 2.0, 0.5))
	_hand_tw.tween_property(_hand, "scale", Vector2.ONE, 0.16)
	_hand_tw.tween_property(_hand, "modulate:a", 0.0, 0.3).set_delay(0.25)
	_hand_tw.tween_interval(0.5)
	_hand_tw.tween_callback(_loop_hand)

# ------------------------------------------------------------------ Sürükle-bırak

func _local(at: Vector2) -> Vector2:
	return _play.get_global_transform_with_canvas().affine_inverse() * at

func _input(e: InputEvent) -> void:
	if _page != 1 or _solved or _busy:
		return
	if e is InputEventScreenTouch and e.index == 0:
		if e.pressed:
			_pick(_local(e.position))
		else:
			_drop()
	elif e is InputEventScreenDrag and e.index == 0 and _drag:
		_finger = _local(e.position)

func _pick(at: Vector2) -> void:
	for pid in ["b", "c"]:
		var v: PieceView = _views[pid]
		if v.state == PieceView.State.TRAY and v.hit(at, 0.5):
			_drag = v
			_finger = at
			v.state = PieceView.State.DRAG
			v.z_index = 50
			v.target_scale = 1.04
			v.lift = 1.0
			v.punch(-3.0, 5.0)
			Sfx.play("click", 1.1, -4.0)
			Juice.haptic("light")
			if _hand_tw:
				_hand_tw.kill()
			_hand.visible = false
			return

func _process(dt: float) -> void:
	if _drag == null:
		return
	var target := _finger + Vector2(0, -LIFT * _cs)
	_drag.position = _drag.position.lerp(target, 1.0 - exp(-30.0 * dt))
	var o: Vector2i = _lvl.solution[_drag.data.id]
	var tl := _drag.position - _drag.size_px() / 2.0 - _board.position
	var ok := (tl / _cs - Vector2(o)).length() <= SNAP_TOL
	if ok != _snap_ok:
		_snap_ok = ok
		if ok:
			_board.set_ghost(_drag.data, o)
			Sfx.play("snap", 1.0, -6.0)
			Juice.haptic("medium")
		else:
			_board.clear_ghost()

func _drop() -> void:
	if _drag == null:
		return
	var v := _drag
	_drag = null
	_board.clear_ghost()
	v.lift = 0.0
	if _snap_ok:
		_snap_ok = false
		var o: Vector2i = _lvl.solution[v.data.id]
		_board.place(v.data, o)
		_placed[v.data.id] = o
		v.state = PieceView.State.FLYING
		v.z_index = 5
		v.target_scale = 1.0
		var tw := create_tween()
		tw.tween_property(v, "position", _dest(v), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void: _landed(v, o))
	else:
		v.state = PieceView.State.FLYING
		v.target_scale = v.tray_scale
		var tw := create_tween()
		tw.tween_property(v, "position", v.home, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			v.state = PieceView.State.TRAY
			v.z_index = 0
			v.wobble(4.0)
			get_tree().create_timer(0.6).timeout.connect(_loop_hand))

func _landed(v: PieceView, o: Vector2i) -> void:
	v.state = PieceView.State.PLACED
	v.punch(4.0, -4.5)
	v.flash = 0.8
	Sfx.note(_placed.size() + 1, "place", -2.0)
	Sfx.play("snap", 0.7, -10.0)
	Juice.haptic("medium")
	_board.ripple(Vector2(o) + Vector2(v.data.size) / 2.0, 1.0)
	for c in v.data.cells:
		_fx.puff(_board.position + (Vector2(c + o) + Vector2(0.5, 1.0)) * _cs, 3, Palette.CREAM, _cs * 0.16)
	if SolutionChecker.is_solved(_lvl, _placed):
		_win()
	else:
		get_tree().create_timer(0.7).timeout.connect(_loop_hand)

func _win() -> void:
	_solved = true
	for c in _play.get_children():
		if c is Tray:
			c.create_tween().tween_property(c, "modulate:a", 0.0, 0.4)
	_hand.visible = false
	Sfx.play("solve", 1.0, 0.0, 0.0)
	Juice.haptic("heavy")
	var gp := _board.grid_px()
	_fx.ring(_board.position + gp / 2.0, gp.x * 0.7, Palette.CREAM, 22.0)
	var i := 0
	for pid in _views:
		var v: PieceView = _views[pid]
		get_tree().create_timer(0.1 * i).timeout.connect(func() -> void:
			v.punch(-2.5, 5.0)
			v.flash = 1.0
			_fx.sparks(v.position, 10, Palette.GOLD, 520.0))
		i += 1
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		_fx.confetti(Vector2(X0 - 20, H * 0.6), 60, PI * 0.18, -PI * 0.32, 2000.0)
		_fx.confetti(Vector2(X0 + W + 20, H * 0.6), 60, PI * 0.18, -PI * 0.68, 2000.0)
		Sfx.play("reward", 1.0, -2.0, 0.0)
		var bn := Ui.banner(tr("praise.%d" % (randi() % 6)), 620.0, 150.0)
		bn.position = Vector2(X0 + (W - bn.size.x) / 2.0, _board.position.y + _board.grid_px().y + _cs * 0.6)
		_pages[1].add_child(bn)
		Ui.pop_in(bn, 0.0, 0.3, 0.5)
		_next.visible = true
		Ui.pop_in(_next, 0.3, 0.5))

## Dev: gerçek dokunma olaylarıyla iki parçayı sürükle (SNUG_ONB_SOLVE=1).
func _dev_drag_all() -> void:
	await get_tree().create_timer(1.0).timeout
	var xf := _play.get_global_transform_with_canvas()
	for pid in ["b", "c"]:
		var v: PieceView = _views[pid]
		var c0 := v.data.cells[0]
		var start := xf * (v.home + (Vector2(c0) - Vector2(v.data.size) / 2.0 + Vector2(0.5, 0.5)) * _cs * v.tray_scale)
		var dest := xf * (_dest(v) + Vector2(0, LIFT * _cs))
		_dev_touch(start, true)
		for i in 24:
			await get_tree().process_frame
			var d := InputEventScreenDrag.new()
			d.position = get_viewport().get_final_transform() * start.lerp(dest, ease(i / 23.0, 0.5))
			Input.parse_input_event(d)
		await get_tree().create_timer(0.25).timeout
		_dev_touch(dest, false)
		await get_tree().create_timer(0.5).timeout

func _dev_touch(at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = get_viewport().get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)

## Dev: 2. sayfayı çözülmüş göster (ekran görüntüsü için).
func dev_solve() -> void:
	for pid in ["b", "c"]:
		var v: PieceView = _views[pid]
		var o: Vector2i = _lvl.solution[pid]
		_board.place(v.data, o)
		_placed[pid] = o
		v.state = PieceView.State.PLACED
		v.position = _dest(v)
		v.set_scale_now(1.0)
	_win()

# ------------------------------------------------------------------ Bileşenler

## Keçe el: işaret parmağı yukarıda (uç = orijin), krem keçe avuç, terrakota manşet, dikişler.
class Hand extends Node2D:
	var size_px := 180.0
	var trail_from := Vector2.ZERO
	var trail := 0.0
	func _draw() -> void:
		var s := size_px / 180.0
		# Arkasında kesikli iplik izi (başlangıçtan ele)
		if trail > 0.02:
			var a := (trail_from - position) / scale
			var segs := PeceDash.line(a, Vector2.ZERO, 16.0 * s, 12.0 * s)
			draw_multiline(segs, Color(Palette.TERRACOTTA, 0.85), 6.0 * s)
		var t := UiArt.tex("ic_hand")
		if t:
			var h := size_px * 1.15
			var w := h * t.get_width() / t.get_height()
			var r := Rect2(-Vector2(w * 0.08, h * 0.05), Vector2(w, h))
			draw_texture_rect(t, Rect2(r.position + Vector2(8, 12) * s, r.size), false, Color(0.3, 0.15, 0.05, 0.3))
			draw_texture_rect(t, r, false)
			return
		_draw_vector(s)
	func _draw_vector(s: float) -> void:
		draw_set_transform(Vector2(8, 10) * s, -0.35, Vector2(s, s))
		var skin := Palette.PIECES[5].lightened(0.25)
		var edge := Palette.PIECES[5].darkened(0.25)
		# Gölge
		draw_colored_polygon(_finger(Vector2(4, 8)), Color(Palette.INK, 0.18))
		draw_colored_polygon(_palm(Vector2(4, 8)), Color(Palette.INK, 0.18))
		# Avuç + parmaklar (kıvrık)
		draw_colored_polygon(_palm(Vector2.ZERO), edge)
		draw_colored_polygon(_palm_in(), skin)
		for i in 3:
			var k := Rect2(Vector2(14 + i * 26, 76), Vector2(28, 44))
			draw_colored_polygon(Ui.rrect(k, 14, 4), edge)
			draw_colored_polygon(Ui.rrect(k.grow(-4), 10, 4), skin)
		# Başparmak
		var th := Rect2(Vector2(-34, 98), Vector2(54, 28))
		draw_colored_polygon(Ui.rrect(th, 14, 4), edge)
		draw_colored_polygon(Ui.rrect(th.grow(-4), 10, 4), skin)
		# İşaret parmağı
		draw_colored_polygon(_finger(Vector2.ZERO), edge)
		draw_colored_polygon(Ui.rrect(Rect2(Vector2(-14, 4), Vector2(28, 100)), 14, 5), skin)
		# Manşet
		var cuff := Rect2(Vector2(-22, 166), Vector2(116, 40))
		draw_colored_polygon(Ui.rrect(cuff, 12, 4), Palette.TERRACOTTA)
		draw_multiline(PieceShape.dashes(Ui.rrect(cuff.grow(-7), 8, 3), 8, 6), Color(Palette.STITCH, 0.9), 2.5)
		# Dikişler
		draw_multiline(PieceShape.dashes(Ui.rrect(Rect2(Vector2(-11, 8), Vector2(22, 92)), 11, 4), 7, 6), Color(edge, 0.9), 2.0)
		draw_multiline(PieceShape.dashes(_palm_stitch(), 8, 6), Color(edge, 0.9), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	func _finger(o: Vector2) -> PackedVector2Array:
		var p := Ui.rrect(Rect2(Vector2(-18, 0) + o, Vector2(36, 110)), 18, 5)
		return p
	func _palm(o: Vector2) -> PackedVector2Array:
		return Ui.rrect(Rect2(Vector2(-26, 80) + o, Vector2(118, 96)), 34, 5)
	func _palm_in() -> PackedVector2Array:
		return Ui.rrect(Rect2(Vector2(-22, 84), Vector2(110, 88)), 30, 5)
	func _palm_stitch() -> PackedVector2Array:
		return Ui.rrect(Rect2(Vector2(-14, 92), Vector2(94, 72)), 24, 4)

## Sayfa noktaları: etkin = geniş kumaş yama, diğerleri tebeşir dikişli küçük yama.
class Dots extends Control:
	var active := 0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	func _draw() -> void:
		var n := 3
		var small := 40.0
		var big := 110.0
		var gap := 22.0
		var total := big + small * (n - 1) + gap * (n - 1)
		var x := (size.x - total) / 2.0
		for i in n:
			var w := big if i == active else small
			var r := Rect2(Vector2(x, (size.y - small) / 2.0), Vector2(w, small))
			if i == active:
				var poly := Ui.rrect(r, 14, 3)
				draw_colored_polygon(Ui.rrect(Rect2(r.position + Vector2(0, 4), r.size), 14, 3), Palette.SHADOW)
				var tex := Fabrics.get_tex(i * 4)
				if tex:
					var uv := PackedVector2Array()
					for p in poly:
						uv.append(p / (tex.get_size() * 0.75))
					draw_colored_polygon(poly, Color.WHITE, uv, tex)
				draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-6), 9, 3), 7, 5), Color(Palette.STITCH, 0.85), 2.0)
			else:
				draw_colored_polygon(Ui.rrect(r, 14, 3), Color(Palette.CREAM, 0.8))
				draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-4), 10, 3), 6, 5), Color(Palette.INK_SOFT, 0.6), 2.0)
			x += w + gap

## Düz çizgi boyunca kesikli segmentler.
class PeceDash:
	static func line(a: Vector2, b: Vector2, dash: float, gap: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		var L := a.distance_to(b)
		var t := 0.0
		while t < L:
			out.append(a.lerp(b, t / L))
			out.append(a.lerp(b, minf(t + dash, L) / L))
			t += dash + gap
		return out
