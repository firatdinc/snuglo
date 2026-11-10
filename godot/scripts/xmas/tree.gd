extends XmasGame
## Noel mini oyunu: Keçe ağacı süsle. Süs tepsisinden sürükle, ağaca bırak; ışıklar, tepe yıldızı.
## state: items [{k,x,y}] (ağaca göre 0..1), lights, star. Çizimler tree_art.gd'de.

const Art := preload("res://scripts/xmas/tree_art.gd")
const TRAY_H := 290.0
const SLOT_W := 176.0
const ORDER: Array[String] = Xmas.ORN_ORDER   # ilk 4 açık; sonrası advent günü / her 4. bölüm hediyesi / düğmeyle
const PENTA := [1.0, 1.125, 1.25, 1.5, 1.667, 2.0]

var tr_rect := Rect2()
var tray_rect := Rect2()
var board: Control
var tree_view: Control
var lights: Art.Lights
var hang: Control
var tray_clip: Control
var tray_content: Control
var drag_layer: Control
var slots: Array = []        # {kind, orn}
var placed: Array = []       # Orn
var star_orn: Art.Orn = null
var lights_btn: JuicyButton
var tray_scroll := 0.0
var scroll_vel := 0.0

var mode := ""               # "" | pending | scroll | drag
var press := Vector2.ZERO
var press_scroll := 0.0
var press_kind := ""
var press_orn: Art.Orn = null
var drag: Art.Orn = null
var reset_ready := false
var light_mode := false
var light_paths: Array = []   # [[ [x,y]... ]] ağaca göre 0..1
var cur_path: Array = []
var last_drag_p := Vector2.ZERO

func _init() -> void:
	super()
	GAME = "tree"
	BG_SCENE = "lake"            # ağaçsız-merkez kış sahnesi (arka planda ikinci ağaç olmasın)
	BG_WASH = Vector2(0.55, 0.5)
	TITLE_KEY = "xmas.tree.title"

func unlock_day(kind: String) -> int:
	return Xmas.orn_unlock_day(kind)

func unlocked(kind: String) -> bool:
	return Xmas.orn_open(kind)

func setup_game(r: Rect2) -> void:
	tray_rect = Rect2(r.position.x, r.end.y - TRAY_H - 6.0, r.size.x, TRAY_H)
	var btn_y := tray_rect.position.y - 132.0
	var th := btn_y - r.position.y - 46.0
	var tw := minf(r.size.x * 0.94, th * 0.78)
	th = tw / 0.78 if tw / 0.78 < th else th
	tr_rect = Rect2(Vector2(r.position.x + (r.size.x - tw) / 2.0, btn_y - 6.0 - th), Vector2(tw, th))

	board = Control.new()
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.position = area.position
	board.size = area.size
	board.gui_input.connect(_input_board)
	add_child(board)

	tree_view = Art.TreeView.new()
	put(tree_view, tr_rect.position, tr_rect.size)
	lights = Art.Lights.new()
	put(lights, tr_rect.position, tr_rect.size)
	lights.visible = false
	lights.stepped.connect(_light_step)
	hang = Control.new()
	hang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(hang, tr_rect.position, tr_rect.size)

	_build_tray()
	_build_buttons(btn_y, r)
	drag_layer = Control.new()
	drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_layer.size = size
	add_child(drag_layer)

	_load_state()
	if Dev.env("SNUG_TRAY_SCROLL") != "":
		_set_scroll(-float(Dev.env("SNUG_TRAY_SCROLL")))
	var auto := Dev.env("SNUG_TREE_AUTO")
	if auto != "":
		get_tree().create_timer(0.7).timeout.connect(_auto.bind(auto))

func _process(dt: float) -> void:
	if mode == "" and absf(scroll_vel) > 5.0:
		_set_scroll(tray_scroll + scroll_vel * dt)
		scroll_vel *= pow(0.02, dt)

# ---------- kurulum ----------

