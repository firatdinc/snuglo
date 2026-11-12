class_name SewFlow
extends Control
## Yama dikme akışı (Yorganım ekranının üstünde). 1) alttaki tepsiden düz kumaş kare seç,
## 2) yorgandaki BOŞ bir kareye dokun ya da kumaşı üstüne sürükle (serbest yuva seçimi),
## 3) yorgan o kareye "yakınlaşır": kareyi iğneyle kenarları boyunca sürükleyerek dik. İğne her dikişte
## batar → kumaşın altında gider → çıkar; ses + titreşim + kumaşta çukur + gergin iplik.
## Bitince kare yuvasına küçülür; Quilt.sew_next(slot, set, fabric) ile kaydedilir.

signal closed

const SIDE := 700.0
const NEEDLE_PATH := "res://art/quilt/needle.png"
const THREAD_PATH := "res://art/quilt/thread.png"
const DIMPLE_PATH := "res://art/quilt/dimple.png"
const RIDGE_PATH := "res://art/quilt/ridge.png"

var host: Node                 ## Yorganım ekranı: slot_rect/slot_at/set_slots_hot/hover_slot
var on_done := Callable()
var dev := ""
var _tray: QuiltCard
var _piece: Control
var _piece_card: QuiltCard
var _hint: Label
var _sw: Array[QuiltCard] = []
var _set_cards := {}
var _set := "classic"
var _ci := 0
var _slot := -1
var _stage: _SewStage
var _fx: Fx
var _busy := false
var _home := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx = Fx.new()
	add_child(_fx)
	var rec: Dictionary = Quilt.pending()[0]
	var cols: Array = rec.get("c", [])
	_ci = (int(cols[0]) + 6) % Palette.PIECES.size() if not cols.is_empty() else 0
	_set = Cosmetics.selected_fabric
	var w := Ui.col_w()
	var x0 := Ui.col_x()
	var owned: Array = Cosmetics.fabrics().filter(func(f: Dictionary) -> bool: return f.unlocked)
	var th := 480.0 if owned.size() > 1 else 330.0
	_tray = QuiltCard.new()
	_tray.skin_name = "panel_cream"
	_tray.radius = 56
	_tray.depth = 16
	_tray.mouse_filter = Control.MOUSE_FILTER_STOP
	_tray.size = Vector2(w - 40.0, th)
	_tray.position = Vector2(x0 + 20.0, size.y - Ui.safe_bottom() - th - 20.0)
	add_child(_tray)
	var tw := _tray.size.x
	var title := Ui.label(tr("sew.pickFabric"), 38, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(title, Vector2(130, 34), Vector2(tw - 260, 50))
	_tray.add_child(title)
	var cl := Ui.icon_button("ic_close", 90)
	Ui.place(cl, Vector2(tw - 120, 22), Vector2(90, 90))
	_tray.add_child(cl)
	cl.tapped.connect(cancel)
	var y := 110.0
	if owned.size() > 1:
		var sc := DragScroll.new()
		sc.horizontal = true
		Ui.place(sc, Vector2(30, y), Vector2(tw - 60, 90))
		_tray.add_child(sc)
		var x := 8.0
		for f: Dictionary in owned:
			var label := tr(String(f.name))
			var pw2 := Ui.FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 56.0
			var c := QuiltCard.new()
			c.fill = Palette.CARD
			c.radius = 34
			c.depth = 6
			c.pressable = true
			Ui.place(c, Vector2(x, 6), Vector2(pw2, 72))
			sc.content.add_child(c)
			var l := Ui.label(label, 30, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
			Ui.place(l, Vector2(0, 12), Vector2(pw2, 44))
			c.add_child(l)
			var sid := String(f.id)
			c.tapped.connect(_pick_set.bind(sid))
			_set_cards[sid] = c
			x += pw2 + 12.0
		sc.set_length(x + 8.0)
		y += 104.0
	var ssc := DragScroll.new()
	ssc.horizontal = true
	Ui.place(ssc, Vector2(30, y), Vector2(tw - 60, 160))
	_tray.add_child(ssc)
	var sw := 132.0
	for i in Palette.PIECES.size():
		var c := QuiltCard.new()
		c.fabric = i
		c.fabric_set = _set
		c.radius = 30
		c.depth = 8
		c.pressable = true
		Ui.place(c, Vector2(10.0 + i * (sw + 16.0), 10), Vector2(sw, sw))
		ssc.content.add_child(c)
		_sw.append(c)
		c.tapped.connect(_pick_fabric.bind(i))
	ssc.set_length(20.0 + Palette.PIECES.size() * (sw + 16.0))
	# Tutulan kumaş kare: üstüne sürükle ya da boş kareye dokun.
	_piece = _Piece.new()
	_piece.flow = self
	_piece.size = Vector2(150, 150)
	_home = Vector2(_tray.position.x + tw / 2.0 - 75.0, _tray.position.y - 190.0)
	_piece.position = _home
	_piece.pivot_offset = Vector2(75, 75)
	add_child(_piece)
	_piece_card = QuiltCard.new()
	_piece_card.radius = 26
	_piece_card.depth = 12
	_piece_card.size = Vector2(150, 150)
	_piece_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_piece.add_child(_piece_card)
	_hint = Ui.title(tr("sew.pickCell"), 40, Palette.CREAM)
	_hint.size = Vector2(w - 160.0, 56)
	_hint.position = Vector2(x0 + 80.0, _home.y - 76.0)
	add_child(_hint)
	_refresh()
	Ui.pop_in(_tray, 0.0, 0.9, 0.35)
	Ui.pop_in(_piece, 0.15, 0.4, 0.45)
	if host:
		host.set_slots_hot(true)
	if dev != "":
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			var fs := Quilt.free_slots()
			var sl := int(Dev.env("SNUG_SLOT")) if Dev.env("SNUG_SLOT") != "" else int(fs[0])
			choose_slot(sl))

func _refresh() -> void:
	_piece_card.fabric = _ci
	_piece_card.fabric_set = _set
	_piece_card.queue_redraw()
	for i in _sw.size():
		_sw[i].fabric_set = _set
		_sw[i].glow = i == _ci
		_sw[i].queue_redraw()
	for sid: String in _set_cards:
		var c: QuiltCard = _set_cards[sid]
		c.glow = sid == _set
		c.fill = Palette.GOLD.lightened(0.55) if sid == _set else Palette.CARD
		c.queue_redraw()
	Ui.punch(_piece, 0.12)

func _pick_fabric(i: int) -> void:
	if _busy or i == _ci:
		return
	_ci = i
	Asmr.hit("felt_pop", "tick", "click", 1.1, -8.0)
	_refresh()

func _pick_set(sid: String) -> void:
	if _busy or sid == _set:
		return
	_set = sid
	Asmr.hit("felt_pop", "light", "click", 0.9, -8.0)
	_refresh()

func cancel() -> void:
	if _busy and _stage and _stage.done:
		return
	if host:
		host.set_slots_hot(false)
		host.hover_slot(-1, "", 0)
	closed.emit()
	queue_free()

# ------------------------------------------------------------------ Yuva seçimi

func piece_dropped(global_center: Vector2) -> void:
	var sl: int = host.slot_at(global_center) if host else -1
	host.hover_slot(-1, "", 0)
	if sl >= 0:
		choose_slot(sl)
	else:
		var tw := create_tween()
		tw.tween_property(_piece, "position", _home, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func piece_moved(global_center: Vector2) -> void:
	if host:
		host.hover_slot(host.slot_at(global_center), _set, _ci)

func choose_slot(slot: int) -> void:
	if _busy or slot < 0 or slot in Quilt.used_slots():
		return
	_busy = true
	_slot = slot
	host.set_slots_hot(false)
	host.hover_slot(-1, "", 0)
	Asmr.hit("felt_pop", "medium", "place")
	var cell: Rect2 = host.slot_rect(slot)
	# Tepsi aşağı kayar, kumaş kare hücreye düşer; sahne hücreye yakınlaşır.
	var tw := create_tween().set_parallel()
	tw.tween_property(_tray, "position:y", size.y + 40.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(_hint, "modulate:a", 0.0, 0.2)
	tw.tween_property(_piece, "modulate:a", 0.0, 0.15)
	var rec: Dictionary = Quilt.pending()[0]
	var patch := Quilt.with_choice(rec, "plain", _set, _ci, _ci)
	_stage = _SewStage.new()
	_stage.size = size
	add_child(_stage)
	var center := Vector2(size.x / 2.0, size.y * 0.47)
	var shade := ColorRect.new()
	shade.color = Color(Palette.DIM, 0.0)
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(shade)
	create_tween().tween_property(shade, "color:a", 0.62, 0.5)
	_stage.setup(patch, SIDE, center, cell)
	_stage.finished.connect(_on_finished)
	var hint := Ui.wrap(Ui.title(tr("sew.drag"), 52, Palette.CREAM), size.x - 160.0)
	Ui.place(hint, Vector2(80, center.y - SIDE / 2.0 - 290.0), Vector2(size.x - 160.0, 150))
	hint.modulate.a = 0.0
	_stage.add_child(hint)
	_stage.hint = hint
	create_tween().tween_property(hint, "modulate:a", 1.0, 0.4).set_delay(0.5)
	var x := Ui.icon_button("ic_close", 100)
	Ui.place(x, Vector2(40, Ui.safe_top() + 30.0), Vector2(100, 100))
	_stage.add_child(x)
	x.tapped.connect(cancel)
	var auto := Ui.button(tr("sew.auto"), "sage", Vector2(560, 120))
	Ui.place(auto, Vector2((size.x - 560.0) / 2.0, size.y - Ui.safe_bottom() - 230.0), Vector2(560, 120))
	_stage.add_child(auto)
	auto.tapped.connect(_stage.start_auto)
	_stage.auto_btn = auto
	Ui.pop_in(auto, 1.0, 0.6)
	_stage.zoom_in()
	if dev == "auto":
		get_tree().create_timer(1.6).timeout.connect(_stage.start_auto)
	elif dev == "mid" or dev == "pierce":
		get_tree().create_timer(1.3).timeout.connect(func() -> void:
			_stage.dev_progress(float(Dev.env("SNUG_PROG")) if Dev.env("SNUG_PROG") != "" else (0.37 if dev == "mid" else 0.0)))

func _on_finished() -> void:
	Quilt.sew_next(_slot, _set, _ci)
	var completed := Quilt.completed_count() > 0 and Quilt.current().is_empty()
	var c := _stage.plate.global_position
	_stage.hint.text = tr("sew.done")
	Ui.pop_in(_stage.hint, 0.0, 0.4)
	_stage.auto_btn.visible = false
	Asmr.hit("felt_pop", "success", "levelUp")
	_fx.puff(c, 14, Palette.CREAM, 34.0)
	_fx.sparks(c, 22, Palette.GOLD, 800.0)
	_fx.ring(c, SIDE * 0.55, Palette.GOLD, 14.0)
	_hearts(c)
	var plate := _stage.plate
	var tw := create_tween()
	tw.tween_property(plate, "scale", Vector2(0.94, 1.05), 0.12)
	tw.tween_property(plate, "scale", Vector2(1.06, 0.96), 0.14)
	tw.tween_property(plate, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: Asmr.hit("scissors", "light"))
	if completed:
		get_tree().create_timer(0.4).timeout.connect(func() -> void:
			_fx.confetti(Vector2(-20, size.y * 0.55), 60, PI * 0.18, -PI * 0.3, 2000.0)
			_fx.confetti(Vector2(size.x + 20, size.y * 0.55), 60, PI * 0.18, -PI * 0.7, 2000.0)
			Sfx.play("levelUp")
			_stage.hint.text = tr("quilt.done"))
		tw.tween_interval(1.9)
		tw.tween_callback(_finish_flow)
		return
	tw.tween_interval(0.5)
	# Yama yuvasına küçülerek oturur (yakınlaşmanın tersi).
	if not Ui.reduce_motion():
		var cell: Rect2 = host.slot_rect(_slot)
		var k := cell.size.x / SIDE
		tw.tween_callback(_stage.zoom_out.bind(cell))
		tw.tween_interval(0.62)
		tw.tween_callback(func() -> void: Asmr.hit("felt_pop", "medium", "place"))
		tw.tween_interval(0.1)
		k += 0.0
	tw.tween_callback(_finish_flow)

func _finish_flow() -> void:
	if on_done.is_valid():
		on_done.call()
	if host:
		host.set_slots_hot(false)
	closed.emit()
	queue_free()

func _hearts(at: Vector2) -> void:
	for i in 9:
		var h := Ui.icon("ic_heart", Vector2(70, 70))
		h.position = at - Vector2(35, 35) + Vector2(randf_range(-260, 260), randf_range(-60, 120))
		h.pivot_offset = Vector2(35, 35)
		h.scale = Vector2.ZERO
		h.rotation = randf_range(-0.4, 0.4)
		add_child(h)
		var tw := h.create_tween()
		tw.tween_interval(i * 0.05)
		tw.tween_property(h, "scale", Vector2.ONE * randf_range(0.7, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(h, "position:y", h.position.y - randf_range(240, 420), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(h, "modulate:a", 0.0, 0.5).set_delay(0.7)
		tw.tween_callback(h.queue_free)

# ------------------------------------------------------------------ Tutulan kumaş kare

class _Piece extends Control:
	var flow: SewFlow
	var _drag := false
	var _grab := Vector2.ZERO
	func _exit_tree() -> void:
		if _drag:
			DragScroll.locked = false
	func _gui_input(e: InputEvent) -> void:
		if e is InputEventScreenTouch:
			if e.pressed:
				_drag = true
				DragScroll.locked = true
				_grab = get_global_mouse_position() - global_position
				scale = Vector2(1.15, 1.15)
				Asmr.hit("felt_pop", "tick", "click", 1.05, -8.0)
			elif _drag:
				_drag = false
				DragScroll.locked = false
				scale = Vector2.ONE
				flow.piece_dropped(global_position + size / 2.0)
			accept_event()
		elif e is InputEventScreenDrag and _drag:
			global_position = get_global_mouse_position() - _grab
			flow.piece_moved(global_position + size / 2.0)
			accept_event()

# ------------------------------------------------------------------ İğne sahnesi

class _SewStage extends Control:
	signal finished
	var patch := {}
	var side := 700.0
	var plate: Control          ## mat + yama; yakınlaşma/küçülme bunu hareket ettirir
	var mat: QuiltCard
	var pv: PatchView
	var overlay: Control
	var hint: Label
	var auto_btn: Control
	var path := PackedVector2Array()
	var cum: Array[float] = []
	var total := 0.0
	var prog := 0.0
	var finger := Vector2.ZERO
	var touching := false
	var live := false
	var auto := false
	var done := false
	var coach := true
	var needle_tex: Texture2D
	var thread_tex: Texture2D
	var dimple_tex: Texture2D
	var ridge_tex: Texture2D
	var _t := 0.0
	var _dash := 0.0
	var _period := 0.0
	var _stitch_id := -1
	var _ev := 0              ## bu dikişte tetiklenen olaylar (1 batış, 2 çıkış, 4 iplik)
	var _last_b := Vector2.ZERO
	var _hit_a := Vector2.ZERO
	var _dimple := 0.0

	func setup(p: Dictionary, sd: float, center: Vector2, cell: Rect2) -> void:
		patch = p
		side = sd
		mouse_filter = Control.MOUSE_FILTER_STOP
		plate = Control.new()
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.position = cell.get_center()
		plate.scale = Vector2.ONE * (cell.size.x / side)
		add_child(plate)
		mat = QuiltCard.new()
		mat.fabric = 10
		mat.radius = 60
		mat.depth = 16
		mat.position = Vector2(-side / 2.0 - 60.0, -side / 2.0 - 60.0)
		mat.size = Vector2(side + 120.0, side + 120.0)
		mat.modulate.a = 0.0
		plate.add_child(mat)
		pv = PatchView.new()
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.show_trim = true
		pv.set_patch(p)
		pv.stitch_in = 0.0
		pv.position = Vector2(-side / 2.0, -side / 2.0)
		pv.size = Vector2(side, side)
		plate.add_child(pv)
		overlay = Control.new()
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.size = size
		overlay.draw.connect(_draw_overlay)
		add_child(overlay)
		var tp := PatchView.trim_path(side)
		var off := center - Vector2(side, side) / 2.0
		cum.append(0.0)
		for i in tp.size():
			path.append(tp[i] + off)
			if i > 0:
				cum.append(cum[i - 1] + path[i - 1].distance_to(path[i]))
		total = cum[cum.size() - 1]
		_dash = maxf(3.0, side * 0.05)
		_period = _dash * 1.7
		coach = not Quilt.tutorial_sew_done()
		# Tüm görseller ChatGPT çizimi (art/quilt/); dosya yoksa o öğe çizilmez.
		needle_tex = load(SewFlow.NEEDLE_PATH) if ResourceLoader.exists(SewFlow.NEEDLE_PATH) else null
		thread_tex = load(SewFlow.THREAD_PATH) if ResourceLoader.exists(SewFlow.THREAD_PATH) else null
		dimple_tex = load(SewFlow.DIMPLE_PATH) if ResourceLoader.exists(SewFlow.DIMPLE_PATH) else null
		ridge_tex = load(SewFlow.RIDGE_PATH) if ResourceLoader.exists(SewFlow.RIDGE_PATH) else null
		_last_b = point_at(0.0)
		set_process(true)

	func zoom_in() -> void:
		var to := Vector2(size.x / 2.0, size.y * 0.47)
		if Ui.reduce_motion():
			plate.position = to
			plate.scale = Vector2.ONE
			mat.modulate.a = 1.0
			live = true
			return
		var tw := create_tween().set_parallel()
		tw.tween_property(plate, "position", to, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(plate, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(mat, "modulate:a", 1.0, 0.4).set_delay(0.2)
		tw.chain().tween_callback(func() -> void:
			Asmr.hit("felt_pop", "light", "place")
			live = true)

	func zoom_out(cell: Rect2) -> void:
		live = false
		var tw := create_tween().set_parallel()
		tw.tween_property(plate, "position", cell.get_center(), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(plate, "scale", Vector2.ONE * (cell.size.x / side), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(mat, "modulate:a", 0.0, 0.3)
		for c in get_children():
			if c is ColorRect:
				tw.tween_property(c, "color:a", 0.0, 0.5)
		if hint:
			tw.tween_property(hint, "modulate:a", 0.0, 0.25)

	func point_at(s: float) -> Vector2:
		s = clampf(s, 0.0, total)
		for i in 4:
			if s <= cum[i + 1] or i == 3:
				var l := cum[i + 1] - cum[i]
				return path[i].lerp(path[i + 1], clampf((s - cum[i]) / l, 0.0, 1.0))
		return path[0]

	func _edge_of(s: float) -> int:
		for i in 4:
			if s <= cum[i + 1]:
				return i
		return 3

	## Dikiş döngüsü durumu: {id, u (0..1 dikiş içinde), a (batış), b (çıkış), phase}
	func cycle(s: float) -> Dictionary:
		var ei := _edge_of(s)
		var t := s - cum[ei]
		var k := int(floor(t / _period))
		var u := (t - k * _period) / _period
		var edge_len := cum[ei + 1] - cum[ei]
		var a_s := cum[ei] + k * _period
		var b_s := minf(a_s + _dash, cum[ei] + edge_len)
		var dfrac := _dash / _period
		var ph := 0
		if u >= 0.14:
			ph = 1
		if u >= dfrac - 0.12:
			ph = 2
		if u >= dfrac:
			ph = 3
		return {"id": ei * 1000 + k, "u": u, "a": point_at(a_s), "b": point_at(b_s), "ph": ph, "dfrac": dfrac}

	func _gui_input(e: InputEvent) -> void:
		if not live or done or auto:
			return
		if e is InputEventScreenTouch:
			touching = e.pressed
			finger = e.position
			if e.pressed:
				_advance()
		elif e is InputEventScreenDrag:
			touching = true
			finger = e.position
			_advance()

	## Parmak hedefi belirler; iğne ona SEW_SPEED hızıyla yetişir (her dikiş hissedilsin diye yavaş).
	var _goal := 0.0
	const SEW_SPEED := 0.26          ## yan uzunluğu / sn (≈ 3 dikiş/sn)

	func _advance() -> void:
		var base := maxf(prog, _goal)
		var best := base
		var s := base
		var lim := minf(total, base + side * 0.3)
		while s <= lim:
			if finger.distance_to(point_at(s)) < side * 0.17:
				best = s
			s += 8.0
		if best > base + 0.5:
			_goal = best

	func move_to(s: float) -> void:
		prog = minf(s, total)
		pv.stitch_in = prog / total
		pv.queue_redraw()
		_events()
		if prog > total * 0.05 and coach:
			coach = false
		if prog >= total - 5.0 and not done:
			done = true
			prog = total
			pv.stitch_in = 1.0
			touching = false
			Asmr.hit("needle_in", "light", "", 0.9, -2.0)
			finished.emit()

	## Batış / çıkış / iplik çekme sesleri + titreşim, dikiş döngüsüne bağlı.
	func _events() -> void:
		var c := cycle(prog)
		if int(c.id) != _stitch_id:
			_stitch_id = int(c.id)
			_ev = 0
			_hit_a = c.a
		var ph := int(c.ph)
		if _ev & 1 == 0:
			_ev |= 1
			Asmr.hit("needle_in", "tick", "", randf_range(0.96, 1.04), -4.0)
			_dimple = 1.0
		if ph >= 2 and _ev & 2 == 0:
			_ev |= 2
			Juice.haptic("tick")   # çıkış: yalnız titreşim, ses yok
			_last_b = c.b
		if ph >= 3 and _ev & 4 == 0:
			_ev |= 4
			pass   # iplik çekme sesi kaldırıldı (hışırtılı)

	func dev_progress(f: float) -> void:
		live = true
		coach = false
		if f > 0.0:
			move_to(total * f)
		else:
			prog = 0.0
		finger = point_at(prog)

	func start_auto() -> void:
		if auto or done or not live:
			return
		auto = true
		coach = false
		if auto_btn:
			auto_btn.visible = false

	func _process(dt: float) -> void:
		_t += dt
		if auto and not done:
			move_to(prog + side * SEW_SPEED * 1.4 * dt)
		elif not done and _goal > prog + 0.5:
			move_to(minf(_goal, prog + side * SEW_SPEED * dt))
		_dimple = maxf(0.0, _dimple - dt * 1.6)
		overlay.queue_redraw()

	func _draw_overlay() -> void:
		if not live:
			return
		var off := plate.position - Vector2(side, side) / 2.0
		if not done:
			var g := PatchView.trim_segments(side, prog, total)
			var pts := PackedVector2Array()
			for q in g:
				pts.append(q + off)
			if pts.size() > 1:
				overlay.draw_multiline(pts, Color(Palette.INK, 0.38), side * 0.03)
				overlay.draw_multiline(pts, Color(Palette.CREAM, 0.7), side * 0.014)
			_draw_needle()
		if coach and not touching and not done:
			_draw_coach()

	func _thread_col() -> Color:
		return pv.trim_color()

	## Kumaş çukuru (ChatGPT dokusu): iğnenin battığı yerde.
	func _draw_dimple(at: Vector2, k: float) -> void:
		if k <= 0.02 or dimple_tex == null:
			return
		var r := side * 0.12 * (0.75 + 0.5 * k)
		overlay.draw_texture_rect(dimple_tex, Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, clampf(k * 1.3, 0.0, 1.0)))

	## Bir iğne parçasını (kuyruk/göz ucu ya da uç) çiz; at = kumaşa giriş/çıkış noktası, gövde yukarı-sola uzanır.
	func _needle_piece(at: Vector2, tail_part: bool, vis: float, lift: float) -> Vector2:
		var len := side * 0.5
		var tsz := needle_tex.get_size()
		var th := len * tsz.y / tsz.x
		var ang := Vector2(0.5, 0.86).normalized().angle()
		var lv := len * vis
		var src := Rect2(0, 0, tsz.x * vis, tsz.y) if tail_part else Rect2(tsz.x * (1.0 - vis), 0, tsz.x * vis, tsz.y)
		var p := at + Vector2(0, -lift * 18.0)
		overlay.draw_set_transform(p + Vector2(10 + lift * 10, 16 + lift * 14), ang, Vector2.ONE)
		overlay.draw_texture_rect_region(needle_tex, Rect2(-lv, -th / 2.0, lv, th), src, Color(0, 0, 0, 0.28))
		overlay.draw_set_transform(p, ang, Vector2.ONE)
		overlay.draw_texture_rect_region(needle_tex, Rect2(-lv, -th / 2.0, lv, th), src)
		overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return p - Vector2(0.5, 0.86).normalized() * (lv - len * 0.06)   # göz konumu

	## Kumaş altından geçen iğnenin kabarık sırtı: a→b boyunca uzanan ChatGPT kıvrım dokusu.
	func _draw_ridge(a: Vector2, b: Vector2, k: float) -> void:
		if ridge_tex == null or k <= 0.02:
			return
		var d := b - a
		var l := maxf(d.length(), side * 0.07)
		var w := side * 0.15
		var dir := d.normalized() if d.length() > 0.5 else Vector2.RIGHT
		overlay.draw_set_transform(a - dir * side * 0.02, dir.angle(), Vector2.ONE)
		overlay.draw_texture_rect(ridge_tex, Rect2(0, -w / 2.0, l + side * 0.04, w), false, Color(1, 1, 1, clampf(k, 0.0, 1.0)))
		overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_needle() -> void:
		var c := cycle(prog)
		var u: float = c.u
		var ph: int = c.ph
		var dfrac: float = c.dfrac
		var cur := point_at(prog)
		var A: Vector2 = c.a
		var B: Vector2 = c.b
		var thread_from: Vector2 = A
		var sag := 10.0
		var to: Vector2 = point_at(maxf(0.0, prog - _period * 0.6))
		if _ev & 2 != 0 and ph >= 2:
			to = _last_b
		_draw_dimple(A if ph <= 2 else Vector2.ZERO, 1.0 if ph <= 1 else 0.7 if ph == 2 else 0.0)
		if ph >= 2:
			_draw_dimple(B, maxf(0.5, _dimple))
		if needle_tex == null:
			_draw_thread(A, to, 20.0)
			return
		match ph:
			0:
				var m := clampf(u / 0.14, 0.0, 1.0)
				thread_from = _needle_piece(A, true, lerpf(1.0, 0.33, ease(m, 1.6)), 0.0)
			1:
				_draw_ridge(A, cur, 1.0)
				var bob := 0.015 * sin(_t * 9.0)
				thread_from = _needle_piece(A, true, 0.33 + bob, 0.0)
			2:
				var m2 := clampf((u - (dfrac - 0.12)) / 0.12, 0.0, 1.0)
				_draw_ridge(A, B, 1.0 - m2)
				var ev := 0.33 * (1.0 - ease(m2, 1.5))
				if ev > 0.03:
					thread_from = _needle_piece(A, true, ev, 0.0)
				else:
					thread_from = B
				_needle_piece(B, false, ease(m2, 0.6), 0.0)
				sag = 40.0
			3:
				var lf := sin(clampf((u - dfrac) / (1.0 - dfrac), 0.0, 1.0) * PI)
				thread_from = _needle_piece(cur, true, 1.0, lf)
				sag = 70.0 * (1.0 - clampf((u - dfrac) / (1.0 - dfrac), 0.0, 1.0))
		_draw_thread(thread_from, to, sag)

	## İplik: ChatGPT iplik dokusu, eğri boyunca döşenmiş eğik parçalar (dokusu yoksa çizilmez).
	func _draw_thread(a: Vector2, b: Vector2, sag: float) -> void:
		if thread_tex == null:
			return
		var mid := (a + b) / 2.0 + Vector2(-sag * 0.35, sag)
		var pts: Array[Vector2] = []
		for i in 25:
			var t := i / 24.0
			pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
		var tsz := thread_tex.get_size()
		var th := 16.0
		var k := tsz.x / 360.0          ## doku pikseli / dünya pikseli (büküm sıklığı sabit)
		var dist := 0.0
		for i in pts.size() - 1:
			var d := pts[i + 1] - pts[i]
			var l := d.length()
			if l < 0.5:
				continue
			var sx := fmod(dist * k, tsz.x * 0.6)
			var src := Rect2(sx, 0, minf(l * k + 2.0, tsz.x * 0.4), tsz.y)
			overlay.draw_set_transform(pts[i] + Vector2(2, 4), d.angle(), Vector2.ONE)
			overlay.draw_texture_rect_region(thread_tex, Rect2(0, -th / 2.0, l + 1.0, th), src, Color(0, 0, 0, 0.3))
			overlay.draw_set_transform(pts[i], d.angle(), Vector2.ONE)
			overlay.draw_texture_rect_region(thread_tex, Rect2(0, -th / 2.0, l + 1.0, th), src, _thread_col().lerp(Color.WHITE, 0.45))
			dist += l
		overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_coach() -> void:
		var hand := UiArt.tex("ic_hand")
		var u := fmod(_t * 0.5, 1.0)
		var m := clampf((u - 0.12) / 0.7, 0.0, 1.0)
		var p := point_at(ease(m, -2.0) * side * 0.55)
		var fade := clampf(minf(u, 1.0 - u) * 8.0, 0.0, 1.0)
		var pressing := u > 0.08 and u < 0.85
		if pressing:
			overlay.draw_circle(p, 34.0 + 8.0 * sin(_t * 10.0), Color(1, 1, 1, 0.35 * fade))
		if hand:
			var w := 170.0 * (0.9 if pressing else 1.0)
			var h := w * hand.get_height() / hand.get_width()
			overlay.draw_texture_rect(hand, Rect2(p - Vector2(w * 0.15, h * 0.05), Vector2(w, h)), false, Color(1, 1, 1, fade))
