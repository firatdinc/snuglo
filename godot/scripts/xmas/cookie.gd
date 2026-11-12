extends XmasGame
## Noel mini oyunu: Kurabiye pişir ve süsle. 5 adım: karıştır, aç, kes, pişir, süsle (+ tabak).
## Kaybetme / yanma / süre baskısı yok. Çizim: cookie_art.gd (prosedürel keçe).

const Art = preload("res://scripts/xmas/cookie_art.gd")
const MAX_COOKIES := 8
const MIN_COOKIES := 3
const MIX_TURNS := 4.0
const ROLL_TOTAL := 2100.0
const COOKIE_S := 190.0
var DOUGH_W := 860.0   ## partiye göre (1: %72, 2: %86, 3: %100) — _apply_batches
var DOUGH_H := 640.0
const TRAY_TABLE := 1.12                 ## tezgâhtaki tepsi ölçeği (büyük, net)
const TRAY_BED := Rect2(-0.31, -0.33, 0.62, 0.66)  ## tray.png iç tabanı (tepsi ölçüsüne oran)

## ---- GÖRSEL YERLEŞİM SABİTLERİ (art/xmas/cookie/ görselleri gelince buradan ayarla) ----
const IMG := "res://art/xmas/cookie/"
const SHAPE_NAMES := ["star", "tree", "heart", "man", "bell"]
const BOWL_W := 760.0                    ## bowl_back/front görsel genişliği (px); iç ağız = bowl_r
const OVEN_C_Y := 0.47                   ## fırın merkezi: stage yüksekliği oranı
const OVEN_IMG := Vector2(940, 955)      ## oven_closed/open görsel boyutu (merkez = oven_c)
const OVEN_WIN := Rect2(-325, -45, 651, 340)  ## fırın penceresi/ağzı (oven_c'ye göre); PNG'de bu alan ŞEFFAF
const OVEN_SHELF := Vector2(0, 112)       ## tepsinin içerideki merkezi (oven_c'ye göre) — orta raf üstünde
const OVEN_INNER := Rect2(140, 335, 660, 355)  ## oven_open.png'de iç hazne (940 gen. ölçekte) → kapalı camda çizilir
const TRAY_SIZE := Vector2(880, 560)     ## tray.png çizim boyutu (tezgâhta)
const TRAY_IN := 0.6                     ## içerideki perspektif ölçeği
const MITT_SIZE := 360.0                 ## oven_mitt.png genişliği
const PLATE_IMG_K := 2.08                ## plate.png genişliği = plate_r * bu
const CUTTER_SIZE := 130.0
const BAG_SIZE := 170.0
const KNOB_TEMP := Vector2(-225, -317)   ## sıcaklık düğmesi merkezi (oven_c'ye göre; knob_temp.png + dial_temp_face.png)
const KNOB_TIMER := Vector2(233, -317)   ## zamanlayıcı düğmesi merkezi (knob_timer.png)
const KNOB_SIZE := 214.0                 ## düğme görseli genişliği
const DIAL_SIZE := 230.0                 ## dial_temp_face.png genişliği (düğmenin arkasında, aynı merkez)
const KNOB_HIT := 105.0
const LIGHT_POS := Vector2(3, -317)      ## oven_light.png merkezi (oven_c'ye göre)
const LIGHT_SIZE := 140.0
const TEMP_MIN := 140
const TEMP_MAX := 220
const TEMP_IDEAL := 180
const ZONE_T := Vector2i(170, 190)   ## doğru sıcaklık bölgesi (çubukta altın bant)
const ZONE_M := Vector2i(9, 11)      ## doğru süre bölgesi (dk)
const MIN_LO := 5
const MIN_HI := 15

static var _tx := {}

static func tx(n: String) -> Texture2D:
	if not _tx.has(n):
		var t: Texture2D = null
		for ext in ["png", "jpg", "webp"]:
			if ResourceLoader.exists(IMG + n + "." + ext):
				t = load(IMG + n + "." + ext)
				break
		_tx[n] = t
	return _tx[n]

## Görseli c merkezine, genişliği w olacak şekilde çiz.
func _img(l: CanvasItem, n: String, c: Vector2, w: float, a := 1.0, rot := 0.0, sy := 1.0) -> bool:
	var t := tx(n)
	if t == null:
		return false
	var h := w * t.get_height() / t.get_width() * sy
	l.draw_set_transform(c, rot, Vector2.ONE)
	l.draw_texture_rect(t, Rect2(-w / 2.0, -h / 2.0, w, h), false, Color(1, 1, 1, a))
	l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func _cookie(l: CanvasItem, id: int, c: Vector2, s: float, bake: float, jit := 0.0, sy := 1.0) -> void:
	var nm: String = SHAPE_NAMES[id]
	if tx("cookie_raw_" + nm) != null:
		var k := 1.0 + 0.05 * bake
		_img(l, "cookie_raw_" + nm, c, s * 1.12 * k, 1.0, 0.0, sy)
		if bake > 0.01 and tx("cookie_baked_" + nm) != null:
			_img(l, "cookie_baked_" + nm, c, s * 1.12 * k, clampf(bake, 0.0, 1.0), 0.0, sy)
		if bake > 1.0 and tx("cookie_baked_" + nm) != null:
			# fazla pişti: koyulaşan kahve-siyah yanık katmanı
			var tb := tx("cookie_baked_" + nm)
			var w := s * 1.12 * k
			var h := w * tb.get_height() / tb.get_width() * sy
			l.draw_set_transform(c, 0.0, Vector2.ONE)
			l.draw_texture_rect(tb, Rect2(-w / 2.0, -h / 2.0, w, h), false, Color(0.22, 0.11, 0.05, clampf((bake - 1.0) * 1.6, 0.0, 0.88)))
		return
	Art.cookie(l, id, c, s, bake, jit)

class Layer extends Control:
	var fn: Callable
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	func _draw() -> void:
		if fn.is_valid():
			fn.call(self)

var step := 1
var root: Control
var stage: Control
var pad: Control
var dots_l: Layer
var hint: Label
var btn_main: JuicyButton
var btn_undo: JuicyButton
var count_l: Label
var layers: Array = []
var t := 0.0
var cx := 540.0
var y0 := 215.0
var y1 := 1500.0
var _extra := {}
var _busy := false

# karıştır
var bowl_c := Vector2.ZERO
var bowl_r := 320.0
var mix_c := Vector2.ZERO               ## kase agzinin (icerigin gorundugu elips) merkezi
var items: Array = []
var added: Array = []
var cnt: Array = [0, 0, 0, 0]    ## kaseye eklenen adet (tür başına)
var avail := 0                   ## kilerde yapılabilecek parti
var blob := PackedFloat32Array([0, 0, 0, 0])
var drag_i := -1
var turns := 0.0
var stirring := false
var last_ang := 0.0
var stir_tip := Vector2.ZERO
var ball := 0.0
var _snd_turn := 0.0
var fx: Array = []
# aç
var roll_acc := 0.0
var pin_y := 0.0
var pin_down := false
var wave := 0.0
var _snd_roll := 0.0
var dough_c := Vector2.ZERO
# kes
var sel_cut := 0
var cuts: Array = []   # {s, p, pop}
var tile_rects: Array = []
var ring_fx: Array = []
# pişir
var phase := 0
var bake_t := 0.0
var bake_dur := 6.0
var flash := 0.0
var oven_c := Vector2.ZERO
var tray_p := Vector2.ZERO
var tray_s := 1.0
var tray_front := true    ## tepsi fırının ÖNÜNDE mi (tezgâh/ağız) — değilse fırın içinde, camın arkasında
var _drag_c = null        ## sürüklenen tezgâh kurabiyesi
var _drag_off := Vector2.ZERO
var tray_tilt := 0.0      ## 0 üstten düz, 1 açılı yatırılmış (perspektif: arka kenar dar + basık)
const TILT_SQUASH := 0.5   ## tam yatıkta yükseklik oranı kaybı
const TILT_TAPER := 0.22   ## tam yatıkta arka kenar daralma oranı
var tray_a := 1.0
var oven_a := 0.0
var tray_cook: Array = []  # {s, p, pop, jit}
var _snd_crack := 0.0
var embers: Array = []
# süsle
var ink := 0
var mode := 0
var strokes: Array = []   # {c, pts: PackedVector2Array (tabak yarıçapı birimi)}
var sprinkles: Array = [] # [x, y, a, c]
var spr_age: Array = []
var history: Array = []
var plate_c := Vector2.ZERO
var plate_r := 500.0
var cur: Dictionary = {}
var _snd_ice := 0.0
var _last_spr := Vector2.ZERO
var tool_pos: Array = []

func _init() -> void:
	super()
	GAME = "cookie"
	TITLE_KEY = "xmas.cookie.title"

# ------------------------------------------------------------------ Yardımcılar

func _t(key: String) -> String:
	var s := tr(key)
	if s != key:
		return s
	if _extra.is_empty():
		_extra = {"_": 1}
		var f := FileAccess.open("res://i18n/work/xmas_cookie.csv", FileAccess.READ)
		if f:
			var col := maxi(1, Settings.LANGS.find(Settings.effective_language()) + 1)
			while not f.eof_reached():
				var row := f.get_csv_line()
				if row.size() > col:
					_extra[row[0]] = row[col] if row[col] != "" else row[1]
	return String(_extra.get(key, key))

func _d(x: float) -> float:
	return 0.15 if Ui.reduce_motion() else x

func _layer(parent: Control, fn: Callable) -> Layer:
	var l := Layer.new()
	l.fn = fn
	l.size = root.size
	parent.add_child(l)
	layers.append(l)
	return l

func _snd(n: String, fb := "place", pitch := 1.0, db := 0.0) -> void:
	XmasKit.asmr(n, fb, pitch, db)