func _build_tray() -> void:
	var panel := TrayPanel.new()
	put(panel, tray_rect.position, tray_rect.size)
	var hint := Ui.label(tr("xmas.tree.hint"), 28, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var plate := HintPlate.new()
	var pw := minf(hint.get_minimum_size().x + 70.0, tray_rect.size.x - 20.0)
	put(plate, tray_rect.position + Vector2((tray_rect.size.x - pw) / 2.0, 6), Vector2(pw, 54))
	put(hint, tray_rect.position + Vector2(0, 14), Vector2(tray_rect.size.x, 40))
	tray_clip = Control.new()
	tray_clip.clip_contents = true
	tray_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(tray_clip, tray_rect.position + Vector2(10, 4), tray_rect.size - Vector2(20, 8))
	tray_content = Control.new()
	tray_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray_clip.add_child(tray_content)
	for i in ORDER.size():
		var k := ORDER[i]
		var o := Art.Orn.new(k)
		o.hanging = false
		o.locked = not unlocked(k)
		o.position = Vector2(SLOT_W * i + (SLOT_W - Art.BOX) / 2.0 + 16.0, 78.0)
		tray_content.add_child(o)
		var slot := {"kind": k, "orn": o, "price": null}
		if o.locked:
			slot.price = _price_chip(o.position.x + Art.BOX / 2.0)
		slots.append(slot)
	tray_content.size = Vector2(SLOT_W * ORDER.size() + 32.0, tray_rect.size.y)

## Kilitli süsün altında düğme fiyatı rozeti.
func _price_chip(cx: float) -> Control:
	var chip := Control.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := 150.0
	chip.size = Vector2(w, 46)
	chip.position = Vector2(cx - w / 2.0, 78.0 + Art.BOX + 4.0)
	var bg := Art.PriceTag.new()
	bg.size = chip.size
	chip.add_child(bg)
	var ic := Ui.icon("coin", Vector2(34, 34))
	ic.position = Vector2(16, 6)
	chip.add_child(ic)
	var l := Ui.label(str(Xmas.ORN_PRICE), 30, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(50, 2)
	l.size = Vector2(90, 42)
	chip.add_child(l)
	tray_content.add_child(chip)
	return chip

func _build_buttons(y: float, r: Rect2) -> void:
	lights_btn = Ui.button(tr("xmas.tree.lights"), "mustard", Vector2(440, 120), "", 46)
	put(lights_btn, Vector2(r.position.x + 30.0, y), Vector2(440, 120))
	lights_btn.tapped.connect(_toggle_lights)
	var rb := Ui.button(tr("xmas.tree.reset"), "terracotta", Vector2(360, 120), "", 42)
	put(rb, Vector2(r.end.x - 390.0, y), Vector2(360, 120))
	rb.tapped.connect(_reset_tapped)

func _load_state() -> void:
	for it in state.get("items", []):
		var k := str(it.get("k", ""))
		if ORDER.has(k) and k != "star_top":
			_hang_at(k, Vector2(float(it.get("x", 0.5)), float(it.get("y", 0.5))), false)
	if bool(state.get("star", false)):
		_hang_at("star_top", Vector2(0.5, 0.045), false)
	var lp: Array = state.get("light_paths", [])
	for path in lp:
		lights.stroke_begin(Vector2(path[0][0], path[0][1]) * tr_rect.size)
		for q in path:
			lights.stroke_add(Vector2(q[0], q[1]) * tr_rect.size, true)
		light_paths.append(path)
	if bool(state.get("lights", false)) and lp.is_empty():
		lights.visible = true      # eski kayıt: otomatik sarkan zincir
		lights.build(tr_rect.size)
		lights.start(true)
	elif not lp.is_empty():
		lights.visible = true
	_refresh_star_slot()
	_progress()

# ---------- giriş ----------

func _input_board(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = e.position + board.position
		if e.pressed:
			_press(p)
		else:
			_release(p)
	elif e is InputEventMouseMotion and mode != "":
		_motion(e.position + board.position, e.relative)

func _slot_at(p: Vector2) -> int:
	if not tray_rect.has_point(p):
		return -1
	var gx := p.x - (tray_rect.position.x + 10.0) - tray_scroll
	var i := int(gx / SLOT_W)
	return i if i >= 0 and i < slots.size() else -1

func _press(p: Vector2) -> void:
	press = p
	press_scroll = tray_scroll
	scroll_vel = 0.0
	press_orn = null
	press_kind = ""
	mode = ""
	if light_mode and tr_rect.has_point(p) and not tray_rect.has_point(p):
		_light_begin(p)
		return
	if tray_rect.has_point(p):
		var i := _slot_at(p)
		mode = "pending"
		if i >= 0:
			press_kind = slots[i].kind
		return
	for i in range(placed.size() - 1, -1, -1):
		var o: Art.Orn = placed[i]
		var c := o.position + hang.position + Art.anchor(o.kind) + Vector2(0, 0 if o.kind == "star_top" else 74)
		if c.distance_to(p) < 62.0:
			press_orn = o
			mode = "pending"
			press_kind = o.kind
			return

func _motion(p: Vector2, rel: Vector2) -> void:
	if mode == "pending":
		var d := p - press
		if d.length() < 14.0:
			return
		var from_tray := tray_rect.has_point(press)
		if from_tray and press_orn == null:
			if press_kind != "" and unlocked(press_kind) and d.y < -12.0 and absf(d.y) > absf(d.x) * 0.8 \
					and not (press_kind == "star_top" and star_orn != null):
				_begin_drag(p)
			else:
				mode = "scroll"
		else:
			_begin_drag(p)
	elif mode == "scroll":
		_set_scroll(press_scroll + (p.x - press.x))
		scroll_vel = rel.x * 60.0
	elif mode == "drag":
		_drag_to(p)
	elif mode == "light":
		_light_to(p)

func _release(p: Vector2) -> void:
	var m := mode
	mode = ""
	if m == "light":
		_light_end()
		return
	if m == "drag":
		_drop(p)
	elif m == "pending":
		if press_orn == null and press_kind != "" and not unlocked(press_kind):
			_tap_slot(press_kind)

func _set_scroll(v: float) -> void:
	var mn := minf(0.0, tray_clip.size.x - tray_content.size.x)
	tray_scroll = clampf(v, mn, 0.0)
	tray_content.position.x = tray_scroll

func _tap_slot(kind: String) -> void:
	Juice.haptic("tick")
	Main.confirm(tr("xmas.orn.buyTitle"), tr("xmas.orn.buyMsg") % [Xmas.ORN_PRICE, unlock_day(kind)], tr("xmas.orn.buyOk") % Xmas.ORN_PRICE, func() -> void: _buy_orn(kind))

func _buy_orn(kind: String) -> void:
	if unlocked(kind):
		return
	if not Xmas.orn_buy(kind):
		Juice.haptic("error")
		Main.toast(tr("xmas.cookie.noCoins"), "ic_coin", Palette.TERRACOTTA)
		return
	for s in slots:
		if s.kind == kind:
			s.orn.locked = false
			s.orn.queue_redraw()
			if s.price is Control:
				s.price.queue_free()
				s.price = null
			var sp := Art.Spark.new()
			sp.size = Vector2.ONE
			tray_content.add_child(sp)
			sp.burst(s.orn.position + Vector2(Art.BOX, Art.BOX) / 2.0)
	Asmr.hit("chime", "success", "reward", 1.3)

# ---------- sürükleme ----------

func _drag_off(kind: String) -> Vector2:
	return Vector2(0, -90) if kind == "star_top" else Vector2(0, -130)

func _begin_drag(p: Vector2) -> void:
	mode = "drag"
	if press_orn != null:
		drag = press_orn
		placed.erase(drag)
		if drag == star_orn:
			star_orn = null
		var gp := drag.position + hang.position
		hang.remove_child(drag)
		drag_layer.add_child(drag)
		drag.position = gp
		drag.rotation = 0.0
		_sync()
	else:
		drag = Art.Orn.new(press_kind)
		drag_layer.add_child(drag)
		if press_kind == "star_top":
			_refresh_star_slot(true)
	var tw := create_tween()
	drag.scale = Vector2.ONE * 0.9
	tw.tween_property(drag, "scale", Vector2.ONE * 1.12, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Asmr.hit("rustle", "tick", "click", 1.0, -6.0)
	Asmr.reset_stroke(self, "drag")
	last_drag_p = p
	_drag_to(p)

func _drag_to(p: Vector2) -> void:
	last_drag_p = p
	if drag:
		drag.position = p + _drag_off(drag.kind) - Art.anchor(drag.kind)

func _attach_norm(p: Vector2, kind: String) -> Vector2:
	return (p + _drag_off(kind) - tr_rect.position) / tr_rect.size

func _drop(p: Vector2) -> void:
	var o := drag
	drag = null
	Asmr.reset_stroke(self, "drag")
	var is_new := press_orn == null   # raftan yeni süs (taşıma değil)
	var n := _attach_norm(p, o.kind)
	if o.kind == "star_top":
		var apex := tr_rect.position + Vector2(tr_rect.size.x * 0.5, tr_rect.size.y * 0.045)
		if (p + _drag_off(o.kind)).distance_to(apex) < tr_rect.size.y * 0.24:
			o.queue_free()
			_hang_at("star_top", Vector2(0.5, 0.045), true)
			_after_star(true)
			if is_new:
				Xmas.task_event("tree")
			return
	elif Art.in_tree(n):
		n.y = clampf(n.y, 0.12, 0.88)
		var hw := Art.max_hw(n.y) * 0.95
		n.x = clampf(n.x, 0.5 - hw, 0.5 + hw)
		o.queue_free()
		_hang_at(o.kind, n, true)
		if is_new:
			Xmas.task_event("tree")
		return
	_glide_home(o)

func _glide_home(o: Art.Orn) -> void:
	var i := ORDER.find(o.kind)
	var home := tray_rect.position + Vector2(10.0 + tray_scroll + SLOT_W * i + 16.0 + (SLOT_W - Art.BOX) / 2.0, 82.0)
	home.x = clampf(home.x, tray_rect.position.x, tray_rect.end.x - Art.BOX)
	var tw := create_tween().set_parallel()
	tw.tween_property(o, "position", home, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(o, "scale", Vector2.ONE * 0.9, 0.4)
	tw.chain().tween_callback(o.queue_free)
	tw.chain().tween_callback(_refresh_star_slot)
	Asmr.hit("rustle", "", "click", 0.9, -4.0)
	_sync()

# ---------- yerleştirme ----------

func _hang_at(kind: String, n: Vector2, animate: bool) -> Art.Orn:
	var o := Art.Orn.new(kind)
	o.nx = n.x
	o.ny = n.y
	hang.add_child(o)
	o.position = n * tr_rect.size - Art.anchor(kind)
	placed.append(o)
	if kind == "star_top":
		star_orn = o
	if animate:
		o.scale = Vector2(1.25, 0.8)
		var tw := create_tween()
		tw.tween_property(o, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		if not Ui.reduce_motion():
			var tw2 := create_tween()
			tw2.tween_method(func(t: float) -> void: o.rotation = 0.32 * sin(t * 9.0) * exp(-t * 2.4) * (1.0 if kind != "star_top" else 0.2), 0.0, 2.4, 2.4)
		Asmr.hit("felt_pop", "light", "place", randf_range(0.92, 1.1))
		_sync()
		_refresh_star_slot()
	return o

func _after_star(first: bool) -> void:
	if not first or star_orn == null:
		return
	var gp := tr_rect.position + Vector2(tr_rect.size.x * 0.5, tr_rect.size.y * 0.06)
	var sp := Art.Spark.new()
	sp.size = size
	add_child(sp)
	sp.burst(gp, 22)
	Sfx.play("reward")
	XmasKit.asmr("jingle", "levelUp")
	Juice.haptic("success")
	var fx := Fx.new()
	add_child(fx)
	fx.confetti(gp, 90)
	get_tree().create_timer(4.0).timeout.connect(fx.queue_free)
	var l := Ui.label(tr("xmas.tree.ready"), 84, Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	put(l, Vector2(area.position.x, tr_rect.position.y + tr_rect.size.y * 0.4), Vector2(area.size.x, 110))
	Ui.pop_in(l, 0.1)
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

func _free_spot() -> Vector2:
	var best := Vector2(0.5, 0.5)
	var bd := -1.0
	for a in 12:
		var y := randf_range(0.18, 0.82)
		var hw := Art.max_hw(y) * 0.8
		var n := Vector2(0.5 + randf_range(-hw, hw), y)
		var md := 9.0
		for o: Art.Orn in placed:
			md = minf(md, (Vector2(o.nx, o.ny) - n).length())
		if md > bd:
			bd = md
			best = n
	return best

func _refresh_star_slot(force := false) -> void:
	for s in slots:
		if s.kind == "star_top":
			s.orn.ghost = star_orn != null or force
			s.orn.queue_redraw()

func _sync() -> void:
	var arr: Array = []
	for o: Art.Orn in placed:
		if o.kind != "star_top":
			arr.append({"k": o.kind, "x": snappedf(o.nx, 0.001), "y": snappedf(o.ny, 0.001)})
	state.items = arr
	state.star = star_orn != null
	state.light_paths = light_paths
	state.lights = not light_paths.is_empty() or (lights.visible and lights.bulbs.size() > 0)
	_progress()

func _progress() -> void:
	var n := (state.get("items", []) as Array).size()
	var ms := mini(n / 4, 6)
	if ms > int(state.get("ing_ms", 0)):
		var gained := ms - int(state.get("ing_ms", 0))
		state.ing_ms = ms
		Xmas.add_ingredients({"flour": gained, "sugar": gained})
	set_progress(minf(1.0, (n + (3 if bool(state.get("lights", false)) else 0) + (3 if bool(state.get("star", false)) else 0)) / 24.0))

# ---------- ışıklar ----------

func _toggle_lights() -> void:
	light_mode = not light_mode
	lights_btn.modulate = Color(1.0, 1.0, 0.72) if light_mode else Color.WHITE
	lights_btn.scale = Vector2.ONE
	Asmr.hit("twinkle", "light", "tick")
	if light_mode:
		var tw := create_tween().set_loops(0)
		tw.tween_property(lights_btn, "modulate", Color(1.0, 0.92, 0.45), 0.7)
		tw.tween_property(lights_btn, "modulate", Color(1.0, 1.0, 0.8), 0.7)
		lights_btn.set_meta("pulse", tw)
		_light_coach()
	elif lights_btn.has_meta("pulse"):
		(lights_btn.get_meta("pulse") as Tween).kill()
		lights_btn.modulate = Color.WHITE
	if not light_mode:
		_light_coach_end(false)

func _light_begin(p: Vector2) -> void:
	_light_coach_end(true)
	mode = "light"
	cur_path = []
	lights.visible = true
	Asmr.reset_stroke(self, "light")
	last_drag_p = p
	var lp := p - tr_rect.position
	lights.stroke_begin(lp)
	cur_path.append([snappedf(lp.x / tr_rect.size.x, 0.001), snappedf(lp.y / tr_rect.size.y, 0.001)])
	_light_to(p)

func _light_to(p: Vector2) -> void:
	var n := (p - tr_rect.position) / tr_rect.size
	if not Art.in_tree(n):
		return
	var lp := p - tr_rect.position
	var b := lights.stroke_add(lp)
	if cur_path.is_empty() or Vector2(cur_path[-1][0], cur_path[-1][1]).distance_to(n) > 0.012:
		cur_path.append([snappedf(n.x, 0.001), snappedf(n.y, 0.001)])
	if b.x >= 0.0:
		var i: int = lights.strokes[-1].bulbs.size()
		Asmr.hit("twinkle", "tick", "tick", PENTA[i % PENTA.size()], -4.0)

func _light_end() -> void:
	lights.stroke_end()
	if cur_path.size() >= 2:
		light_paths.append(cur_path)
	elif not lights.strokes.is_empty() and lights.strokes[-1].pts.size() < 2:
		pass
	cur_path = []
	_sync()

# Mini eğitim: ışık modu ilk açılışta el ağaç üzerinde sarkan bir zincir çizer.
var coach: LightCoach

func _light_coach() -> void:
	if bool(state.get("tut_lights", false)) or Dev.env("SNUG_NO_TUT") != "" or coach != null:
		return
	coach = LightCoach.new()
	coach.path = PackedVector2Array()
	var y0 := tr_rect.position.y + tr_rect.size.y * 0.46
	var cx := tr_rect.position.x + tr_rect.size.x * 0.5
	var hw := tr_rect.size.x * Art.max_hw(0.46) * 0.8
	for i in 41:
		var u := i / 40.0
		coach.path.append(Vector2(cx - hw + 2.0 * hw * u, y0 + tr_rect.size.y * 0.06 * sin(u * PI)))
	coach.size = size
	add_child(coach)
	var b := Art.Bubble.new()
	b.setup(tr("xmas.tree.lightsTut"))
	b.position = Vector2(cx - b.size.x / 2.0, y0 - b.size.y - 150.0)
	coach.add_child(b)
	Ui.pop_in(b, 0.0, 0.6, 0.3)

func _light_coach_end(learned: bool) -> void:
	if learned and not bool(state.get("tut_lights", false)):
		state["tut_lights"] = true
		_sync()
	if coach != null:
		var c := coach
		coach = null
		var tw := c.create_tween()
		tw.tween_property(c, "modulate:a", 0.0, 0.25)
		tw.tween_callback(c.queue_free)

class LightCoach extends Control:
	var path: PackedVector2Array
	var t := 0.0
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(dt: float) -> void:
		t += dt
		queue_redraw()
	func _draw() -> void:
		var cyc := 2.6
		var u := fmod(t, cyc) / cyc
		var m := clampf((u - 0.12) / 0.66, 0.0, 1.0)
		var fade := clampf(minf(u, 1.0 - u) * 9.0, 0.0, 1.0)
		var n := int(m * (path.size() - 1))
		if n >= 1:
			var seg := path.slice(0, n + 1)
			Art.cord(self, seg, 12.0, Color(1, 1, 1, 0.6 * fade))
			for k in range(4, n + 1, 13):
				var bt := Art.tex("tree_bulb_%d" % ((k / 13) % 4))
				if bt:
					var h := 80.0
					var w := h * bt.get_width() / bt.get_height()
					draw_texture_rect(bt, Rect2(path[k] + Vector2(-w / 2.0, -6), Vector2(w, h)), false, Color(1, 1, 1, 0.8 * fade))
		var p := path[n]
		var press := u > 0.1 and u < 0.8
		if press:
			draw_circle(p, 34.0 + 8.0 * sin(t * 10.0), Color(1, 1, 1, 0.35 * fade))
		var hand := UiArt.tex("ic_hand")
		if hand:
			var w := 170.0 * (0.9 if press else 1.0)
			var h := w * hand.get_height() / hand.get_width()
			draw_texture_rect(hand, Rect2(p - Vector2(w * 0.15, h * 0.05), Vector2(w, h)), false, Color(1, 1, 1, fade))

func _light_step(i: int) -> void:
	if i % 2 == 0:
		XmasKit.asmr("twinkle", "tick", PENTA[(i / 2) % PENTA.size()], -4.0)
	if i == lights.bulbs.size() - 1:
		XmasKit.asmr("chime", "snap", 1.0)

# ---------- balon / sıfırla ----------

func _bubble(kind: String) -> void:
	var b := Art.Bubble.new()
	var ut := tr("xmas.tree.unlock")
	b.setup(ut % unlock_day(kind) if "%" in ut else "%s %d" % [ut, unlock_day(kind)])
	var i := ORDER.find(kind)
	var cx := tray_rect.position.x + 10.0 + tray_scroll + SLOT_W * (i + 0.5) + 16.0
	b.position = Vector2(clampf(cx - b.size.x / 2.0, tray_rect.position.x, tray_rect.end.x - b.size.x), tray_rect.position.y - b.size.y + 8.0)
	add_child(b)
	Ui.pop_in(b, 0.0, 0.6, 0.3)
	var tw := create_tween()
	tw.tween_interval(1.7)
	tw.tween_property(b, "modulate:a", 0.0, 0.4)
	tw.tween_callback(b.queue_free)

func _reset_tapped() -> void:
	if not state.get("items", []).is_empty() or lights.visible or star_orn != null or not light_paths.is_empty():
		Main.confirm(tr("xmas.tree.resetTitle"), tr("xmas.tree.resetMsg"), tr("xmas.tree.resetOk"), _do_reset, true)

func _do_reset() -> void:
	for o: Art.Orn in placed:
		o.queue_free()
	placed.clear()
	star_orn = null
	lights.visible = false
	lights.strokes.clear()
	lights.wire.clear()
	lights.bulbs.clear()
	light_paths.clear()
	state.erase("light_paths")
	_refresh_star_slot()
	_sync()

# ---------- debug ----------

func _auto(mode_s: String) -> void:
	if mode_s == "7":
		_auto_slow()
		return
	if mode_s == "6":
		_toggle_lights()
		return
	for k in ["ball_red", "ball_gold", "ball_green", "ball_blue", "ball_red", "bell", "candy_cane", "gingerbread_orn", "snowflake_orn", "bow_orn", "heart_orn", "ball_pink", "ball_gold", "ball_green", "ball_blue"]:
		if unlocked(k):
			_hang_at(k, _free_spot(), true)
	if mode_s == "5":
		_auto_drag()
		return
	if mode_s != "2":
		_auto_lights()
		_hang_at("star_top", Vector2(0.5, 0.045), true)
		_after_star(true)
	if mode_s == "3":
		_bubble("bow_orn")

class HintPlate extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		Art.nine(self, "tree_bubble", Rect2(Vector2.ZERO, size), Vector4(90, 90, 90, 90), 0.22)

class TrayPanel extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	func _draw() -> void:
		Art.nine(self, "tree_tray", Rect2(Vector2.ZERO, size), Vector4(70, 60, 70, 60), 0.5, true)

func _auto_lights() -> void:
	light_mode = true
	for k in 2:
		var y0 := tr_rect.position.y + tr_rect.size.y * (0.35 + 0.22 * k)
		var cx := tr_rect.position.x + tr_rect.size.x * 0.5
		var hw := tr_rect.size.x * 0.2
		_press(Vector2(cx - hw, y0))
		for i in 41:
			var u := i / 40.0
			_motion(Vector2(cx - hw + 2.0 * hw * u, y0 + 40.0 * sin(u * PI)), Vector2.ZERO)
		_release(Vector2(cx + hw, y0))
	light_mode = false

## Reklam kaydı (yalnız debug): süsler tepsiden tek tek uçup asılır, sonra ışık ve yıldız.
func _auto_slow() -> void:
	var seq := ["ball_red", "ball_gold", "candy_cane", "ball_green", "heart_orn", "bell", "ball_blue", "snowflake_orn", "bow_orn", "ball_pink", "gingerbread_orn", "ball_red", "ball_gold", "ball_green"]
	for k: String in seq:
		if not unlocked(k):
			continue
		var i := ORDER.find(k)
		var n := _free_spot()
		var o := Art.Orn.new(k)
		o.hanging = false
		drag_layer.add_child(o)
		o.position = tray_rect.position + Vector2(10.0 + tray_scroll + SLOT_W * maxi(i, 0) + 16.0 + (SLOT_W - Art.BOX) / 2.0, 82.0)
		var to := tr_rect.position + n * tr_rect.size - Art.anchor(k)
		Asmr.hit("rustle", "", "click", 0.9, -4.0)
		var tw := create_tween()
		tw.tween_property(o, "position", to, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tw.finished
		o.queue_free()
		_hang_at(k, n, true)
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.3).timeout
	_auto_lights()
	await get_tree().create_timer(0.8).timeout
	_hang_at("star_top", Vector2(0.5, 0.045), true)
	_after_star(true)

func _auto_drag() -> void:
	var from := tray_rect.position + Vector2(10.0 + SLOT_W * 0.5 + 16.0, 150.0)
	for k in 3:
		var to := tr_rect.position + tr_rect.size * Vector2(0.4 + 0.1 * k, 0.4 + 0.15 * k) + Vector2(0, 130)
		_press(from + Vector2(SLOT_W * k, 0))
		_motion(from + Vector2(SLOT_W * k, -40), Vector2.ZERO)
		_motion(to, Vector2.ZERO)
		_release(to)