## Sözlük alanını yaylı tween (Dictionary Object olmadığı için tween_method).
func _tw(tw: Tween, d: Dictionary, key: String, to: Variant, dur: float) -> void:
	var from: Variant = d[key]
	tw.tween_method(func(v: Variant) -> void: d[key] = v, from, to, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hap(k: String) -> void:
	Juice.haptic(k)

func _puff(p: Vector2, col: Color, n := 10, spd := 140.0) -> void:
	for i in n:
		fx.append({"p": p, "v": Vector2.from_angle(randf() * TAU) * randf_range(0.3, 1.0) * spd + Vector2(0, -40), "life": 1.0, "col": col, "r": randf_range(6.0, 15.0)})

# ------------------------------------------------------------------ Kurulum

func setup_game(r: Rect2) -> void:
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.position = r.position
	root.size = r.size
	add_child(root)
	cx = r.size.x / 2.0
	y0 = 215.0
	y1 = r.size.y - 195.0
	pad = Control.new()
	pad.size = r.size
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	pad.gui_input.connect(_pad_input)
	root.add_child(pad)
	var kb := tx("kitchen_bg")
	if kb:
		var tr_ := Ui.tex_rect(kb, size, true)
		tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr_)
		move_child(tr_, 1)
	stage = Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.size = r.size
	root.add_child(stage)
	dots_l = _layer(root, _draw_dots)
	hint = Ui.title("", 42, Palette.CREAM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_constant_override("outline_size", 8)
	hint.size = Vector2(r.size.x - 120, 130)
	hint.position = Vector2(60, 70)
	root.add_child(hint)
	btn_main = Ui.button("", "sage", Vector2(620, 140))
	btn_main.position = Vector2(cx - 310, r.size.y - 165)
	btn_main.tapped.connect(_on_main)
	root.add_child(btn_main)
	btn_undo = Ui.icon_button("ic_undo", 120)
	btn_undo.position = Vector2(r.size.x - 150, y1 - 150)
	btn_undo.tapped.connect(_undo)
	root.add_child(btn_undo)
	count_l = Ui.title("", 46, Palette.CREAM)
	count_l.size = Vector2(200, 70)
	count_l.position = Vector2(r.size.x - 230, y1 - 330)
	root.add_child(count_l)
	cur = state.get("cur", {}) if state.get("cur") is Dictionary else {}
	var s: int = int(state.get("step", 1))
	if Xmas.oven_busy():
		s = 4
	var dev := int(Dev.env("SNUG_COOKIE_STEP"))
	if dev > 0:
		_dev_prepare(dev)
		s = dev
	elif s == 6 and not (state.get("last") is Dictionary):
		s = 1
	elif s in [4, 5] and _saved_shapes().size() < MIN_COOKIES:
		s = 3 if s == 4 else 1
	go_step(s, true)
	if Dev.env("SNUG_COOKIE_SIM") != "":
		_sim()

func go_step(n: int, resume := false) -> void:
	step = n
	phase = 0
	_busy = false
	for c in stage.get_children():
		c.queue_free()
	layers = layers.filter(func(l: Control) -> bool: return l == dots_l)
	coach = {}
	fx.clear()
	ring_fx.clear()
	embers.clear()
	_hum_stop()
	btn_undo.visible = false
	btn_main.visible = false
	count_l.text = ""
	if n < 6 and int(state.get("step", 1)) != n:
		state.step = n
		Xmas.save()
	_apply_batches()
	match n:
		1: _build_mix()
		2: _build_roll()
		3: _build_cut()
		4: _build_bake()
		5: _build_decor(false)
		_: _build_decor(true, resume)
	dots_l.queue_redraw()

func _batches() -> int:
	return clampi(int(state.get("dough_b", Xmas.MAX_BATCHES)), 1, Xmas.MAX_BATCHES)

## Sınır sayı değil hamurun kendisi: yer kaldıkça kesilir (tepsi kapasitesi MAX_COOKIES).
## Parti sayısı hamurun boyutunu belirler (1 parti ≈ 3-4 kurabiyelik hamur).
func _max_cuts() -> int:
	return MAX_COOKIES

func _apply_batches() -> void:
	var k: float = [0.58, 0.8, 1.0][_batches() - 1]
	DOUGH_W = 860.0 * k
	DOUGH_H = 640.0 * k

func _process(dt: float) -> void:
	# Fırın pişerken bölüm oynanıyorsa bu ekran yığında gizli kalır: ses/çıtırtı/uğultu susmalı.
	if _covered or not is_visible_in_tree():
		_hum_stop()
		return
	dt = minf(dt, 0.05)
	t += dt
	flash = maxf(0.0, flash - dt * 2.0)
	wave = maxf(0.0, wave - dt * 120.0)
	for f: Dictionary in fx:
		f.life -= dt * 1.6
		f.p += f.v * dt
		f.v *= 0.94
	fx = fx.filter(func(f: Dictionary) -> bool: return f.life > 0.0)
	for r: Dictionary in ring_fx:
		r.life -= dt * 2.4
	ring_fx = ring_fx.filter(func(r: Dictionary) -> bool: return r.life > 0.0)
	if step == 4 and phase == 2:
		_bake_tick(dt)
	if step == 4 and phase in [2, 5]:
		_heat_tick(dt)
	if step == 4 and phase >= 1:
		_embers_tick(dt)
	for l: Control in layers:
		if is_instance_valid(l):
			l.queue_redraw()

# ------------------------------------------------------------------ Üst bilgi

func _draw_dots(l: Control) -> void:
	var n := 5
	var gap := 110.0
	var x := cx - gap * (n - 1) / 2.0
	for i in n:
		var c := Vector2(x + i * gap, 34)
		var done := step > i + 1
		var now := step == i + 1
		var col: Color = Palette.GOLD if done else (Palette.TERRACOTTA if now else Palette.LOCKED)
		var r := 24.0 if now else 18.0
		l.draw_circle(c + Vector2(0, 4), r, Palette.SHADOW)
		l.draw_circle(c, r, col.darkened(0.25))
		l.draw_circle(c + Vector2(0, -2), r - 2, col)
		l.draw_arc(c + Vector2(0, -2), r - 6, 0, TAU, 20, Palette.CREAM, 2.5, true)
		if done:
			l.draw_polyline(PackedVector2Array([c + Vector2(-8, -1), c + Vector2(-2, 6), c + Vector2(9, -9)]), Palette.CREAM, 4.0, true)

func _set_hint(key: String) -> void:
	hint.text = _t(key)
	hint.pivot_offset = hint.size / 2.0
	hint.modulate.a = 0.0
	create_tween().tween_property(hint, "modulate:a", 1.0, _d(0.35))

func _show_main(key: String, skin := "sage", enabled := true) -> void:
	btn_main.text = _t(key)
	btn_main.skin = UiArt.tex("btn_" + skin)
	btn_main.color = {"terracotta": Palette.TERRACOTTA, "sage": Palette.SAGE, "mustard": Palette.MUSTARD}.get(skin, Palette.CARD)
	btn_main.disabled = not enabled
	btn_main.visible = true
	Ui.pop_in(btn_main, 0.0, 0.8)

func _on_main() -> void:
	if _busy:
		return
	match step:
		1:
			if avail == 0:
				Main.back()
		3:
			if cuts.size() < MIN_COOKIES:
				return
			_save_cuts()
			go_step(4)
		4:
			if phase == 6:
				for c: Dictionary in tray_cook:
					if not c.placed:
						return
				_tray_go()
			elif phase == 2 and Xmas.oven_busy():
				Main.play(Progress.continue_target())
			elif phase == 3:
				go_step(5)
		5:
			_finish()
		6:
			_new_batch()

# ------------------------------------------------------------------ Girdi

func _pad_input(e: InputEvent) -> void:
	if _busy:
		return
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_down(e.position)
		else:
			_up(e.position)
	elif e is InputEventMouseMotion and ((e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_move(e.position)

func _down(p: Vector2) -> void:
	match step:
		1: _mix_down(p)
		2: _roll_down(p)
		3: _cut_down(p)
		4: _bake_down(p)
		5: _decor_down(p)

func _move(p: Vector2) -> void:
	match step:
		1: _mix_move(p)
		2: _roll_move(p)
		4: _bake_move(p)
		5: _decor_move(p)

func _up(p: Vector2) -> void:
	match step:
		1: _mix_up(p)
		2: pin_down = false
		4: _bake_up(p)
		5: _decor_up(p)

# ------------------------------------------------------------------ 1 Karıştır

func _build_mix() -> void:
	# kase yukarida; raf + 'Malzeme al' dugmesi kaseyle cakismaz (y1-360 dugme ustu, kase tabani <= y1-430)
	bowl_c = Vector2(cx, maxf(y0 + 250.0 + 312.0, minf(_table_y(-0.06), y1 - 725.0)))
	bowl_r = 320.0
	mix_c = bowl_c + Vector2(0, -149.0)   # içerik yüzeyi: arka iç duvar üstte görünür, alt kenar ön dudağın altına girer
	items.clear()
	added.clear()
	blob = PackedFloat32Array([0, 0, 0, 0])
	turns = 0.0
	ball = 0.0
	stirring = false
	drag_i = -1
	cnt = [0, 0, 0, 0]
	avail = Xmas.batches_available()
	for i in 4:
		var h := Vector2(cx + (i - 1.5) * 245.0, y1 - 120.0)
		items.append({"k": i, "home": h, "pos": h, "sc": 1.0, "a": 1.0, "used": avail == 0})
	_layer(stage, _draw_mix)
	var buy := Ui.button(_t("xmas.cookie.buy") % Xmas.SET_PRICE, "mustard", Vector2(400, 100), "", 30)
	buy.position = Vector2(root.size.x - 440.0, y1 - 375.0)
	buy.tapped.connect(_buy_ingredients)
	stage.add_child(buy)
	if avail == 0:
		_set_hint("xmas.cookie.hint.noIng")
		_show_main("xmas.cookie.btn.village", "sage")
	else:
		_set_hint("xmas.cookie.hint.add")
		_coach("mix", "drag", items[0].home, mix_c)
	var dk := int(Dev.env("SNUG_COOKIE_STEP"))
	if dk == 1:
		var dn := int(Dev.env("SNUG_COOKIE_MIXN")) if Dev.env("SNUG_COOKIE_MIXN") != "" else 2
		for k in dn:
			items[k].used = true
			cnt[k] = 1
			added.append(k)
			blob[k] = 1.0

const MIX_LAYERS := ["mix_flour", "mix_sugar", "mix_egg", "mix_butter"]
const MIX_CLIP_RX := 309.0   ## bowl_front iç dudağından ölçüldü (görsel ölçek 760/700)
const MIX_CLIP_RY := 103.0

## Dokuyu kase agzi elipsine kirpilmis cizer (poligon + UV): tasma yok.
func _clip_img(l: CanvasItem, n: String, sc: float, a: float) -> void:
	var t := tx(n)
	if t == null or a <= 0.002:
		return
	var w := MIX_CLIP_RX * 2.08 * sc
	var h := MIX_CLIP_RY * 2.08 * sc
	var r := Rect2(mix_c - Vector2(w, h) / 2.0, Vector2(w, h))
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 48:
		var an := TAU * i / 48.0
		var p := mix_c + Vector2(cos(an) * MIX_CLIP_RX, sin(an) * MIX_CLIP_RY)
		pts.append(p)
		uvs.append((p - r.position) / r.size)
	l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	l.draw_colored_polygon(pts, Color(1, 1, 1, a), uvs, t)

func _draw_mix(l: Control) -> void:
	# raf
	if turns < 0.05:
		Art.felt_rr(l, Rect2(Vector2(60, y1 - 215), Vector2(root.size.x - 120, 190)), 60.0, Palette.TRAY, Art.F_PEACH, 8.0, Color(0.95, 0.88, 0.8), 18.0, 3)
	var bt := tx("bowl_back") != null
	if bt:
		_img(l, "bowl_back", bowl_c, BOWL_W)
	else:
		Art.bowl_back(l, bowl_c, bowl_r)
	var m := clampf(turns / MIX_TURNS, 0.0, 1.0)
	var ic := mix_c
	var irx := 270.0
	var iry := 62.0
	var offs := [Vector2(-0.45, -0.1), Vector2(0.45, -0.05), Vector2(-0.05, 0.3), Vector2(0.2, -0.35)]
	var layered := bt and tx("mix_flour") != null and tx("batter_0") != null
	if layered:
		# her malzeme kendi katmanini kaseye ekler (eklenme sirasiyla), tamami agiz elipsine kirpilir
		var g := clampf(m * 10.0, 0.0, 1.0)
		for k: int in added:
			var bs := clampf(blob[k], 0.0, 1.3)
			_clip_img(l, MIX_LAYERS[k], lerpf(0.78, 1.0, minf(bs, 1.0)), clampf(bs * 2.0, 0.0, 1.0) * (1.0 - g))
		if g > 0.0:
			var bi := clampf(m * 3.0, 0.0, 3.0)
			var b0 := int(floorf(bi))
			_clip_img(l, "batter_%d" % b0, 1.0, g)
			if b0 < 3 and tx("batter_%d" % (b0 + 1)) != null:
				_clip_img(l, "batter_%d" % (b0 + 1), 1.0, (bi - b0) * g)
	for a in (added.size() if not layered else 0):
		var k: int = added[a]
		var bs := blob[k]
		var o: Vector2 = offs[k] * (1.0 - m)
		var col: Color = Art.ING_BLOB[k].lerp(Palette.PIECES[Art.F_PEACH].lightened(0.15), m)
		var rx := irx * lerpf(0.3, 0.82, m) * bs
		var ry := iry * lerpf(0.42, 0.85, m) * bs
		var c := ic + Vector2(o.x * irx * 0.7, o.y * iry * 0.8)
		l.draw_colored_polygon(Art.ell(c + Vector2(0, 3), rx, ry, 28), Color(0.2, 0.1, 0.05, 0.25))
		l.draw_colored_polygon(Art.ell(c, rx, ry, 28), col)
		l.draw_colored_polygon(Art.ell(c + Vector2(-rx * 0.2, -ry * 0.25), rx * 0.55, ry * 0.4, 20), Color(1, 1, 1, 0.14))
	if turns > 0.05 and ball < 0.5:
		var sp := PackedVector2Array()
		for i in 60:
			var u := i / 59.0
			var a := last_ang * 0.0 + u * TAU * 2.2 + t * 0.0
			sp.append(ic + Vector2(cos(a) * irx * u * 0.8, sin(a) * iry * u * 0.8))
		l.draw_polyline(sp, Color(0.55, 0.35, 0.2, 0.22 + 0.3 * m), 7.0, true)
	if ball > 0.01:
		if not _img(l, "dough_ball", ic + Vector2(0, -80.0 * ball), 300.0 * ball):
			Art.dough_ball(l, ic + Vector2(0, -80.0 * ball), 150.0 * ball)
	if bt:
		_img(l, "bowl_front", bowl_c, BOWL_W)
	else:
		Art.bowl_lip(l, bowl_c, bowl_r)
	for it: Dictionary in items:
		if it.used and it.a < 0.02:
			continue
		var s: float = 190.0 * float(it.sc) * (0.3 + 0.7 * float(it.a))
		if not _img(l, ["flour", "sugar", "egg", "butter"][it.k], it.pos, s, 1.0 if avail > 0 else 0.45):
			Art.ingredient(l, it.k, it.pos, s)
		if turns < 0.05 and it.pos.distance_to(it.home) < 4.0:
			# kilerde kalan adet rozeti
			var left := int(Xmas.pantry().get(Xmas.INGR[it.k], 0)) - int(cnt[it.k])
			var bc: Vector2 = it.home + Vector2(62, -62)
			l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			l.draw_circle(bc + Vector2(0, 3), 30.0, Palette.SHADOW)
			l.draw_circle(bc, 30.0, Palette.TERRACOTTA if left > 0 else Palette.LOCKED)
			var txt := "x%d" % maxi(0, left)
			var fs := Ui.FONT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
			l.draw_string(Ui.FONT, bc + Vector2(-fs.x / 2.0, 11.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.CREAM)
	if stirring and ball < 0.1:
		Art.spoon(l, stir_tip)

func _in_bowl(p: Vector2) -> bool:
	return absf(p.x - bowl_c.x) < bowl_r and p.y > bowl_c.y - bowl_r * 0.8 and p.y < bowl_c.y + bowl_r * 0.45

func _mix_ready() -> bool:
	for k in 4:
		if int(cnt[k]) < 1:
			return false
	return true

func _mix_down(p: Vector2) -> void:
	if turns < 0.05 and avail > 0:
		for i in items.size():
			var it: Dictionary = items[i]
			if not it.used and p.distance_to(it.pos) < 120.0:
				drag_i = i
				it.sc = 1.2
				_hap("tick")
				_snd("rustle", "place", 1.4, -8.0)
				return
	if _mix_ready() and ball < 0.1:
		stirring = true
		stir_tip = p
		last_ang = (p - mix_c).angle()

func _mix_move(p: Vector2) -> void:
	if drag_i >= 0:
		items[drag_i].pos = p
	elif stirring:
		var d := p - mix_c
		var e := Vector2(clampf(d.x, -bowl_r * 0.75, bowl_r * 0.75), clampf(d.y, -bowl_r * 0.2, bowl_r * 0.2))
		stir_tip = mix_c + e
		if d.length() > 40.0:
			var a := d.angle()
			var da := absf(angle_difference(last_ang, a))
			last_ang = a
			turns += da / TAU
			_snd_turn += da / TAU
			if _snd_turn > 0.2:
				_snd_turn = 0.0
				_snd("rustle", "place", randf_range(0.7, 0.95), -7.0)
				_hap("tick")
			if turns >= MIX_TURNS and not _busy:
				_mix_done()

func _mix_up(_p: Vector2) -> void:
	stirring = false
	if drag_i < 0:
		return
	var it: Dictionary = items[drag_i]
	drag_i = -1
	it.sc = 1.0
	if _in_bowl(it.pos):
		_add_ingredient(it)
	else:
		_tw(create_tween(), it, "pos", it.home, _d(0.35))

func _add_ingredient(it: Dictionary) -> void:
	_coach_done("mix")
	var k: int = it.k
	cnt[k] = int(cnt[k]) + 1
	var first := not added.has(k)
	if first:
		added.append(k)
	# stok/parti sınırı dolmadıysa malzeme rafta yeniden belirir (bir tane daha eklenebilir)
	it.used = int(cnt[k]) >= avail
	if not it.used:
		get_tree().create_timer(_d(0.3)).timeout.connect(func() -> void:
			it.pos = it.home
			it.a = 1.0
			it.sc = 0.4
			_tw(create_tween(), it, "sc", 1.0, _d(0.3)))
	var target := mix_c
	var tw := create_tween().set_parallel()
	_tw(tw, it, "pos", target, _d(0.22))
	_tw(tw, it, "a", 0.0, _d(0.22))
	tw.tween_method(func(v: float) -> void: blob[k] = v, 0.0, 1.0, _d(0.45)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.12)
	var cols: Array[Color] = [Color(1, 0.98, 0.92), Color(0.98, 0.85, 0.9), Color(0.95, 0.72, 0.28), Color(0.96, 0.85, 0.45)]
	get_tree().create_timer(_d(0.22)).timeout.connect(func() -> void:
		_puff(target, cols[k], 14, 200.0 if k == 0 else 140.0)
		match k:
			0: _snd("rustle", "place", 0.75, 0.0)
			1: _snd("rustle", "place", 1.35, -2.0)
			2: _snd("felt_pop", "place", 0.7, 0.0)
			_: _snd("felt_pop", "place", 1.15, 0.0)
		_hap("light"))
	if _mix_ready():
		_coach("stir", "circle", mix_c, Vector2.ZERO, bowl_r * 0.5)
		var b := _mix_batches()
		get_tree().create_timer(_d(0.7)).timeout.connect(func() -> void:
			if step == 1:
				hint.text = _t("xmas.cookie.hint.stirN") % [b * Xmas.BATCH_COOKIES])

func _mix_batches() -> int:
	var b := Xmas.MAX_BATCHES
	for k in 4:
		b = mini(b, int(cnt[k]))
	return maxi(1, b)

func _mix_done() -> void:
	_coach_done("stir")
	var b := _mix_batches()
	Xmas.use_batches(b)
	state.dough_b = b
	Xmas.save()
	_busy = true
	stirring = false
	_snd("felt_pop", "place", 0.9)
	_hap("success")
	create_tween().tween_property(self, "ball", 1.0, _d(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(_d(1.5)).timeout.connect(func() -> void:
		if step == 1:
			go_step(2))

# ------------------------------------------------------------------ 2 Aç

func _build_roll() -> void:
	dough_c = Vector2(cx, _table_y(0.04))
	roll_acc = 0.0
	pin_y = dough_c.y - 380.0
	pin_down = false
	_layer(stage, _draw_roll)
	_set_hint("xmas.cookie.hint.roll")
	_coach("roll", "swipe", dough_c + Vector2(60, -240), dough_c + Vector2(60, 240))
	var dk := int(Dev.env("SNUG_COOKIE_STEP"))
	if dk == 2:
		roll_acc = ROLL_TOTAL * 0.45

func _dough_dims() -> Vector2:
	var pr := clampf(roll_acc / ROLL_TOTAL, 0.0, 1.0)
	return Vector2(lerpf(330.0, DOUGH_W, ease(pr, 0.7)), lerpf(300.0, DOUGH_H, ease(pr, 0.7)))

func _dough_poly(c: Vector2, dm: Vector2, e: float, ripple := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 72:
		var a := TAU * i / 72.0
		var ca := cos(a)
		var sa := sin(a)
		var x := signf(ca) * pow(absf(ca), 2.0 / e) * dm.x / 2.0
		var y := signf(sa) * pow(absf(sa), 2.0 / e) * dm.y / 2.0
		var py := c.y + y
		var bump := 1.0 + ripple * exp(-pow((py - pin_y) / 90.0, 2.0))
		pts.append(Vector2(c.x + x * bump, py + sin(x * 0.03 + t * 5.0) * ripple * 80.0 * exp(-pow((py - pin_y) / 120.0, 2.0))))
	return pts

func _draw_table(l: Control, c: Vector2) -> void:
	if tx("kitchen_bg") != null:
		return
	var r := Rect2(Vector2(20, y0 + 10), Vector2(root.size.x - 40, y1 - y0 - 20))
	Art.felt_rr(l, r, 70.0, Palette.BOARD, Art.F_TWEED, 12.0, Color(1.08, 1.0, 0.92), 22.0, 6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 90:
		var q := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		l.draw_circle(q, rng.randf_range(2.0, 5.5), Color(1, 0.98, 0.94, 0.3))

func _draw_roll(l: Control) -> void:
	_draw_table(l, dough_c)
	var pr := clampf(roll_acc / ROLL_TOTAL, 0.0, 1.0)
	var dm := _dough_dims()
	var e := lerpf(2.1, 3.0, pr)
	var poly := _dough_poly(dough_c, dm, e, wave * 0.0006)
	var th := lerpf(34.0, 12.0, pr)
	if tx("dough_flat") != null:
		var big := pr > 0.08
		_img(l, "dough_ball" if not big else "dough_flat", dough_c, dm.x * (1.1 if big else 0.9))
		_draw_roll_extras(l, pr)
		return
	var tex := Fabrics.get_tex(Art.F_PEACH)
	l.draw_colored_polygon(Art.shift(poly, Vector2(0, th + 10.0)), Palette.SHADOW)
	l.draw_colored_polygon(Art.shift(poly, Vector2(0, th)), Palette.PIECES[Art.F_PEACH].darkened(0.28))
	if tex:
		l.draw_colored_polygon(poly, Color(1, 0.96, 0.88), Fabrics.uvs(poly, tex, 37), tex)
	else:
		l.draw_colored_polygon(poly, Palette.PIECES[Art.F_PEACH])
	l.draw_polyline(Art.ring(poly), Color(0.3, 0.14, 0.06, 0.24), 10.0, true)
	l.draw_colored_polygon(Art.off(poly, -dm.x * 0.12), Color(1, 0.96, 0.85, 0.1))
	Art.stitch(l, Art.off(poly, -18.0), 3.5)
	_draw_roll_extras(l, pr)

func _draw_roll_extras(l: Control, pr: float) -> void:
	# pasları göster
	var passes := int(roll_acc / (ROLL_TOTAL / 5.0))
	for i in 5:
		var c := Vector2(cx + (i - 2) * 54.0, y1 - 40.0)
		l.draw_circle(c + Vector2(0, 3), 16.0, Palette.SHADOW)
		l.draw_circle(c, 16.0, (Palette.GOLD if i < passes else Palette.LOCKED).darkened(0.25))
		l.draw_circle(c + Vector2(0, -2), 13.0, Palette.GOLD if i < passes else Palette.LOCKED)
	# ok ipucu
	if roll_acc < 120.0:
		var o := sin(t * 3.0) * 16.0
		var ax := dough_c.x + 440.0
		for s in [-1.0, 1.0]:
			var tip := Vector2(ax, dough_c.y + s * (150.0 + o))
			l.draw_polyline(PackedVector2Array([tip + Vector2(-26, -s * 30.0), tip, tip + Vector2(26, -s * 30.0)]), Palette.CREAM, 10.0, true)
	if not _img(l, "rolling_pin", Vector2(cx, pin_y), 760.0):
		Art.pin(l, Vector2(cx, pin_y), 640.0)

func _roll_down(p: Vector2) -> void:
	_coach_done("roll")
	pin_down = true
	pin_y = clampf(p.y, dough_c.y - 400.0, dough_c.y + 400.0)
	_snd("rustle", "place", 0.9, -6.0)

func _roll_move(p: Vector2) -> void:
	if not pin_down:
		return
	var ny := clampf(p.y, dough_c.y - 400.0, dough_c.y + 400.0)
	var dy := absf(ny - pin_y)
	pin_y = ny
	var was := int(roll_acc / (ROLL_TOTAL / 5.0))
	if absf(pin_y - dough_c.y) < _dough_dims().y / 2.0 + 60.0:
		roll_acc = minf(ROLL_TOTAL, roll_acc + dy)
		wave = minf(wave + dy * 2.0, 120.0)
	_snd_roll += dy
	if _snd_roll > 130.0:
		_snd_roll = 0.0
		_snd("rustle", "place", randf_range(0.8, 1.15), -5.0)
		_hap("tick")
	var now := int(roll_acc / (ROLL_TOTAL / 5.0))
	if now > was and now < 5:
		_snd("felt_pop", "place", 0.8, -6.0)
		_hap("light")
	if roll_acc >= ROLL_TOTAL and not _busy:
		_busy = true
		pin_down = false
		_snd("felt_pop", "place", 1.1)
		_hap("success")
		get_tree().create_timer(_d(0.9)).timeout.connect(func() -> void:
			if step == 2:
				go_step(3))

# ------------------------------------------------------------------ 3 Kes

func _build_cut() -> void:
	dough_c = Vector2(cx, _table_y(0.0))
	cuts.clear()
	for s: Dictionary in _saved_shapes():
		cuts.append({"s": int(s.s), "p": _dough_tl() + Vector2(float(s.x) * DOUGH_W, float(s.y) * DOUGH_H), "pop": 1.0, "press": 0.0, "fly": 1.0})
	sel_cut = 0
	tile_rects.clear()
	for i in 5:
		tile_rects.append(Rect2(Vector2(cx + (i - 2) * 196.0 - 85.0, y1 - 205.0), Vector2(170, 170)))
	_layer(stage, _draw_cut)
	_set_hint("xmas.cookie.hint.cut")
	_coach("cut", "tap", dough_c + Vector2(-160, -60))
	_show_main("xmas.cookie.btn.bake", "terracotta", cuts.size() >= MIN_COOKIES)
	btn_main.position.y = root.size.y - 165.0
	btn_main.position.x = cx - 310.0
	_refresh_cut_ui()

func _dough_tl() -> Vector2:
	return dough_c - Vector2(DOUGH_W, DOUGH_H) / 2.0

func _draw_cut(l: Control) -> void:
	_draw_table(l, dough_c)
	var poly := _dough_poly(dough_c, Vector2(DOUGH_W, DOUGH_H), 3.0)
	var tex := Fabrics.get_tex(Art.F_PEACH)
	var img_d := _img(l, "dough_flat", dough_c, DOUGH_W * 1.1)
	if not img_d:
		l.draw_colored_polygon(Art.shift(poly, Vector2(0, 22.0)), Palette.SHADOW)
	if not img_d:
		l.draw_colored_polygon(Art.shift(poly, Vector2(0, 12.0)), Palette.PIECES[Art.F_PEACH].darkened(0.28))
		if tex:
			l.draw_colored_polygon(poly, Color(1, 0.96, 0.88), Fabrics.uvs(poly, tex, 37), tex)
		l.draw_polyline(Art.ring(poly), Color(0.3, 0.14, 0.06, 0.24), 10.0, true)
		Art.stitch(l, Art.off(poly, -18.0), 3.5)
	# Kesilen yerler: hamur o şekilde eksilir (delikten tezgâh görünür + hamur kalınlığı).
	for c: Dictionary in cuts:
		_draw_hole(l, _cut_poly(c.s, c.p))
	# Kalıp basma + kalkan kurabiye parçası (kurabiye uçup sayaca gider).
	for c: Dictionary in cuts:
		var fly: float = c.get("fly", 1.0)
		if fly < 1.0:
			var dest := Vector2(root.size.x - 170.0, y1 - 300.0)
			var lift := sin(clampf(fly, 0.0, 1.0) * PI) * -160.0
			var cp: Vector2 = c.p.lerp(dest, ease(fly, 2.2)) + Vector2(0, lift)
			_cookie(l, c.s, cp, COOKIE_S * lerpf(1.0, 0.45, fly), 0.0)
		var pr: float = c.get("press", 0.0)
		if pr > 0.01:
			var k := lerpf(1.25, 1.0, clampf(pr, 0.0, 1.0))
			if not _img(l, "cutter_" + SHAPE_NAMES[c.s], c.p + Vector2(0, -30.0 * (1.0 - pr)), COOKIE_S * 1.25 * k, clampf(pr * 1.4, 0.0, 1.0)):
				l.draw_polyline(Art.ring(Art.xf(Art.shape(c.s), c.p, COOKIE_S * k)), Color(Palette.CREAM, pr), 6.0, true)
			l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for r: Dictionary in ring_fx:
		l.draw_arc(r.p, 40.0 + (1.0 - r.life) * 70.0, 0, TAU, 28, Color(r.col, r.life * 0.8), 7.0, true)
	# kalıp rafı
	Art.felt_rr(l, Rect2(Vector2(40, y1 - 225.0), Vector2(root.size.x - 80, 210)), 50.0, Palette.TRAY, Art.F_PEACH, 8.0, Color(0.95, 0.88, 0.8), 16.0, 4)
	for i in 5:
		var r: Rect2 = tile_rects[i]
		var on := i == sel_cut
		var rr := r if not on else Rect2(r.position + Vector2(-6, -14), r.size + Vector2(12, 12))
		Art.felt_rr(l, rr, 34.0, Palette.CARD, Art.F_TERRA if on else Art.F_SAGE, 6.0, Color(1.0, 0.95, 0.9) if on else Color(0.92, 0.95, 0.9), 12.0, i)
		if _img(l, "cutter_" + SHAPE_NAMES[i], rr.get_center(), CUTTER_SIZE * 1.15):
			continue
		var pts := Art.xf(Art.shape(i), rr.get_center(), 100.0)
		l.draw_colored_polygon(Art.shift(pts, Vector2(0, 4)), Color(0.25, 0.12, 0.05, 0.3))
		l.draw_colored_polygon(pts, Palette.CREAM)
		l.draw_polyline(Art.ring(pts), Palette.INK, 4.0, true)

func _refresh_cut_ui() -> void:
	count_l.text = "%d" % cuts.size()
	count_l.position = Vector2(root.size.x - 240, y1 - 280.0)
	btn_main.disabled = cuts.size() < MIN_COOKIES

func _cut_poly(sh: int, p: Vector2) -> PackedVector2Array:
	return Art.xf(Art.shape(sh), p, COOKIE_S)

func _in_dough(q: Vector2) -> bool:
	var d := q - dough_c
	return pow(absf(d.x) / (DOUGH_W / 2.0 - 10.0), 3.0) + pow(absf(d.y) / (DOUGH_H / 2.0 - 10.0), 3.0) <= 1.0

## Kalıp tamamen hamurun içinde ve önceki deliklere değmiyorsa kesilir (boş yer arama).
func _cut_ok(p: Vector2, sh := -1) -> bool:
	var poly := _cut_poly(sel_cut if sh < 0 else sh, p)
	for q: Vector2 in poly:
		if not _in_dough(q):
			return false
	var grown := Geometry2D.offset_polygon(poly, 6.0)
	var g: PackedVector2Array = grown[0] if not grown.is_empty() else poly
	for c: Dictionary in cuts:
		if not Geometry2D.intersect_polygons(g, _cut_poly(c.s, c.p)).is_empty():
			return false
	return true

## Hamurdaki delik: içi arka plan (tezgâh) dokusu, üst iç duvarda hamur kalınlığı, kenarda gölge.
func _draw_hole(l: CanvasItem, poly: PackedVector2Array) -> void:
	var kb := tx("kitchen_bg")
	if kb:
		var scr := size
		var ts := Vector2(kb.get_width(), kb.get_height())
		var k := maxf(scr.x / ts.x, scr.y / ts.y)
		var off := (scr - ts * k) / 2.0
		var uvs := PackedVector2Array()
		for q: Vector2 in poly:
			uvs.append((q + root.position - off) / (ts * k))
		l.draw_colored_polygon(poly, Color(0.82, 0.78, 0.74), uvs, kb)
	else:
		l.draw_colored_polygon(poly, Palette.BOARD.darkened(0.15))
	# iç duvar (hamur kalınlığı): delik − aşağı kaydırılmış delik → üstte hilal
	var wall := Geometry2D.clip_polygons(poly, Art.shift(poly, Vector2(0, 16.0)))
	for w: PackedVector2Array in wall:
		if not Geometry2D.is_polygon_clockwise(w):
			l.draw_colored_polygon(w, Color(0.72, 0.47, 0.27))
	var sh := Geometry2D.clip_polygons(poly, Art.shift(poly, Vector2(0, 30.0)))
	for w: PackedVector2Array in sh:
		if not Geometry2D.is_polygon_clockwise(w):
			l.draw_colored_polygon(Art.shift(w, Vector2(0, 16.0)), Color(0.15, 0.07, 0.03, 0.22))
	l.draw_polyline(Art.ring(poly), Color(0.98, 0.86, 0.66, 0.9), 3.0, true)

func _cut_down(p: Vector2) -> void:
	for i in 5:
		if (tile_rects[i] as Rect2).grow(14.0).has_point(p):
			sel_cut = i
			_snd("rustle", "click", 1.3, -6.0)
			_hap("tick")
			return
	for i in cuts.size():
		if Geometry2D.is_point_in_polygon(p, _cut_poly(cuts[i].s, cuts[i].p)) and float(cuts[i].get("fly", 1.0)) >= 1.0:
			# deliğe dokun → parça hamura geri basılır
			var c: Dictionary = cuts[i]
			cuts.remove_at(i)
			_puff(c.p, Palette.PIECES[Art.F_PEACH], 8, 120.0)
			_snd("snow_pack", "place", 1.3, -4.0)
			_hap("light")
			_refresh_cut_ui()
			return
	if cuts.size() >= _max_cuts() or not _cut_ok(p):
		# sığmıyor: kalıp kırmızı titrer
		ring_fx.append({"p": p, "life": 1.0, "col": Palette.BAD})
		_snd("knob_click", "click", 0.6, -6.0)
		_hap("error")
		return
	_coach_done("cut")
	var c := {"s": sel_cut, "p": p, "pop": 1.0, "press": 0.0, "fly": 0.0}
	cuts.append(c)
	_refresh_cut_ui()
	# 1) kalıp iner ve hamura gömülür: yumuşak "ezilme" + orta titreşim
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: c.press = v, 0.0, 1.0, _d(0.16)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_snd("snow_pack", "place", randf_range(1.15, 1.35), -2.0)
		_hap("medium")
		_puff(c.p, Color(0.97, 0.93, 0.85), 10, 150.0))
	tw.tween_interval(_d(0.12))
	# 2) kalıp kalkar, hamur "vırt" diye ayrılır
	tw.tween_callback(func() -> void:
		_snd("felt_pop", "place", randf_range(0.85, 1.0), -2.0)
		_hap("light"))
	tw.tween_method(func(v: float) -> void: c.press = v, 1.0, 0.0, _d(0.18))
	# 3) kurabiye parçası havalanıp sayaca uçar
	tw.parallel().tween_method(func(v: float) -> void: c.fly = v, 0.0, 1.0, _d(0.55)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_snd("rustle", "click", 1.35, -6.0)
		_hap("tick"))

func _save_cuts() -> void:
	var arr: Array = []
	for c: Dictionary in cuts:
		var q: Vector2 = c.p - _dough_tl()
		arr.append({"s": c.s, "x": snappedf(q.x / DOUGH_W, 0.001), "y": snappedf(q.y / DOUGH_H, 0.001)})
	cur = {"shapes": arr, "strokes": [], "sprinkles": []}
	state.cur = cur
	Xmas.save()

func _saved_shapes() -> Array:
	var a: Variant = cur.get("shapes")
	return a if a is Array else []

# ------------------------------------------------------------------ 4 Pişir

func _bed() -> Rect2:
	var tt := tx("tray")
	var w := TRAY_SIZE.x * 1.08
	var h := w * (tt.get_height() / float(tt.get_width()) if tt else TRAY_SIZE.y / TRAY_SIZE.x)
	return Rect2(TRAY_BED.position * Vector2(w, h), TRAY_BED.size * Vector2(w, h))

func _grid(n: int) -> Vector2i:
	var b := _bed()
	var cols := clampi(ceili(sqrt(n * b.size.x / b.size.y)), 1, n)
	return Vector2i(cols, ceili(float(n) / cols))

## Kurabiyeler tepsinin İÇ TABANINA sığacak ızgara (taşmaz).
func _tray_layout(n: int) -> Array:
	var out: Array = []
	if n <= 0:
		return out
	var b := _bed()
	var g := _grid(n)
	var cw := b.size.x / g.x
	var ch := b.size.y / g.y
	for i in n:
		var r := i / g.x
		var in_row := mini(g.x, n - r * g.x)
		var c := i % g.x
		out.append(b.get_center() + Vector2((c - (in_row - 1) / 2.0) * cw, (r - (g.y - 1) / 2.0) * ch))
	return out

## Tepsi üstündeki kurabiye çizim ölçüsü (_cookie s; görsel genişliği s*1.12) — hücreye sığar.
func _cookie_size() -> float:
	var n := maxi(1, tray_cook.size())
	var b := _bed()
	var g := _grid(n)
	return minf(b.size.x / g.x, b.size.y / g.y) * 0.86 / 1.12

var temp := 140
var temp_set := false
var minutes := 5
var timer_set := false
var knob_drag := -1
var slide_drag := -1          ## fırın altı ayar çubuğu (0 sıcaklık, 1 süre)
var slide_vis: Array = [-1.0, -1.0]   ## sürüklerken tutamağın kesintisiz konumu (0..1), -1 = değere bağlı
var _slide_x := 0.0
const SLIDER_W := 640.0
const SLIDER_GAP := 26.0
## Çubuk satırı yüksekliği = fırın düğmesi yüksekliği (KNOB_SIZE); tutamak da aynı boyda düğme.
func _slider_cy(i: int) -> float:
	return OVEN_IMG.y / 2.0 + SLIDER_GAP + KNOB_SIZE / 2.0 + i * (KNOB_SIZE + SLIDER_GAP)
var temp_ang := -135.0
var timer_ang := -135.0
var heat_lvl := 0.0
var heated := false
var pending_start := false
var bake_goal := 1.0
var wound_ang := 0.0
var _hum := 0.0
var _last_sec := -1
var door := 0.0         ## 0 kapalı, 1 açık
var mitt_a := 0.0
var clipper: Control
var heat: ColorRect
var tray_l: Layer
const HEAT_SHADER := """shader_type canvas_item;
uniform sampler2D scr : hint_screen_texture, filter_linear;
uniform float amp = 0.0035;
uniform float k = 1.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 70.0 + TIME * 3.0) * amp * (1.0 - UV.y * 0.5);
	uv.y += cos(uv.x * 50.0 + TIME * 2.0) * amp * 0.5;
	COLOR = vec4(texture(scr, uv).rgb, k);
}
"""

func _win_rect() -> Rect2:
	return Rect2(oven_c + OVEN_WIN.position, OVEN_WIN.size)

## Tepsi katmanını (kırpma) tüm alana ya da yalnız fırın penceresine ayarla.
func _set_clip(full: bool) -> void:
	var r := Rect2(Vector2.ZERO, root.size) if full else _win_rect()
	clipper.position = r.position
	clipper.size = r.size
	for c in clipper.get_children():
		(c as Control).position = -r.position

func _build_bake() -> void:
	phase = 0
	bake_t = 0.0
	bake_dur = 2.5 if Ui.reduce_motion() else 6.0
	oven_c = Vector2(cx, y0 + (y1 - y0) * OVEN_C_Y)
	# kısa ekranda iki düğme boyu çubuk sığsın diye fırını yukarı al (üst kenar y0'ın altında kalır)
	oven_c.y = maxf(y0 + OVEN_IMG.y / 2.0 - 60.0, minf(oven_c.y, y1 + 120.0 - _slider_cy(1) - KNOB_SIZE / 2.0))
	oven_a = 0.0
	door = 0.0
	mitt_a = 0.0
	tray_a = 1.0
	tray_s = TRAY_TABLE
	tray_tilt = 0.0
	tray_front = true
	tray_p = _table_pos()
	tray_cook.clear()
	var lay := _tray_layout(_saved_shapes().size())
	var n := _saved_shapes().size()
	var i := 0
	for s: Dictionary in _saved_shapes():
		# tezgâhta iki sıra halinde bekler; oyuncu tek tek tepsiye dizer
		var row := 0 if n <= 4 else (0 if i < ceili(n / 2.0) else 1)
		var in_row := n if n <= 4 else (ceili(n / 2.0) if row == 0 else n - ceili(n / 2.0))
		var col := i if row == 0 else i - ceili(n / 2.0)
		var home := Vector2(cx + (col - (in_row - 1) / 2.0) * 200.0, y1 - 300.0 + row * 175.0)
		tray_cook.append({"s": int(s.s), "p": lay[i], "pop": 1.0, "jit": randf_range(-0.06, 0.06), "placed": false, "home": home, "sp": home, "slot": -1})
		i += 1
	_layer(stage, _draw_oven)
	clipper = Control.new()
	clipper.clip_contents = true
	clipper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(clipper)
	tray_l = _layer(clipper, _draw_tray)
	if tx("oven_glow") != null:
		var gl := _layer(clipper, _draw_glow)
		gl.material = CanvasItemMaterial.new()
		(gl.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_set_clip(true)
	_layer(stage, _draw_glass)
	_layer(stage, _draw_knobs)
	_layer(stage, _draw_tray_front)
	temp = TEMP_MIN
	temp_set = false
	minutes = MIN_LO
	timer_set = false
	temp_ang = -135.0
	timer_ang = -135.0
	heat_lvl = 0.0
	heated = false
	pending_start = false
	knob_drag = -1
	heat = ColorRect.new()
	heat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = HEAT_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	heat.material = mat
	heat.position = _win_rect().position
	heat.size = _win_rect().size
	heat.visible = false
	stage.add_child(heat)
	_set_hint("xmas.cookie.hint.bake")
	if Xmas.oven_busy():
		# Fırın zaten çalışıyor (oyuncu bölüm oynayıp döndü): tepsi içeride, kalan süre akıyor.
		var o := Xmas.oven()
		temp = int(o.get("temp", TEMP_IDEAL))
		minutes = int(o.get("minutes", 10))
		temp_set = true
		timer_set = true
		temp_ang = -135.0 + float(temp - TEMP_MIN) / float(TEMP_MAX - TEMP_MIN) * 270.0
		timer_ang = -135.0 + float(minutes - MIN_LO) / float(MIN_HI - MIN_LO) * 270.0
		wound_ang = timer_ang
		bake_goal = float(o.get("goal", 1.0))
		bake_t = Xmas.oven_progress()
		phase = 2
		oven_a = 1.0
		heat_lvl = 0.86
		heated = true
		tray_p = oven_c + OVEN_SHELF
		tray_s = TRAY_IN
		tray_tilt = 1.0
		tray_front = false
		for c: Dictionary in tray_cook:
			c.placed = true
		_set_clip(false)
		heat.visible = not Ui.reduce_motion()
		_hum_update()
		_bake_hint()
		_show_main("xmas.cookie.btn.play", "sage")
		btn_main.position = Vector2(cx - 310.0, root.size.y - 165.0)
		return
	if int(Dev.env("SNUG_COOKIE_STEP")) == 4 and Dev.env("SNUG_COOKIE_INTRO") == "":
		bake_t = float(Dev.env("SNUG_COOKIE_BAKE")) if Dev.env("SNUG_COOKIE_BAKE") != "" else 0.5
		phase = 2
		oven_a = 1.0
		tray_p = oven_c + OVEN_SHELF
		tray_s = TRAY_IN
		tray_tilt = 1.0
		tray_front = false
		for c: Dictionary in tray_cook:
			c.placed = true
		_set_clip(false)
		heat.visible = not Ui.reduce_motion()
		for c: Dictionary in tray_cook:
			c.pop = 1.0
		temp = TEMP_IDEAL
		temp_set = true
		minutes = 10
		timer_set = true
		temp_ang = 0.0
		timer_ang = 0.0
		heat_lvl = 0.86
		heated = true
		_calc_goal()
		if Dev.env("SNUG_COOKIE_SETUP") != "":
			phase = 5
			bake_t = 0.0
			heat_lvl = 0.3
			heated = false
			temp_set = false
			timer_set = false
			temp_ang = -135.0
			timer_ang = -135.0
			heat.visible = false
			_set_hint("xmas.cookie.hint.temp")
		else:
			_set_hint("xmas.cookie.hint.baking")
		return
	# 0) yerleştirme: kurabiyeler tezgâhta, tepsi büyük ve ortada; oyuncu sürükleyip dizer
	phase = 6
	_set_hint("xmas.cookie.hint.place")
	if not tray_cook.is_empty():
		_coach("place", "drag", tray_cook[0].home, tray_p)
	for k in tray_cook.size():
		var c: Dictionary = tray_cook[k]
		c.pop = 0.0
		var tw0 := create_tween()
		tw0.tween_interval(_d(0.08 * k))
		_tw(tw0, c, "pop", 1.0, _d(0.3))
		tw0.tween_callback(func() -> void:
			_snd("felt_pop", "place", 0.9 + k * 0.06, -6.0)
			_hap("tick"))
	if Dev.env("SNUG_COOKIE_PLACED") != "":
		for c: Dictionary in tray_cook:
			c.placed = true
		_tray_go()

## Fırına ver: tepsi açılı yatırılıp fırın ağzına getirilir, raya oturtulup içeri itilir.
func _tray_go() -> void:
	_busy = true
	phase = 1
	btn_main.visible = false
	var tw := create_tween()
	tw.tween_interval(_d(0.15))
	tw.tween_property(self, "oven_a", 1.0, _d(0.5))
	# kapak açılır (menteşe sesi)
	tw.tween_callback(func() -> void: _snd("oven_door", "paper_fold", 0.55, -2.0))
	tw.tween_property(self, "door", 1.0, _d(0.7)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# eldiven + tepsi içeri kayar (perspektif küçülme)
	tw.tween_callback(func() -> void:
		_snd("rustle", "place", 0.7, -2.0)
		_set_hint("xmas.cookie.hint.baking"))
	tw.tween_property(self, "mitt_a", 1.0, _d(0.25))
	# 1) tepsi eldivenle kaldırılıp açılı yatırılır (fırın ağzına hizalanır)
	tw.tween_callback(func() -> void:
		_snd("knob_click", "click", 0.7, -6.0)
		_hap("light"))
	tw.tween_property(self, "tray_tilt", 1.0, _d(0.45)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(self, "tray_p", oven_c + OVEN_SHELF + Vector2(0, 330.0), _d(0.45)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(self, "tray_s", 0.85, _d(0.45))
	# 2) raya oturup içeri itilir: metal sürtme dokusu + ritmik tık titreşimi
	tw.tween_callback(func() -> void:
		tray_front = false
		_snd("place", "place", 0.6, -2.0)
		_hap("medium")
		Asmr.stitch_run(self, 6, 0.1, "tick")
		_snd("rustle", "place", 0.55, -2.0))
	tw.tween_property(self, "tray_p", oven_c + OVEN_SHELF, _d(0.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(self, "tray_s", TRAY_IN, _d(0.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_snd("knob_click", "click", 0.5, -2.0)
		_hap("heavy"))
	tw.tween_property(self, "mitt_a", 0.0, _d(0.3))
	tw.tween_callback(func() -> void: _set_clip(false))
	tw.tween_callback(func() -> void: _snd("place", "place", 0.7, 0.0))
	tw.tween_property(self, "door", 0.0, _d(0.6)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_snd("snap", "place", 0.8, -2.0)
		_hap("medium")
		phase = 5
		_set_hint("xmas.cookie.hint.temp")
		var sr := _slider_rect(0)
		_coach("slide", "drag", Vector2(sr.position.x + 50.0, sr.get_center().y), Vector2(sr.position.x + sr.size.x * 0.5, sr.get_center().y))
		_busy = false)

## İç lamba: fırın ısınırken/pişirirken yanar (ısı seviyesine göre), hafif titrer.
func _oven_lit() -> float:
	if not (phase in [2, 5]) or not temp_set:
		return 0.0
	var on := clampf(0.35 + heat_lvl * 0.8, 0.0, 1.0)
	return on * (0.96 + 0.04 * sin(t * 13.0) * sin(t * 3.7))

func _glow() -> float:
	var g := 0.15 + 0.75 * heat_lvl
	return clampf(g + flash * 0.4 + 0.06 * sin(t * 7.0) * (1.0 if phase == 2 else 0.0), 0.0, 1.2)

func _draw_oven(l: Control) -> void:
	l.modulate.a = oven_a
	if tx("oven_closed") != null:
		var r := Rect2(oven_c + OVEN_WIN.position, OVEN_WIN.size)
		l.draw_rect(r, Color(0.2, 0.09, 0.06))
		# Kapalı kapı camından fırının içi (raflar) görünür; çalışırken iç lamba yanar.
		var oo := tx("oven_open")
		if oo and door < 0.99:
			var lit := _oven_lit()
			var b := lerpf(0.22, 1.0, lit)
			var warm := Color(b, lerpf(0.2, 0.95, lit) * (0.92 + 0.08 * lit), lerpf(0.2, 0.85, lit) * 0.95)
			var k := oo.get_width() / OVEN_IMG.x
			var src := Rect2(OVEN_INNER.position * k, OVEN_INNER.size * k)
			l.draw_texture_rect_region(oo, r, src, warm)
		# Açık fırın tepsinin ARKASINDA (iç kısmı opak); kapalı fırın camın önünde.
		if tx("oven_open") != null and door > 0.01:
			_img(l, "oven_open", oven_c, OVEN_IMG.x, door)
		return
	l.draw_set_transform(oven_c, 0.0, Vector2.ONE)
	Art.flat = true
	Art.oven_body(l, _glow(), 0.0, OVEN_WIN)
	Art.flat = false

func _draw_glow(l: Control) -> void:
	var g := _glow()
	var breathe := 0.75 + 0.25 * sin(t * 2.0)
	_img(l, "oven_glow", oven_c + OVEN_WIN.position + OVEN_WIN.size / 2.0, OVEN_WIN.size.x * 1.0, clampf(g * breathe, 0.0, 1.0))

## Tepsi yerel noktası → ekran (perspektif yatırma: arka kenar dar ve basık).
func _tray_pt(q: Vector2) -> Vector2:
	var h := TRAY_SIZE.y * 1.08
	var v := clampf(q.y / h + 0.5, 0.0, 1.0)            # 0 arka, 1 ön
	var wk := 1.0 - TILT_TAPER * tray_tilt * (1.0 - v)
	var hk := 1.0 - TILT_SQUASH * tray_tilt
	return tray_p + Vector2(q.x * wk, q.y * hk) * tray_s

func _table_pos() -> Vector2:
	return Vector2(cx, _table_y(-0.03))

## Tezgâh (masa) hizası: kitchen_bg'de masa üst kenarı ekranın ~%47'si → nesneler masanın üstünde.
func _table_y(off: float) -> float:
	return minf(root.size.y * (0.6 + off), y1 - 520.0)

func _draw_tray(l: Control) -> void:
	if not tray_front:
		_tray_core(l)

func _draw_tray_front(l: Control) -> void:
	if tray_front:
		_tray_core(l)
	# tezgâhta bekleyen / sürüklenen kurabiyeler
	if step == 4 and phase == 6:
		var cs := _cookie_size() * TRAY_TABLE
		for c: Dictionary in tray_cook:
			if not c.placed:
				var lift := 1.12 if c == _drag_c else 1.0
				if c == _drag_c:
					_img(l, "cookie_raw_" + SHAPE_NAMES[c.s], c.sp + Vector2(0, 24), cs * 1.12 * lift, 0.25)
				_cookie(l, c.s, c.sp, cs * clampf(c.pop, 0.0, 1.3) * lift, 0.0, c.jit)
		l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## tray_in.png (1100×520, önden 3/4) iç taban dörtgeni: sol-arka, sağ-arka, sağ-ön, sol-ön (px, içe 18px pay)
const TRAY_IN_FLOOR := [Vector2(218, 176), Vector2(862, 176), Vector2(960, 302), Vector2(136, 302)]
const TRAY_IN_SQUASH := 0.5   ## önden görünüşte kurabiye basıklığı

## Tepsi yerel noktası (üstten) → 3B tepsi tabanında ekran noktası (tray_p merkezli).
func _tray3d_pt(q: Vector2) -> Vector2:
	var b := _bed()
	var u := clampf((q.x - b.position.x) / b.size.x, 0.0, 1.0)
	var v := clampf((q.y - b.position.y) / b.size.y, 0.0, 1.0)
	var back: Vector2 = TRAY_IN_FLOOR[0].lerp(TRAY_IN_FLOOR[1], u)
	var front: Vector2 = TRAY_IN_FLOOR[3].lerp(TRAY_IN_FLOOR[2], u)
	var px := back.lerp(front, v)
	var k := _tray3d_k()
	return tray_p + (px - Vector2(550, 260)) * k

func _tray3d_k() -> float:
	return TRAY_SIZE.x * 1.08 * tray_s / 1100.0

func _tray_core(l: Control) -> void:
	var tt := tx("tray")
	var t3 := tx("tray_in")
	var a3 := smoothstep(0.25, 0.75, tray_tilt) if t3 else 0.0
	l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# üstten tepsi (masada), yatırılırken basıklaşıp 3B görünüşe geçer
	if tt and a3 < 0.999:
		var w := TRAY_SIZE.x * 1.08 * tray_s
		var h := w * tt.get_height() / tt.get_width() * (1.0 - TILT_SQUASH * tray_tilt)
		l.draw_texture_rect(tt, Rect2(tray_p - Vector2(w, h) / 2.0, Vector2(w, h)), false, Color(1, 1, 1, 1.0 - a3))
	elif not tt:
		l.draw_set_transform(tray_p, 0.0, Vector2.ONE * tray_s)
		Art.tray(l, TRAY_SIZE)
		l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if a3 > 0.001:
		var k := _tray3d_k()
		var sz := Vector2(1100, 520) * k
		l.draw_texture_rect(t3, Rect2(tray_p - sz / 2.0, sz), false, Color(1, 1, 1, a3))
	# kurabiyeler: arkadan öne çiz (öndekiler üstte)
	var order: Array = []
	for c: Dictionary in tray_cook:
		if c.get("placed", true):
			order.append(c)
	order.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.p.y < y.p.y)
	for c: Dictionary in order:
		var pop := clampf(c.pop, 0.0, 1.3)
		var flat: Vector2 = tray_p + c.p * tray_s * Vector2(1.0, 1.0 - TILT_SQUASH * tray_tilt)
		var sp := flat
		var cs := _cookie_size() * pop * tray_s
		var sy := 1.0 - TILT_SQUASH * tray_tilt
		if a3 > 0.0:
			var b := _bed()
			var v := clampf((c.p.y - b.position.y) / b.size.y, 0.0, 1.0)
			var depth := lerpf(0.84, 1.0, v)   # arkadakiler biraz küçük
			sp = flat.lerp(_tray3d_pt(c.p), a3)
			cs *= lerpf(1.0, depth * 1.12, a3)
			sy = lerpf(sy, TRAY_IN_SQUASH, a3)
		# kurabiyenin tepsiye düşen gölgesi
		if a3 > 0.0:
			l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			l.draw_colored_polygon(Art.ell(sp + Vector2(0, cs * sy * 0.32), cs * 0.46, cs * sy * 0.22, 18), Color(0.15, 0.07, 0.02, 0.28 * a3))
		_cookie(l, c.s, sp - Vector2(0, cs * sy * 0.06 * a3), cs, clampf(bake_t * bake_goal, 0.0, 1.9), c.jit, sy)
	l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if mitt_a > 0.01:
		var mp := tray_p + Vector2(0, TRAY_SIZE.y * 0.5 * tray_s + 40.0 * tray_s)
		if not _img(l, "oven_mitt", mp, MITT_SIZE * tray_s * 1.2, mitt_a):
			l.draw_set_transform(mp, 0.0, Vector2.ONE * tray_s)
			Art.felt_rr(l, Rect2(-120, -60, 240, 170), 60.0, Palette.TERRACOTTA, Art.F_ROSE, 8.0, Color(1, 1, 1, mitt_a), 12.0, 3)
			l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_glass(l: Control) -> void:
	if oven_a < 0.01:
		return
	l.modulate.a = oven_a
	if tx("oven_closed") != null:
		var w := OVEN_IMG.x
		_img(l, "oven_closed", oven_c, w, 1.0 - door if tx("oven_open") != null else 1.0)
		return
	l.draw_set_transform(oven_c, 0.0, Vector2.ONE)
	for e: Dictionary in embers:
		l.draw_circle(e.p, e.r, Color(1.0, 0.7, 0.3, e.life * 0.8))
	Art.flat = true
	Art.oven_glass(l, t, flash, door, OVEN_WIN)
	Art.flat = false

func _embers_tick(dt: float) -> void:
	if phase == 2 and randf() < dt * 14.0:
		embers.append({"p": Vector2(randf_range(OVEN_WIN.position.x + 30.0, OVEN_WIN.end.x - 30.0), OVEN_WIN.end.y - 10.0), "v": randf_range(60.0, 130.0), "r": randf_range(2.0, 5.0), "life": 1.0})
	for e: Dictionary in embers:
		e.p.y -= e.v * dt
		e.p.x += sin(t * 3.0 + e.v) * 18.0 * dt
		e.life -= dt * 0.8
	embers = embers.filter(func(e: Dictionary) -> bool: return e.life > 0.0 and e.p.y > OVEN_WIN.position.y)

func _bake_hint() -> void:
	hint.text = _t("xmas.cookie.hint.bakingBoost") % int(Xmas.oven().get("pct", 5))

func _bake_tick(dt: float) -> void:
	if Xmas.oven_busy():
		bake_t = Xmas.oven_progress()
	else:
		bake_t = minf(1.0, bake_t + dt / bake_dur)
	timer_ang = lerpf(wound_ang, -135.0, bake_t)
	var sec := Xmas.oven_seconds_left() if Xmas.oven_busy() else int(bake_t * bake_dur)
	if sec != _last_sec:
		_last_sec = sec
		_snd("tick", "click", 1.0 if sec % 2 == 0 else 0.85, -9.0)
	_snd_crack -= dt
	if _snd_crack <= 0.0:
		_snd_crack = randf_range(0.5, 1.0)
		_snd("crackle", "click", randf_range(0.9, 1.2), -9.0)
	if bake_t >= 1.0:
		phase = 3
		_busy = true
		flash = 1.0
		_snd("ding", "reward", 1.0, -2.0)
		_snd("bell", "levelUp", 1.0, -4.0)
		_hap("success")
		_hum_stop()
		# Sonuç: bölgede → mükemmel (%10 bonus), yakın → iyi (%5), çiğ/yanık → bonus yok
		cur.bake = bake_goal
		state.cur = cur
		var kind := _doneness_kind(bake_goal)
		Xmas.clear_oven()
		btn_main.visible = false
		if kind == 0:
			hint.text = _t("xmas.cookie.perfect" if _in_zone() else "xmas.cookie.good")
		else:
			hint.text = _t("xmas.cookie.raw" if kind < 0 else "xmas.cookie.burnt")
			_hap("medium")
		Xmas.save()
		heat.visible = false
		var tw := create_tween()
		tw.tween_interval(_d(0.8))
		tw.tween_callback(func() -> void:
			_set_clip(true)
			_snd("oven_door", "paper_fold", 0.55, -2.0))
		tw.tween_property(self, "door", 1.0, _d(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "mitt_a", 1.0, _d(0.25))
		tw.tween_callback(func() -> void:
			_snd("rustle", "place", 0.6, -2.0)
			Asmr.stitch_run(self, 5, 0.1, "tick"))
		tw.tween_property(self, "tray_p", oven_c + OVEN_SHELF + Vector2(0, 330.0), _d(0.7)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(self, "tray_s", 0.85, _d(0.7))
		tw.tween_callback(func() -> void: tray_front = true)
		tw.tween_property(self, "tray_tilt", 0.0, _d(0.45)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(self, "tray_p", _table_pos(), _d(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "tray_s", TRAY_TABLE, _d(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "mitt_a", 0.0, _d(0.3))
		tw.tween_property(self, "door", 0.0, _d(0.5))
		tw.parallel().tween_property(self, "oven_a", 0.0, _d(0.6))
		tw.tween_callback(func() -> void:
			_busy = false
			_show_main("xmas.cookie.btn.decorate", "terracotta"))

var _hum_p: AudioStreamPlayer

## Fırın uğultusu: kendi döngülü oynatıcısı; ısı arttıkça yükselir.
func _hum_update() -> void:
	if Dev.env("SNUG_MUTE") != "" or Settings.get_value("asmr") == false or not Settings.sfx_enabled:
		return
	if _hum_p == null:
		var st: AudioStream = load("res://audio/sfx/oven_hum.wav") if ResourceLoader.exists("res://audio/sfx/oven_hum.wav") else null
		if st == null:
			return
		if st is AudioStreamWAV:
			(st as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		_hum_p = AudioStreamPlayer.new()
		_hum_p.stream = st
		add_child(_hum_p)
	_hum_p.volume_db = linear_to_db(clampf(heat_lvl * 0.6 * Sfx.sfx_volume, 0.001, 1.0))
	_hum_p.pitch_scale = 0.85 + heat_lvl * 0.3
	if not _hum_p.playing:
		_hum_p.play()

func _hum_stop() -> void:
	if _hum_p and _hum_p.playing:
		_hum_p.stop()

func _exit_tree() -> void:
	_hum_stop()

var _covered := false
func on_cover(covered: bool) -> void:
	super.on_cover(covered)
	_covered = covered
	if covered:
		_hum_stop()

func _calc_goal() -> void:
	var tf := float(temp - TEMP_MIN) / float(TEMP_MAX - TEMP_MIN)
	var mf := float(minutes - MIN_LO) / float(MIN_HI - MIN_LO)
	# Isı × süre: 180°×10 dk = 1.0 (altın). Bölgede → mükemmel; azı çiğ (<0.8), fazlası yanık (>1.2).
	if _in_zone():
		bake_goal = 1.0
	else:
		bake_goal = clampf((float(temp) / TEMP_IDEAL) * (float(minutes) / 10.0), 0.3, 1.9)

func _in_zone() -> bool:
	return temp >= ZONE_T.x and temp <= ZONE_T.y and minutes >= ZONE_M.x and minutes <= ZONE_M.y

## 0 mükemmel, -1 çiğ, 1 yanık (0.8..1.2 arası bölge dışı = "iyi")
func _doneness_kind(g: float) -> int:
	return -1 if g < 0.8 else (1 if g > 1.2 else 0)

func _knob_pos(i: int) -> Vector2:
	return oven_c + (KNOB_TEMP if i == 0 else KNOB_TIMER)

func _knob_deg(p: Vector2, c: Vector2) -> float:
	var d := p - c
	return clampf(rad_to_deg(atan2(d.x, -d.y)), -135.0, 135.0)

func _slider_rect(i: int) -> Rect2:
	var th := KNOB_SIZE * 0.4
	return Rect2(oven_c + Vector2(-SLIDER_W / 2.0 + 60.0, _slider_cy(i) - th / 2.0), Vector2(SLIDER_W, th))

func _slider_v(i: int) -> float:
	if i == 0:
		return float(temp - TEMP_MIN) / float(TEMP_MAX - TEMP_MIN) if temp_set else 0.0
	return float(minutes - MIN_LO) / float(MIN_HI - MIN_LO) if timer_set else 0.0

func _bake_down(p: Vector2) -> void:
	if phase == 6:
		var best = null
		var bd := 1e9
		for c: Dictionary in tray_cook:
			var cp: Vector2 = c.sp if not c.placed else _tray_pt(c.p)
			var d := p.distance_to(cp)
			if d < _cookie_size() * TRAY_TABLE * 0.6 and d < bd:
				bd = d
				best = c
		if best != null:
			_drag_c = best
			if best.placed:
				best.placed = false
				best.sp = _tray_pt(best.p)
			_drag_off = best.sp - p
			_snd("rustle", "click", 1.3, -6.0)
			_hap("tick")
			_refresh_place()
		return
	if phase == 5:
		for i in 2:
			if _slider_rect(i).grow_individual(KNOB_SIZE * 0.5, KNOB_SIZE * 0.3, KNOB_SIZE * 0.5, KNOB_SIZE * 0.3).has_point(p):
				slide_drag = i
				_slide_x = p.x
				Asmr.hit("sizzle", "light", "click", 0.9, -6.0)
				_bake_move(p)
				return
		for i in 2:
			if p.distance_to(_knob_pos(i)) < KNOB_HIT:
				knob_drag = i
				_bake_move(p)
				return
	if phase in [2, 5] and OVEN_WIN.grow(60.0).has_point(p - oven_c):
		flash = 1.0
		_snd("chime", "click", 1.9, -10.0)
		_hap("tick")
	elif phase == 2:
		flash = 0.6
		_hap("tick")

func _bake_move(p: Vector2) -> void:
	if phase == 6 and _drag_c != null:
		var d: Vector2 = p + _drag_off - _drag_c.sp
		_drag_c.sp = p + _drag_off
		Asmr.stroke(self, "cdrag", d.length(), 90.0, "rustle", "", 1.3)
		return
	if phase != 5 or (knob_drag < 0 and slide_drag < 0):
		return
	var which := knob_drag
	var deg := 0.0
	if slide_drag >= 0:
		which = slide_drag
		var r := _slider_rect(slide_drag)
		var gk := r.size.y / 64.0
		var sv := clampf((p.x - r.position.x - TRACK_CAP * gk) / (r.size.x - TRACK_CAP * gk * 2.0), 0.0, 1.0)
		deg = -135.0 + sv * 270.0
		# Cızırtı: parmak kaydıkça çıtırtılı ses tanesi + pürüzlü titreşim (hıza göre perde).
		slide_vis[slide_drag] = sv
		Asmr.stroke(self, "slide", p.x - _slide_x, 16.0, "sizzle", "tick", 0.85 + sv * 0.35)
		_slide_x = p.x
	else:
		deg = _knob_deg(p, _knob_pos(knob_drag))
	var v := (deg + 135.0) / 270.0
	if which == 0:
		var step := int(roundf(v * 8.0))
		var nt := TEMP_MIN + step * 10
		var sa := -135.0 + step / 8.0 * 270.0
		temp_ang = sa if nt == TEMP_IDEAL else sa + clampf(deg - sa, -9.0, 9.0) * 0.5
		if nt != temp:
			temp = nt
			temp_set = true
			heated = false
			_snd("knob_click", "click", 0.85 + step * 0.07, -3.0)
			_hap("tick")
			if nt >= ZONE_T.x and nt <= ZONE_T.y:
				# doğru bölgede: ılık çan + yumuşak titreşim
				_hap("light")
				_snd("chime", "click", 1.4 + (nt - ZONE_T.x) * 0.01, -10.0)
			if not pending_start:
				_set_hint("xmas.cookie.hint.timer")
	else:
		var m := MIN_LO + int(roundf(v * float(MIN_HI - MIN_LO)))
		timer_ang = -135.0 + float(m - MIN_LO) / float(MIN_HI - MIN_LO) * 270.0
		if m != minutes or not timer_set:
			minutes = m
			timer_set = true
			_snd("timer_wind", "click", 0.8 + (m - MIN_LO) * 0.05, -4.0)
			_hap("tick")
			if m >= ZONE_M.x and m <= ZONE_M.y:
				_hap("light")
				_snd("chime", "click", 1.5 + (m - ZONE_M.x) * 0.03, -10.0)

func _place_drop(c: Dictionary) -> void:
	var lay := _tray_layout(tray_cook.size())
	var b := _bed().grow(60.0)
	var local: Vector2 = (c.sp - tray_p) / tray_s
	if b.has_point(local):
		# en yakın boş yuvaya otur
		var used := {}
		for o: Dictionary in tray_cook:
			if o.placed and o != c:
				used[int(o.slot)] = true
		var best := -1
		var bd := 1e9
		for i in lay.size():
			if used.has(i):
				continue
			var d: float = local.distance_to(lay[i])
			if d < bd:
				bd = d
				best = i
		if best >= 0:
			_coach_done("place")
			c.slot = best
			c.p = lay[best]
			c.placed = true
			c.pop = 1.25
			_tw(create_tween(), c, "pop", 1.0, _d(0.25))
			_snd("felt_pop", "place", randf_range(0.95, 1.15), -2.0)
			_hap("light")
			_refresh_place()
			return
	var tw := create_tween()
	tw.tween_method(func(v: Vector2) -> void: c.sp = v, c.sp, c.home, _d(0.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_snd("rustle", "click", 1.1, -8.0)

func _refresh_place() -> void:
	var all := true
	for c: Dictionary in tray_cook:
		if not c.placed:
			all = false
	if all and phase == 6:
		_show_main("xmas.cookie.btn.oven", "terracotta")
		btn_main.position = Vector2(cx - 310.0, root.size.y - 165.0)
		_set_hint("xmas.cookie.hint.toOven")
	elif phase == 6:
		btn_main.visible = false

func _bake_up(_p: Vector2) -> void:
	if phase == 6:
		if _drag_c != null:
			var c: Dictionary = _drag_c
			_drag_c = null
			Asmr.reset_stroke(self, "cdrag")
			_place_drop(c)
		return
	var k := knob_drag if knob_drag >= 0 else slide_drag
	knob_drag = -1
	if slide_drag >= 0:
		_coach_done("slide")
		Asmr.reset_stroke(self, "slide")
		# bırakınca tutamak en yakın değere yumuşakça oturur
		var si := slide_drag
		var from: float = slide_vis[si]
		var to := _slider_v(si)
		if from >= 0.0:
			var tw := create_tween()
			tw.tween_method(func(v: float) -> void: slide_vis[si] = v, from, to, _d(0.18)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func() -> void: slide_vis[si] = -1.0)
			_snd("knob_click", "click", 1.1, -6.0)
	slide_drag = -1
	if k == 1 and timer_set and phase == 5:
		if not temp_set:
			temp = TEMP_IDEAL
			temp_set = true
			temp_ang = 0.0
			heated = false
		pending_start = true
		_set_hint("xmas.cookie.hint.heating")
		_hap("light")

func _heat_tick(dt: float) -> void:
	var tf := float(temp - TEMP_MIN) / float(TEMP_MAX - TEMP_MIN)
	var target := (0.35 + 0.65 * tf) if temp_set else 0.1
	var rate := 0.3 if not Ui.reduce_motion() else 1.5
	var before := heat_lvl
	heat_lvl = move_toward(heat_lvl, target, dt * rate)
	_hum_update()
	if heat_lvl < target - 0.001:
		pass
	elif not heated and before != heat_lvl or (not heated and absf(heat_lvl - target) < 0.001 and temp_set):
		heated = true
		_snd("chime", "click", 1.7, -6.0)
		_hap("light")
	if phase == 5 and pending_start and heated:
		pending_start = false
		_calc_goal()
		wound_ang = timer_ang
		bake_t = 0.0
		_last_sec = -1
		phase = 2
		heat.visible = not Ui.reduce_motion()
		# Gerçek zamanlı: ayarlanan dakika kadar pişer; bu sürede bölüm oynayana +%10/%5 XP ve düğme.
		var pct := 10 if _in_zone() else 5
		Xmas.start_oven(minutes, pct, bake_goal)
		var o := Xmas.oven()
		o.temp = temp
		o.minutes = minutes
		Xmas.save()
		_bake_hint()
		_show_main("xmas.cookie.btn.play", "sage")
		btn_main.position = Vector2(cx - 310.0, root.size.y - 165.0)
		_hap("medium")
		_snd("oven_door", "click", 1.2, -6.0)

func _draw_knobs(l: Control) -> void:
	if oven_a < 0.01 or phase == 0:
		return
	l.modulate.a = oven_a
	var f := Ui.FONT
	for i in 2:
		var c := _knob_pos(i)
		var ang := temp_ang if i == 0 else timer_ang
		if tx("oven_closed") != null:
			pass  # kadran çizgileri fırın görselinde
		elif i == 0:
			if not _img(l, "dial_temp_face", c, DIAL_SIZE):
				for k in 9:
					var a := deg_to_rad(-135.0 + k * 33.75)
					var dir := Vector2(sin(a), -cos(a))
					l.draw_line(c + dir * 78.0, c + dir * (96.0 if k == 4 else 88.0), Palette.CREAM, 5.0 if k == 4 else 3.0, true)
		else:
			for k in 11:
				var a := deg_to_rad(-135.0 + k * 27.0)
				var dir := Vector2(sin(a), -cos(a))
				l.draw_line(c + dir * 78.0, c + dir * 88.0, Palette.CREAM, 3.0, true)
		if not _img(l, "knob_temp" if i == 0 else "knob_timer", c, KNOB_SIZE, 1.0, deg_to_rad(ang)):
			l.draw_circle(c + Vector2(0, 7), 62.0, Palette.SHADOW)
			l.draw_circle(c, 62.0, Palette.CARD.darkened(0.3))
			l.draw_circle(c + Vector2(0, -3), 58.0, Palette.CARD)
			l.draw_arc(c + Vector2(0, -3), 46.0, 0, TAU, 32, Palette.STITCH_DARK, 3.0, true)
			var d := Vector2(sin(deg_to_rad(ang)), -cos(deg_to_rad(ang)))
			l.draw_line(c + d * 12.0, c + d * 50.0, Palette.TERRACOTTA, 9.0, true)
		var txt := ("%d°" % temp) if (i == 0 and temp_set) else (("%d" % minutes) if (i == 1 and timer_set) else "")
		if i == 1 and phase == 2:
			txt = "%d" % ceili(float(minutes) * (1.0 - bake_t))
		if txt != "":
			var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 36)
			l.draw_string_outline(f, c + Vector2(-sz.x / 2.0, 118.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, 8, Palette.INK)
			l.draw_string(f, c + Vector2(-sz.x / 2.0, 118.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Palette.CREAM)
	if phase == 5:
		_draw_sliders(l)
	if phase == 2 and Xmas.oven_busy():
		_draw_countdown(l)
	# fırın lambası
	var lp := oven_c + LIGHT_POS
	if tx("oven_light") != null:
		_img(l, "oven_light", lp, LIGHT_SIZE * 0.6, clampf(heat_lvl * (0.85 + 0.15 * sin(t * 3.0)), 0.0, 1.0))
	else:
		var a := clampf(heat_lvl, 0.0, 1.0)
		l.draw_circle(lp, 20.0, Palette.CARD.darkened(0.3))
		l.draw_circle(lp, 15.0, Palette.GOLD.lerp(Color(1, 0.95, 0.7), a) if heated else Palette.LOCKED.lerp(Palette.FLAME, a))
		if a > 0.2:
			l.draw_circle(lp, 34.0, Color(1.0, 0.75, 0.3, 0.18 * a))

# ------------------------------------------------------------------ 5 Süsle / 6 Tabak

func _plate_layout(n: int) -> Array:
	# (x, y, boyut) tabak yarıçapı biriminde
	var out: Array = []
	if n <= 0:
		return out
	if n == 1:
		return [Vector3(0, 0, 0.7)]
	var ring_n := n
	var center := false
	if n == 7:
		ring_n = 6
		center = true
	elif n == 8:
		ring_n = 7
		center = true
	var rho := 0.5 if n <= 3 else (0.54 if n <= 5 else (0.62 if n == 6 else 0.7))
	var sz := 0.62 if n <= 3 else (0.54 if n <= 5 else (0.5 if n == 6 else (0.44 if n == 7 else 0.4)))
	for i in ring_n:
		var a := -PI / 2 + TAU * i / ring_n
		out.append(Vector3(cos(a) * rho, sin(a) * rho, sz))
	if center:
		out.append(Vector3(0, 0, sz))
	return out

func _build_decor(final: bool, resume := false) -> void:
	var zh := y1 - y0
	plate_r = minf(465.0, (zh - (0.0 if final else 300.0)) / 2.0)
	plate_c = Vector2(cx, minf(_table_y(-0.02), y1 - 230.0 - plate_r))
	if final:
		plate_c.y = minf(_table_y(-0.04), y1 - 120.0 - plate_r)
	ink = 0
	mode = 0
	_snd_ice = 0.0
	if not final:
		strokes = _decode_strokes(cur.get("strokes", []))
		sprinkles = (cur.get("sprinkles", []) as Array).duplicate(true) if cur.get("sprinkles") is Array else []
		spr_age = []
		for i in sprinkles.size():
			spr_age.append(1.0)
		history.clear()
	else:
		var last: Dictionary = state.get("last", {})
		var src_shapes: Array = last.get("shapes", [])
		if resume or cur.is_empty() or _saved_shapes().is_empty():
			cur = {"shapes": src_shapes, "strokes": last.get("strokes", []), "sprinkles": last.get("sprinkles", [])}
		strokes = _decode_strokes(cur.get("strokes", []))
		sprinkles = (cur.get("sprinkles", []) as Array).duplicate(true) if cur.get("sprinkles") is Array else []
		spr_age = []
		for i in sprinkles.size():
			spr_age.append(1.0)
	_layer(stage, _draw_decor.bind(final))
	if not final:
		_layer(stage, _draw_tools)
		btn_undo.visible = true
		btn_undo.position = Vector2(root.size.x - 160.0, y1 - 150.0)
		_show_main("xmas.cookie.btn.plate", "terracotta")
		_set_hint("xmas.cookie.hint.decorate")
		_coach("decor", "swipe", plate_c + Vector2(-150, -40), plate_c + Vector2(150, 30))
		_refresh_tools()
	else:
		_set_hint("xmas.cookie.hint.last" if resume else "xmas.merry")
		_show_main("xmas.cookie.btn.new", "sage")

func _refresh_tools() -> void:
	tool_pos.clear()
	for i in 5:
		tool_pos.append(Vector2(cx - 340.0 + i * 140.0 - 70.0, y1 - 100.0))
	btn_undo.disabled = history.is_empty()

func _draw_decor(l: Control, final: bool) -> void:
	if not _img(l, "plate", plate_c, plate_r * PLATE_IMG_K):
		Art.plate(l, plate_c, plate_r)
	var shapes := _saved_shapes() if not final else (cur.get("shapes", []) as Array)
	var lay := _plate_layout(shapes.size())
	for i in shapes.size():
		var v: Vector3 = lay[i]
		var cp := plate_c + Vector2(v.x, v.y) * plate_r
		_cookie(l, int(shapes[i].s), cp, v.z * plate_r * 1.0, float(cur.get("bake", 1.0)), float(i % 3) * 0.04 - 0.04)
	for si in strokes.size():
		var s: Dictionary = strokes[si]
		var px := PackedVector2Array()
		for q: Vector2 in s.pts:
			px.append(plate_c + q * plate_r)
		_icing(l, px, s.c, plate_r * 0.075, si == strokes.size() - 1 and _icing_live)
	for i in sprinkles.size():
		var sp: Array = sprinkles[i]
		var age: float = spr_age[i] if i < spr_age.size() else 1.0
		Art.sprinkle(l, plate_c + Vector2(sp[0], sp[1]) * plate_r, sp[2], int(sp[3]), clampf(age, 0.0, 1.0))
	for i in spr_age.size():
		spr_age[i] = minf(1.0, spr_age[i] + 0.12)

func _draw_tools(l: Control) -> void:
	Art.felt_rr(l, Rect2(Vector2(cx - 440.0, y1 - 200.0), Vector2(880, 190)), 50.0, Palette.TRAY, Art.F_PEACH, 8.0, Color(0.95, 0.88, 0.8), 16.0, 5)
	for i in tool_pos.size():
		var c: Vector2 = tool_pos[i] + Vector2(70, 0)
		if i < 3:
			var sel := mode == 0 and ink == i
			if not _img(l, "icing_bag_" + ["white", "red", "green"][i], c + Vector2(0, -16.0 if sel else 0.0), BAG_SIZE):
				Art.bag(l, c, 150.0, i, sel)
			elif sel:
				l.draw_arc(c + Vector2(0, -10), 90.0, 0, TAU, 40, Color(Palette.CREAM, 0.9), 5.0, true)
		elif i == 3:
			Art.jar(l, c, 150.0, mode == 1)

func _decode_strokes(a: Variant) -> Array:
	var out: Array = []
	if a is Array:
		for s: Dictionary in a:
			var pts := PackedVector2Array()
			var f: Array = s.get("pts", [])
			for i in range(0, f.size() - 1, 2):
				pts.append(Vector2(float(f[i]), float(f[i + 1])))
			if pts.size() > 0:
				out.append({"c": int(s.get("c", 0)), "pts": pts})
	return out

func _encode_strokes() -> Array:
	var out: Array = []
	for s: Dictionary in strokes:
		var f: Array = []
		for q: Vector2 in s.pts:
			f.append(snappedf(q.x, 0.001))
			f.append(snappedf(q.y, 0.001))
		out.append({"c": s.c, "pts": f})
	return out

func _in_plate(p: Vector2) -> bool:
	return p.distance_to(plate_c) < plate_r * 0.98

func _decor_down(p: Vector2) -> void:
	for i in 4:
		if tool_pos.size() > i and absf(p.x - (tool_pos[i].x + 70.0)) < 70.0 and absf(p.y - tool_pos[i].y) < 100.0:
			if i < 3:
				mode = 0
				ink = i
			else:
				mode = 1
			_snd("rustle", "click", 1.2, -6.0)
			_hap("tick")
			return
	if not _in_plate(p):
		return
	if mode == 0:
		_coach_done("decor")
		strokes.append({"c": ink, "pts": PackedVector2Array([(p - plate_c) / plate_r])})
		_icing_live = true
		Asmr.reset_stroke(self, "ice")
		_hap("light")
		_snd("icing", "click", randf_range(0.95, 1.1), -4.0)
		_snd_ice = 0.0
	else:
		history.append({"k": "s", "n": 0})
		_last_spr = p
		_scatter(p)

func _decor_move(p: Vector2) -> void:
	if not _in_plate(p):
		return
	if mode == 0 and not strokes.is_empty():
		var pts: PackedVector2Array = strokes[strokes.size() - 1].pts
		var q := (p - plate_c) / plate_r
		if pts.size() == 0 or (q - pts[pts.size() - 1]).length() * plate_r > 9.0:
			var d := 0.0 if pts.size() == 0 else (q - pts[pts.size() - 1]).length() * plate_r
			pts.append(q)
			strokes[strokes.size() - 1].pts = pts
			# krema sıkma dokusu: kısa aralıklı yumuşak tık + ıslak krema sesi
			Asmr.stroke(self, "ice", d, 34.0, "icing", "tick", randf_range(0.95, 1.1))
	elif mode == 1 and p.distance_to(_last_spr) > 34.0:
		_last_spr = p
		_scatter(p)

func _decor_up(_p: Vector2) -> void:
	_icing_live = false
	if mode == 0 and not strokes.is_empty():
		var s: Dictionary = strokes[strokes.size() - 1]
		if history.is_empty() or history[history.size() - 1].k != "i" or history[history.size() - 1].get("n", 0) != strokes.size():
			history.append({"k": "i", "n": strokes.size()})
		_persist()
	elif mode == 1:
		_persist()
	_refresh_tools()

func _scatter(p: Vector2) -> void:
	for i in 6:
		var q := p + Vector2.from_angle(randf() * TAU) * randf_range(8.0, 44.0)
		sprinkles.append([snappedf((q.x - plate_c.x) / plate_r, 0.001), snappedf((q.y - plate_c.y) / plate_r, 0.001), snappedf(randf() * PI, 0.01), randi() % 5])
		spr_age.append(0.2)
	history[history.size() - 1].n += 6 if history[history.size() - 1].k == "s" else 0
	_snd("sprinkle", "click", randf_range(1.3, 1.7), -4.0)
	_hap("tick")

func _undo() -> void:
	if history.is_empty() or step != 5:
		return
	var h: Dictionary = history.pop_back()
	if h.k == "i":
		if not strokes.is_empty():
			strokes.pop_back()
	else:
		for i in int(h.n):
			if not sprinkles.is_empty():
				sprinkles.pop_back()
				spr_age.pop_back()
	_snd("rustle", "place", 0.8, -4.0)
	_hap("light")
	_persist()
	_refresh_tools()

func _persist() -> void:
	cur.strokes = _encode_strokes()
	cur.sprinkles = sprinkles.duplicate(true)
	state.cur = cur
	Xmas.save()

func _finish() -> void:
	_persist()
	# kurabiye kavanozu: iyi/mükemmel tam sayılır, çiğ/yanık yarım
	var nck := _saved_shapes().size()
	Xmas.add_to_jar(nck if _doneness_kind(float(cur.get("bake", 1.0))) == 0 else nck / 2)
	state.last = {"shapes": _saved_shapes().duplicate(true), "strokes": cur.strokes.duplicate(true), "sprinkles": sprinkles.duplicate(true), "bake": float(cur.get("bake", 1.0))}
	state.batches = int(state.get("batches", 0)) + 1
	state.step = 6
	state.progress = minf(1.0, float(state.batches) / 5.0)
	Xmas.save()
	cur = {"shapes": state.last.shapes, "strokes": state.last.strokes, "sprinkles": state.last.sprinkles, "bake": state.last.get("bake", 1.0)}
	go_step(6)
	XmasKit.celebrate(self, area.position + Vector2(cx, 600.0))
	var pl: Layer = layers[layers.size() - 1] if layers.size() > 1 else null
	if pl:
		Ui.punch(pl, 0.03)

func _new_batch() -> void:
	state.step = 1
	state.erase("cur")
	cur = {}
	strokes.clear()
	sprinkles.clear()
	Xmas.save()
	go_step(1)

# ------------------------------------------------------------------ Geliştirme (yalnız debug)

func _dev_sample_shapes(n: int) -> Array:
	var out: Array = []
	var pos := [Vector2(0.2, 0.28), Vector2(0.5, 0.25), Vector2(0.8, 0.3), Vector2(0.26, 0.7), Vector2(0.55, 0.72), Vector2(0.83, 0.68)]
	for i in n:
		out.append({"s": [0, 1, 2, 3, 4, 0][i % 6], "x": pos[i % 6].x, "y": pos[i % 6].y})
	return out

func _dev_prepare(s: int) -> void:
	if s >= 4:
		cur = {"shapes": _dev_sample_shapes(6), "strokes": [], "sprinkles": []}
	elif s == 3:
		cur = {"shapes": _dev_sample_shapes(4), "strokes": [], "sprinkles": []}
	if s >= 5:
		var lay := _plate_layout(6)
		var strokes_a: Array = []
		var spr_a: Array = []
		for i in 6:
			var v: Vector3 = lay[i]
			var cc := Vector2(v.x, v.y)
			var f: Array = []
			var k := i % 3
			if i % 3 == 1:
				for j in 40:
					var a := j / 39.0 * TAU
					f.append(cc.x + cos(a) * v.z * 0.22)
					f.append(cc.y + sin(a) * v.z * 0.22)
			else:
				for j in 30:
					var u := j / 29.0
					f.append(cc.x - v.z * 0.26 + u * v.z * 0.52)
					f.append(cc.y + sin(u * TAU * 1.5) * v.z * 0.07)
			strokes_a.append({"c": (k + 1) % 3 if i < 5 else 0, "pts": f})
			for j in 5:
				spr_a.append([cc.x + randf_range(-0.2, 0.2) * v.z * 1.2, cc.y + randf_range(-0.2, 0.2) * v.z * 1.2, randf() * PI, randi() % 5])
		cur.strokes = strokes_a
		cur.sprinkles = spr_a
	if s == 6:
		state.last = {"shapes": cur.shapes, "strokes": cur.strokes, "sprinkles": cur.sprinkles}
		state.batches = 2

func _sim() -> void:
	await get_tree().create_timer(0.6).timeout
	match step:
		1:
			for i in 4:
				var h: Vector2 = items[i].home
				_down(h)
				_move(bowl_c)
				_up(bowl_c)
				await get_tree().create_timer(0.3).timeout
			_down(bowl_c + Vector2(200, 0))
			for j in 400:
				_move(bowl_c + Vector2.from_angle(j * 0.1) * 200.0)
				await get_tree().process_frame
			_up(bowl_c)
		2:
			_down(Vector2(cx, pin_y))
			for j in 600:
				_move(Vector2(cx, dough_c.y + sin(j * 0.07) * 380.0))
				await get_tree().process_frame
			_up(Vector2.ZERO)
		3:
			for p in [Vector2(-200, -100), Vector2(0, -100), Vector2(200, -100), Vector2(-100, 100), Vector2(100, 100)]:
				sel_cut = randi() % 5
				_down(dough_c + p)
				await get_tree().create_timer(0.1).timeout
			if Dev.env("SNUG_COOKIE_SIM") == "2":
				_on_main()


## Fırın altı ayar çubukları: ChatGPT emaye/bakır ray (slider_track.png, 3 parça) + dolgu +
## düğme tutamak (kaydırınca yuvarlanır: dönüş = yol / yarıçap) + derece/dakika ölçeği ve değer.
const TRACK_CAP := 32.0      ## slider_track.png uç kapak genişliği (px, 760×64 görselde)
const TRACK_GROOVE := Vector2(24.0, 38.0)  ## oluk y aralığı (görselde)

func _draw_sliders(l: Control) -> void:
	var f := Ui.FONT
	var tt := tx("slider_track")
	for i in 2:
		var r := _slider_rect(i)
		var v: float = slide_vis[i] if float(slide_vis[i]) >= 0.0 else _slider_v(i)
		var col := Color(0.86, 0.3, 0.2) if i == 0 else Color(0.45, 0.6, 0.28)
		l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var k := r.size.y / 64.0
		var gy0 := r.position.y + TRACK_GROOVE.x * k
		var gh := (TRACK_GROOVE.y - TRACK_GROOVE.x + 1.0) * k
		if tt:
			var cap := TRACK_CAP * k
			var tw_ := float(tt.get_width())
			l.draw_texture_rect_region(tt, Rect2(r.position, Vector2(cap, r.size.y)), Rect2(0, 0, TRACK_CAP, 64))
			l.draw_texture_rect_region(tt, Rect2(r.end.x - cap, r.position.y, cap, r.size.y), Rect2(tw_ - TRACK_CAP, 0, TRACK_CAP, 64))
			l.draw_texture_rect_region(tt, Rect2(r.position.x + cap, r.position.y, r.size.x - cap * 2.0, r.size.y), Rect2(TRACK_CAP, 0, tw_ - TRACK_CAP * 2.0, 64))
		else:
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(int(r.size.y / 2.0))
			sb.bg_color = Color(0.36, 0.22, 0.14, 0.85)
			sb.border_color = Color(0.93, 0.82, 0.6)
			sb.set_border_width_all(4)
			l.draw_style_box(sb, r)
		var gx0 := r.position.x + TRACK_CAP * k
		var gw := r.size.x - TRACK_CAP * k * 2.0
		if v > 0.0:
			var fb := StyleBoxFlat.new()
			fb.set_corner_radius_all(int(gh / 2.0))
			fb.bg_color = col.lerp(Color(1.0, 0.62, 0.2), v * 0.6) if i == 0 else col
			l.draw_style_box(fb, Rect2(gx0, gy0, maxf(gh, gw * v), gh))
		# doğru bölge: altın çerçeveli bant
		var z0 := float((ZONE_T.x if i == 0 else ZONE_M.x) - (TEMP_MIN if i == 0 else MIN_LO)) / float((TEMP_MAX - TEMP_MIN) if i == 0 else (MIN_HI - MIN_LO))
		var z1 := float((ZONE_T.y if i == 0 else ZONE_M.y) - (TEMP_MIN if i == 0 else MIN_LO)) / float((TEMP_MAX - TEMP_MIN) if i == 0 else (MIN_HI - MIN_LO))
		var zr := Rect2(gx0 + gw * z0 - gh * 0.3, gy0 - gh * 0.45, gw * (z1 - z0) + gh * 0.6, gh * 1.9)
		var zb := StyleBoxFlat.new()
		zb.set_corner_radius_all(int(zr.size.y / 2.0))
		zb.bg_color = Color(1.0, 0.82, 0.3, 0.28 + 0.1 * sin(t * 3.0))
		zb.border_color = Palette.GOLD
		zb.set_border_width_all(4)
		l.draw_style_box(zb, zr)
		# ölçek: çentik + sayı (140..220° / 5..15 dk)
		var marks: Array = [140, 160, 180, 200, 220] if i == 0 else [5, 7, 10, 13, 15]
		for m in marks:
			var mv := float(int(m) - TEMP_MIN) / float(TEMP_MAX - TEMP_MIN) if i == 0 else float(int(m) - MIN_LO) / float(MIN_HI - MIN_LO)
			var mx := gx0 + gw * mv
			var ideal := (i == 0 and int(m) == TEMP_IDEAL) or (i == 1 and int(m) == 10)
			l.draw_line(Vector2(mx, r.end.y + 4.0), Vector2(mx, r.end.y + (18.0 if ideal else 12.0)), Palette.CREAM if not ideal else Palette.GOLD, 4.0 if ideal else 3.0, true)
			var ms := ("%d°" % int(m)) if i == 0 else (_t("xmas.cookie.min") % int(m))
			var mz := f.get_string_size(ms, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
			var mp := Vector2(mx - mz.x / 2.0, r.end.y + 46.0)
			l.draw_string_outline(f, mp, ms, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Palette.INK)
			l.draw_string(f, mp, ms, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Palette.GOLD if ideal else Palette.CREAM)
		# tutamak: düğme, yolu kadar yuvarlanır
		var hx := gx0 + gw * v
		var hc := Vector2(hx, r.get_center().y)
		var roll := (hx - gx0) / (KNOB_SIZE * 0.5)
		if not _img(l, "knob_temp" if i == 0 else "knob_timer", hc + Vector2(0, -2.0 if slide_drag == i else 0.0), KNOB_SIZE * (1.05 if slide_drag == i else 1.0), 1.0, roll - deg_to_rad(135.0)):
			l.draw_circle(hc, KNOB_SIZE * 0.45, Palette.CARD)
		l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# güncel değer (büyük): solda — "180°C" / "10 dk"
		var lab := ("%d°C" % (temp if temp_set else TEMP_MIN)) if i == 0 else (_t("xmas.cookie.min") % (minutes if timer_set else MIN_LO))
		var sz := f.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 44)
		var lp := Vector2(gx0 - KNOB_SIZE * 0.5 - 22.0 - sz.x, r.get_center().y + 15.0)
		l.draw_string_outline(f, lp, lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, 10, Palette.INK)
		l.draw_string(f, lp, lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(1.0, 0.85, 0.4) if _slider_in_zone(i) else Palette.CREAM)

# ------------------------------------------------------------------ krema (sıkılmış krema boncukları)
var _icing_live := false

## Yolu düzgünleştirip eşit aralıklı noktalara böler.
func _resample(px: PackedVector2Array, step_px: float) -> PackedVector2Array:
	var pts := px
	for _i in 2:  # Chaikin yumuşatma
		if pts.size() < 3:
			break
		var o := PackedVector2Array([pts[0]])
		for i in pts.size() - 1:
			o.append(pts[i].lerp(pts[i + 1], 0.25))
			o.append(pts[i].lerp(pts[i + 1], 0.75))
		o.append(pts[pts.size() - 1])
		pts = o
	var out := PackedVector2Array()
	if pts.is_empty():
		return out
	out.append(pts[0])
	var acc := 0.0
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var d := a.distance_to(b)
		while acc + d >= step_px:
			var k := (step_px - acc) / d
			a = a.lerp(b, k)
			d = a.distance_to(b)
			acc = 0.0
			out.append(a)
		acc += d
	return out

## Gerçek krema gibi: gölge + renkli boncuk gövde + parlak tepe; yeni sıkılan uç kabarır,
## bitmiş çizgilerde ışıltı yavaşça akar.
func _icing(l: CanvasItem, px: PackedVector2Array, k: int, w: float, live := false) -> void:
	var body := tx("icing_bead")
	var hi := tx("icing_hi")
	if body == null or px.is_empty():
		Art.icing(l, px, k, w * 0.9)
		return
	var pts := _resample(px, w * 0.28)
	if pts.size() == 1:
		pts.append(pts[0])
	var col: Color = Art.ICING[k]
	var n := pts.size()
	var sizes := PackedFloat32Array()
	sizes.resize(n)
	for i in n:
		var rid := 1.0 + 0.07 * sin(i * 1.7)              # sıkma halkaları
		var tip := 1.0
		if live:
			tip = lerpf(1.25, 1.0, clampf(float(n - 1 - i) / 6.0, 0.0, 1.0))  # nozülden taze çıkan şişkin uç
		var cap := clampf(minf(i, n - 1 - i) / 3.0, 0.55, 1.0)  # uçlar sivri değil, yuvarlak
		sizes[i] = w * rid * tip * lerpf(0.8, 1.0, cap)
	l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in n:  # gölge
		var d := sizes[i] * 1.18
		l.draw_texture_rect(body, Rect2(pts[i] + Vector2(-d / 2.0, -d / 2.0 + w * 0.28), Vector2(d, d)), false, Color(0.25, 0.12, 0.05, 0.22))
	for i in n:  # gövde
		var d := sizes[i]
		l.draw_texture_rect(body, Rect2(pts[i] - Vector2(d, d) / 2.0, Vector2(d, d)), false, col)
	if hi:
		for i in n:  # parlak tepe + akan ışıltı
			var d := sizes[i] * 0.9
			var glint := 0.55 + 0.45 * maxf(0.0, sin(i * 0.22 - t * 3.2)) if not Ui.reduce_motion() else 0.7
			l.draw_texture_rect(hi, Rect2(pts[i] - Vector2(d, d) / 2.0 + Vector2(-w * 0.06, -w * 0.1), Vector2(d, d)), false, Color(1, 1, 1, glint))


func _slider_in_zone(i: int) -> bool:
	if i == 0:
		return temp_set and temp >= ZONE_T.x and temp <= ZONE_T.y
	return timer_set and minutes >= ZONE_M.x and minutes <= ZONE_M.y


# ------------------------------------------------------------------ geri sayım (gerçek zamanlı fırın)
func _draw_countdown(l: Control) -> void:
	var left := Xmas.oven_seconds_left()
	var txt := "%02d:%02d" % [left / 60, left % 60]
	var f := Ui.FONT
	var c := oven_c + Vector2(0, OVEN_IMG.y / 2.0 + 110.0)
	var pulse := 1.0 + 0.03 * sin(t * 4.0)
	var fs := int(96 * pulse)
	var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	l.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.25, 0.13, 0.07, 0.75)
	bg.set_corner_radius_all(48)
	bg.border_color = Palette.GOLD
	bg.set_border_width_all(4)
	l.draw_style_box(bg, Rect2(c - Vector2(sz.x / 2.0 + 50.0, 80.0), Vector2(sz.x + 100.0, 120.0)))
	l.draw_string(f, c + Vector2(-sz.x / 2.0, 22.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)
	var sub := _t("xmas.cookie.boostNow") % int(Xmas.oven().get("pct", 5))
	var ss := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
	l.draw_string_outline(f, c + Vector2(-ss.x / 2.0, 100.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 8, Palette.INK)
	l.draw_string(f, c + Vector2(-ss.x / 2.0, 100.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Palette.GOLD)

# ------------------------------------------------------------------ eğitim eli (ilk seferde)
var coach := {}      ## {key, kind: drag|tap|circle|swipe, a, b, r}
var coach_l: Layer

func _coach(key: String, kind: String, a: Vector2, b := Vector2.ZERO, r := 120.0) -> void:
	if bool(state.get("tut_" + key, false)) or Dev.env("SNUG_NO_TUT") != "":
		return
	coach = {"key": key, "kind": kind, "a": a, "b": b, "r": r, "t0": t}
	if coach_l == null or not is_instance_valid(coach_l):
		coach_l = _layer(root, _draw_coach)
	elif not layers.has(coach_l):
		layers.append(coach_l)

func _coach_done(key := "") -> void:
	if coach.is_empty() or (key != "" and coach.key != key):
		return
	state["tut_" + String(coach.key)] = true
	Xmas.save()
	coach = {}

func _draw_coach(l: Control) -> void:
	if coach.is_empty():
		return
	var hand := tx_ui("ic_hand")
	var u := fmod((t - float(coach.t0)) * 0.55, 1.0)
	var p: Vector2 = coach.a
	var press := 0.0
	match String(coach.kind):
		"drag":
			var m := clampf((u - 0.15) / 0.6, 0.0, 1.0)
			p = (coach.a as Vector2).lerp(coach.b, ease(m, -2.0))
			press = 1.0 if u > 0.1 and u < 0.8 else 0.0
		"swipe":
			p = (coach.a as Vector2).lerp(coach.b, 0.5 - 0.5 * cos(u * TAU))
			press = 1.0
		"circle":
			p = (coach.a as Vector2) + Vector2.from_angle(u * TAU) * Vector2(float(coach.r), float(coach.r) * 0.45)
			press = 1.0
		_:
			press = 1.0 if u > 0.35 and u < 0.55 else 0.0
	var fade := clampf(minf(u, 1.0 - u) * 8.0, 0.0, 1.0) if coach.kind in ["drag", "tap"] else 1.0
	if press > 0.0:
		l.draw_circle(p, 34.0 + 10.0 * sin(t * 10.0), Color(1, 1, 1, 0.35 * fade))
	if hand:
		var w := 170.0 * (0.9 if press > 0.0 else 1.0)
		var h := w * hand.get_height() / hand.get_width()
		l.draw_texture_rect(hand, Rect2(p - Vector2(w * 0.15, h * 0.05), Vector2(w, h)), false, Color(1, 1, 1, fade))

static func tx_ui(n: String) -> Texture2D:
	return UiArt.tex(n)   # önbellekli (her karede load → doku çizilmeden serbest kalıp beyaz kare oluyordu)

# ------------------------------------------------------------------ malzeme satın al
func _buy_ingredients() -> void:
	if Xmas.buy_set():
		avail = Xmas.batches_available()
		for it: Dictionary in items:
			it.used = int(cnt[it.k]) >= avail
			if not it.used and it.a < 0.5:
				it.pos = it.home
				it.a = 1.0
			it.sc = 1.35
			_tw(create_tween(), it, "sc", 1.0, _d(0.35))
			_puff(it.home, Color(1, 0.95, 0.85), 6, 120.0)
		_snd("felt_pop", "place", 1.1)
		_snd("chime", "click", 1.6, -8.0)
		_hap("success")
		btn_main.visible = false
		_set_hint("xmas.cookie.hint.add")
	else:
		_hap("error")
		Main.toast(_t("xmas.cookie.noCoins"), "ic_coin", Palette.TERRACOTTA)
		Main.open_shop()
