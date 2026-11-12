extends Screen
## Noel Köyü: 2 ASMR mini oyun istasyonu (ağaç, kurabiye) + 25 Aralık
## hediye kutusu + "Noel'e X gün" sayacı + fırın durumu / kurabiye kavanozu takası + günlük Noel
## görevleri ve kiler (malzemeler, düğmeyle satın alma). Kaybetme/zamanlayıcı yok.

const STATIONS := [
	{"game": "tree", "route": "xmas_tree", "key": "xmas.tree.title", "sub": "xmas.tree.sub", "icon": "tree", "fabric": 3,
		"tint_a": "ffffff", "tint_b": "ffffff", "beads": ["red", "gold", "green", "blue"]},
	{"game": "cookie", "route": "xmas_cookie", "key": "xmas.cookie.title", "sub": "xmas.cookie.sub", "icon": "cookie", "fabric": 6,
		"tint_a": "ffe3c8", "tint_b": "ffffff", "beads": ["gold", "red", "gold"]},
]
const ING_IMG := "res://art/xmas/cookie/%s.png"

var _bars := {}
var _scroll: DragScroll
var _oven_l: Label
var _oven_sub: Label
var _jar_l: Label
var _trade_btns: Array = []
var _pantry_ls := {}
var _task_rows: Array = []
var _stations := {}
var _wish_card: QuiltCard
var _wish_scene: _Scene
var _wish_sub: Label
var _wish_snip: Label

func build() -> void:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("christmas")
	bg.wash_top = 0.3
	bg.wash_bottom = 0.7
	bg.motes = 0
	bg.size = size
	add_child(bg)
	var top := header("xmas.village.title")
	_scroll = DragScroll.new()
	put(_scroll, Vector2(X0, top), Vector2(W, H - top))
	var root := _scroll.content
	var pad := 40.0
	var cwid := W - pad * 2.0
	var y := 26.0   # kar kümeleri için üst pay
	# --- Sayaç / hediye kutusu
	var days := Xmas.days_to_christmas()
	var topc := _card(root, 0, Vector2(pad, y), Vector2(cwid, 180))
	var gift := Ui.icon("ic_gift", Vector2(130, 130))
	Ui.place(gift, Vector2(28, 24), gift.size)
	topc.add_child(gift)
	Ui.bob(gift, 6.0, 2.2)
	var line := tr("xmas.daysLeft") % days if days > 0 else tr("xmas.merry")
	var l := Ui.label(line, 42, Palette.INK)
	Ui.place(l, Vector2(184, 26), Vector2(cwid - 210, 60))
	topc.add_child(l)
	if Xmas.gift_box_ready():
		var b := Ui.button(tr("xmas.openGift"), "terracotta", Vector2(360, 84), "", 32)
		Ui.place(b, Vector2(184, 86), b.size)
		topc.add_child(b)
		b.tapped.connect(_open_gift.bind(b))
	else:
		var s := Ui.label(tr("xmas.giftHint"), 28, Palette.INK_SOFT)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Ui.place(s, Vector2(184, 88), Vector2(cwid - 210, 72))
		topc.add_child(s)
	y += 180.0 + 44.0
	# --- yan yana 2 istasyon: keçe cep kartı (sahne penceresi + yün ilerleme girlandı + durum rozeti)
	var gap := 30.0
	var cw := (cwid - gap) / 2.0
	var ch := cw * 1.34
	for i in STATIONS.size():
		var st: Dictionary = STATIONS[i]
		var pos := Vector2(pad + (i % 2) * (cw + gap), y + (i / 2) * (ch + gap + 18.0))
		var c := _card(root, int(st.fabric), pos, Vector2(cw, ch), true)
		var sc := _Scene.new()
		sc.tint_a = Color(st.tint_a)
		sc.tint_b = Color(st.tint_b)
		sc.seed_i = i * 7 + 3
		Ui.place(sc, Vector2(30, 30), Vector2(cw - 60, ch * 0.45))
		c.add_child(sc)
		var ic := _station_icon(String(st.icon), Vector2((cw - 60) * 0.74, ch * 0.45 * 0.86))
		Ui.place(ic, Vector2((sc.size.x - ic.size.x) / 2.0, sc.size.y * 0.06), ic.size)
		ic.pivot_offset = ic.size / 2.0
		sc.add_child(ic)
		Ui.bob(ic, 5.0, 2.6, i * 0.7)
		var ty := 30.0 + ch * 0.45 + 12.0
		var t := Ui.label(tr(st.key), Ui.fit_font(tr(st.key), 38, cw - 60, 22), Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(t, Vector2(24, ty), Vector2(cw - 48, 52))
		c.add_child(t)
		var sb := Ui.label(tr(st.sub), 25, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		sb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Ui.place(sb, Vector2(28, ty + 50), Vector2(cw - 56, 64))
		c.add_child(sb)
		var gl := _Garland.new()
		gl.cols = st.beads
		Ui.place(gl, Vector2(44, ch - 128), Vector2(cw - 88, 44))
		c.add_child(gl)
		var cnt := Ui.label("", 25, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(cnt, Vector2(24, ch - 78), Vector2(cw - 48, 36))
		c.add_child(cnt)
		_stations[st.game] = {"scene": sc, "garland": gl, "count": cnt, "icon": ic}
		var route := String(st.route)
		var game_name := String(st.game)
		c.tapped.connect(func() -> void:
			Asmr.hit({"tree": "twinkle", "cookie": "knob_click"}.get(game_name, "felt_pop"), "light")
			Ui.punch(ic, 0.14)
			if game_name == "tree":
				Xmas.data("tree").seen_orn = _orn_open_count()
				Xmas.save()
			Main.push(route))
		Ui.pop_in(c, 0.08 + i * 0.06)
	y += ch + 44.0
	# --- Yeni Yıl Dileği kartı (tam genişlik)
	var wc := _card(root, 1, Vector2(pad, y), Vector2(cwid, 290), true)
	_wish_card = wc
	var wsc := _Scene.new()
	wsc.tint_a = Color("ffe0e4")
	wsc.tint_b = Color("fbeed8")
	wsc.seed_i = 11
	Ui.place(wsc, Vector2(30, 30), Vector2(cwid * 0.4, 230))
	wc.add_child(wsc)
	var wi := _ScrollIcon.new()
	Ui.place(wi, Vector2(34, 50), Vector2(wsc.size.x - 68, (wsc.size.x - 68) * 0.55))
	wi.pivot_offset = wi.size / 2.0
	wsc.add_child(wi)
	Ui.bob(wi, 6.0, 2.4)
	_wish_scene = wsc
	var wx := 30.0 + cwid * 0.4 + 26.0
	var ww := cwid - wx - 36.0
	var wt := Ui.label(tr("wish.title"), Ui.fit_font(tr("wish.title"), 46, ww, 24), Palette.INK)
	Ui.place(wt, Vector2(wx, 40), Vector2(ww, 58))
	wc.add_child(wt)
	_wish_sub = Ui.label("", 30, Palette.INK_SOFT)
	_wish_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ui.place(_wish_sub, Vector2(wx, 104), Vector2(ww, 84))
	wc.add_child(_wish_sub)
	var wl := Ui.label("", 30, Palette.TERRACOTTA)
	wl.name = "wish_snip"
	Ui.place(wl, Vector2(wx, 180), Vector2(ww, 80))
	wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wl.max_lines_visible = 2
	wl.add_theme_font_override("font", HandFont.get_font())
	wl.add_theme_font_size_override("font_size", int(40.0 * HandFont.scale_for_lang()))
	wc.add_child(wl)
	_wish_snip = wl
	wc.tapped.connect(func() -> void:
		Asmr.hit("felt_pop", "light")
		Ui.punch(wi, 0.14)
		Main.push("xmas_wish"))
	Ui.pop_in(wc, 0.2)
	y += 290.0 + 44.0
	# --- Fırın + kurabiye kavanozu (takas)
	var oc := _card(root, 6, Vector2(pad, y), Vector2(cwid, 350))
	var ov := _img_rect("res://art/xmas/cookie/oven_closed.png", Vector2(120, 122))
	Ui.place(ov, Vector2(26, 22), ov.size)
	oc.add_child(ov)
	_oven_l = Ui.label("", 36, Palette.INK)
	Ui.place(_oven_l, Vector2(170, 24), Vector2(cwid - 200, 50))
	oc.add_child(_oven_l)
	_oven_sub = Ui.label("", 26, Palette.INK_SOFT)
	_oven_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ui.place(_oven_sub, Vector2(170, 74), Vector2(cwid - 200, 70))
	oc.add_child(_oven_sub)
	_jar_l = Ui.label("", 32, Palette.INK)
	Ui.place(_jar_l, Vector2(30, 156), Vector2(cwid - 60, 44))
	oc.add_child(_jar_l)
	var tw_ := (cwid - 60.0 - 20.0 * (Xmas.TRADES.size() - 1)) / Xmas.TRADES.size()
	for i in Xmas.TRADES.size():
		var cl := Ui.label(tr("xmas.trade.cost") % int(Xmas.TRADES[i].cost), 24, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(cl, Vector2(30 + i * (tw_ + 20.0), 192), Vector2(tw_, 30))
		oc.add_child(cl)
		var tb := Ui.button("", "mustard", Vector2(tw_, 72), "", 24)
		Ui.place(tb, Vector2(30 + i * (tw_ + 20.0), 250), tb.size)
		oc.add_child(tb)
		tb.tapped.connect(_trade.bind(i, tb))
		_trade_btns.append(tb)
	y += 350.0 + 44.0
	# --- Noel görevleri + kiler
	var tasks := Xmas.tasks_today()
	var th := 90.0 + tasks.size() * 78.0 + 340.0
	var tc := _card(root, 3, Vector2(pad, y), Vector2(cwid, th))
	var tl := Ui.label(tr("xmas.tasks.title"), 36, Palette.INK)
	Ui.place(tl, Vector2(30, 22), Vector2(cwid - 60, 50))
	tc.add_child(tl)
	for i in tasks.size():
		var row := _TaskRow.new()
		row.data = tasks[i]
		Ui.place(row, Vector2(30, 84 + i * 78.0), Vector2(cwid - 60, 66))
		tc.add_child(row)
		_task_rows.append(row)
	var py := 84.0 + tasks.size() * 78.0 + 14.0
	var pl := Ui.label(tr("xmas.pantry"), 30, Palette.INK_SOFT)
	Ui.place(pl, Vector2(30, py), Vector2(300, 40))
	tc.add_child(pl)
	var colw := (cwid - 60.0) / Xmas.INGR.size()
	for i in Xmas.INGR.size():
		var k: String = Xmas.INGR[i]
		var ix := 30.0 + i * colw
		var im := _img_rect(ING_IMG % k, Vector2(96, 96))
		Ui.place(im, Vector2(ix + (colw - 96) / 2.0, py + 50), im.size)
		tc.add_child(im)
		var cl := Ui.label("", 32, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(cl, Vector2(ix, py + 150), Vector2(colw, 40))
		tc.add_child(cl)
		_pantry_ls[k] = cl
		var buy := Ui.button(str(Xmas.ING_PRICE), "mustard", Vector2(colw - 14, 72), "coin", 28)
		Ui.place(buy, Vector2(ix + 7, py + 198), buy.size)
		tc.add_child(buy)
		buy.tapped.connect(_buy.bind(k, buy))
	y += th + 60.0
	_scroll.set_length(y)
	XmasKit.add_snow(self, 34)
	_refresh()
	Xmas.changed.connect(_refresh)
	# Köy ambiyansı: açılışta uzaktan çan + şömine çıtırtısı.
	Asmr.play("jingle", "", 0.9, -12.0)
	Asmr.play("crackle", "", 1.0, -14.0)

func _process(_dt: float) -> void:
	if _oven_l and Xmas.oven_busy() and not Xmas.oven_ready() and Engine.get_process_frames() % 30 == 0:
		_refresh_oven()
		_refresh_cards()

func on_resume() -> void:
	_refresh()

func _orn_open_count() -> int:
	var n := 0
	for k in Xmas.ORN_ORDER:
		if Xmas.orn_open(k):
			n += 1
	return n

func _refresh_cards() -> void:
	if not _stations.has("tree") or not is_instance_valid(_wish_card):
		return
	var tn := _orn_open_count()
	var ts: Dictionary = _stations.tree
	ts.garland.set_fill(Xmas.ORN_ORDER.size(), tn)
	ts.count.text = tr("xmas.card.orn") % [tn, Xmas.ORN_ORDER.size()]
	ts.scene.pct = Xmas.progress_of("tree")
	ts.scene.chip = tr("xmas.chip.newOrn") if tn > int(Xmas.data("tree").get("seen_orn", Xmas.ORN_START_OPEN)) else ""
	ts.scene.chip_col = Palette.MUSTARD
	var cs: Dictionary = _stations.cookie
	var jar := Xmas.jar()
	cs.garland.set_fill(Xmas.TRADE_COOKIES, mini(jar, Xmas.TRADE_COOKIES))
	cs.count.text = tr("xmas.card.jar") % jar
	cs.scene.pct = Xmas.progress_of("cookie")
	if Xmas.oven_ready():
		cs.scene.chip = tr("xmas.chip.ready")
		cs.scene.chip_col = Palette.SAGE
	elif Xmas.oven_busy():
		var left := Xmas.oven_seconds_left()
		cs.scene.chip = tr("xmas.chip.baking") % ("%d:%02d" % [left / 60, left % 60])
		cs.scene.chip_col = Palette.TERRACOTTA
	else:
		cs.scene.chip = ""
	var sealed := Xmas.wish_sealed()
	_wish_scene.chip_col = Palette.MUSTARD
	if sealed and Xmas.wish_new_year():
		_wish_scene.chip = tr("wish.chipOpen")
		_wish_scene.chip_col = Palette.TERRACOTTA
		_wish_sub.text = tr("wish.subNY")
		_wish_card.glow = true
	elif sealed:
		_wish_scene.chip = tr("wish.chipSealed")
		_wish_scene.chip_col = Palette.SAGE
		_wish_sub.text = tr("wish.subDone")
	else:
		_wish_scene.chip = tr("wish.chipNew")
		_wish_sub.text = tr("wish.sub")
	_wish_snip.text = "“%s”" % String(Xmas.wish().get("text", "")) if sealed and Xmas.wish_new_year() else ""
	for n in [ts.scene, cs.scene, _wish_scene]:
		n.queue_redraw()

func _refresh() -> void:
	if not is_instance_valid(_jar_l):
		return
	_refresh_cards()
	_refresh_oven()
	_jar_l.text = tr("xmas.jar") % Xmas.jar()
	for i in _trade_btns.size():
		var t: Dictionary = Xmas.TRADES[i]
		var give: Dictionary = t.give
		var parts: PackedStringArray = []
		if give.has("energy"):
			parts.append(tr("xmas.trade.energy") % int(give.energy))
		if give.has("coin"):
			parts.append(tr("xmas.trade.coin") % int(give.coin))
		_trade_btns[i].text = " ".join(parts)
		_trade_btns[i].disabled = not Xmas.can_trade(i)
	var p := Xmas.pantry()
	for k in _pantry_ls:
		_pantry_ls[k].text = "x%d" % int(p.get(k, 0))
	for r in _task_rows:
		r.queue_redraw()

func _refresh_oven() -> void:
	if Xmas.oven_ready():
		_oven_l.text = tr("xmas.oven.ready")
		_oven_sub.text = tr("xmas.oven.readySub")
	elif Xmas.oven_busy():
		var left := Xmas.oven_seconds_left()
		_oven_l.text = tr("xmas.oven.baking") % ("%02d:%02d" % [left / 60, left % 60])
		_oven_sub.text = tr("xmas.cookie.boostNow") % Xmas.cookie_boost_pct()
	else:
		_oven_l.text = tr("xmas.oven.idle")
		_oven_sub.text = tr("xmas.oven.idleSub")

func _trade(i: int, b: Control) -> void:
	var give := Xmas.trade(i)
	if give.is_empty():
		Juice.haptic("error")
		return
	Asmr.hit("felt_pop", "success", "reward")
	Ui.punch(b, 0.08)
	XmasKit.celebrate(self, b.get_global_rect().get_center() - global_position)
	_refresh()

func _buy(k: String, b: Control) -> void:
	if Xmas.buy_ingredient(k):
		Asmr.hit("chime", "success", "reward", 1.4)
		Ui.punch(b, 0.08)
		_refresh()
	else:
		Juice.haptic("error")
		Main.toast(tr("xmas.cookie.noCoins"), "ic_coin", Palette.TERRACOTTA)
		Main.open_shop()

func _card(parent: Control, fabric: int, pos: Vector2, sz: Vector2, pressable := false) -> QuiltCard:
	var c := QuiltCard.new()
	c.fabric = fabric
	c.inner = 14
	c.radius = 44
	c.pressable = pressable
	Ui.place(c, pos, sz)
	parent.add_child(c)
	return c

func _img_rect(path: String, sz: Vector2) -> Control:
	if ResourceLoader.exists(path):
		return Ui.tex_rect(load(path), sz)
	return Ui.icon("ic_gift", sz)

func _station_icon(name: String, sz: Vector2) -> Control:
	var p := "res://art/xmas/station_%s.png" % name
	if ResourceLoader.exists(p):
		return Ui.tex_rect(load(p), sz)
	var map := {"tree": "ic_star", "cookie": "ic_heart"}
	return Ui.icon(String(map.get(name, "ic_star")), Vector2(sz.y, sz.y))

func _open_gift(b: Control) -> void:
	var r := Xmas.claim_gift_box()
	if r.is_empty():
		return
	b.queue_free()
	XmasKit.celebrate(self, size / 2.0)
	Main.reward(tr("xmas.giftTitle"), r, {"pose": "cheer", "double": false})

const ART := "res://art/xmas/station/%s.png"

## Kart içi sahne penceresi (ChatGPT keçe çerçeve) + kar tepesi + parıltılar + durum rozeti + yüzde düğmesi.
class _Scene extends Control:
	var tint_a := Color.WHITE        ## çerçeve/iç tonu (modulate)
	var tint_b := Color.WHITE
	var seed_i := 0
	var chip := ""
	var chip_col := Palette.MUSTARD
	var pct := -1.0
	var _t := 0.0
	var _frame: Texture2D = load("res://art/xmas/station/station_frame.png") if ResourceLoader.exists("res://art/xmas/station/station_frame.png") else null
	var _snow: Texture2D = load("res://art/xmas/station/station_snow.png") if ResourceLoader.exists("res://art/xmas/station/station_snow.png") else null
	var _badge: Texture2D = load("res://art/xmas/station/station_badge.png") if ResourceLoader.exists("res://art/xmas/station/station_badge.png") else null
	var _chips := {}
	func _chip_tex(cn: String) -> Texture2D:
		if not _chips.has(cn):
			var p := "res://art/xmas/station/station_%s.png" % cn
			_chips[cn] = load(p) if ResourceLoader.exists(p) else null
		return _chips[cn]
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if _frame:
			# iç dolgu tonu: modulate çerçeve + merkez birlikte renklenir
			WishArt.nine(self, _frame, r, 64.0, 0.42, tint_a)
		else:
			draw_colored_polygon(Ui.rrect(r, 30.0), tint_a)
		if _snow:
			var sw := size.x - 40.0
			var sh := sw * float(_snow.get_height()) / _snow.get_width()
			draw_texture_rect(_snow, Rect2(20, size.y - sh - 12, sw, sh), false)
		for i in 5:
			var a := 0.5 + 0.5 * sin(_t * 2.0 + i * 1.7 + seed_i)
			var c := Vector2(size.x * (0.14 + 0.18 * i + 0.03 * sin(seed_i + i)), size.y * (0.14 + 0.16 * fmod(i * 0.37 + seed_i * 0.1, 1.0)))
			var s := 5.0 + 4.0 * a
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.3, -s * 0.3), c + Vector2(s, 0), c + Vector2(s * 0.3, s * 0.3), c + Vector2(0, s), c + Vector2(-s * 0.3, s * 0.3), c + Vector2(-s, 0), c + Vector2(-s * 0.3, -s * 0.3)]), Color(1, 0.98, 0.9, 0.3 + 0.5 * a))
		if pct >= 0.0:
			var pc := Vector2(size.x - 44, 44)
			if _badge:
				draw_texture_rect(_badge, Rect2(pc - Vector2(33, 33), Vector2(66, 66)), false)
			else:
				draw_circle(pc, 30, Color(Palette.CREAM, 0.95))
			if pct > 0.0:
				draw_arc(pc, 26, -PI / 2.0, -PI / 2.0 + TAU * pct, 28, Palette.SAGE, 5.0, true)
			draw_string(Ui.FONT, pc + Vector2(-30, 8), "%d%%" % int(round(pct * 100.0)), HORIZONTAL_ALIGNMENT_CENTER, 60, 20, Palette.INK)
		if chip != "":
			var fs := 24
			var tw := Ui.FONT.get_string_size(chip, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var cr := Rect2(18, 18 + sin(_t * 3.0) * 1.5, tw + 44, 50)
			var cn := "chip_mustard"
			if chip_col == Palette.TERRACOTTA:
				cn = "chip_red"
			elif chip_col == Palette.SAGE:
				cn = "chip_green"
			var ct: Texture2D = _chip_tex(cn)
			if ct:
				WishArt.nine(self, ct, cr, 62.0, cr.size.y / 139.0, Color.WHITE)
			else:
				draw_colored_polygon(Ui.rrect(cr, 25.0), chip_col)
			draw_string(Ui.FONT, cr.position + Vector2(22, 34), chip, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)

## İlerleme girlandı: stitched ip üstünde keçe boncuklar; dolu olanlar renkli, boşlar soluk.
class _Garland extends Control:
	var cols: Array = ["red", "gold", "green", "blue"]
	var n := 0
	var filled := 0
	var _empty: Texture2D = load("res://art/xmas/station/station_bead_empty.png") if ResourceLoader.exists("res://art/xmas/station/station_bead_empty.png") else null
	var _cache := {}
	func _bead(nm: String) -> Texture2D:
		if not _cache.has(nm):
			var p := "res://art/xmas/station/station_bead_%s.png" % nm
			_cache[nm] = load(p) if ResourceLoader.exists(p) else null
		return _cache[nm]
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func set_fill(total: int, f: int) -> void:
		n = total
		filled = f
		queue_redraw()
	func _draw() -> void:
		if n <= 0:
			return
		var y := size.y * 0.5
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("e8d4a8"), 5.0, true)
		draw_dashed_line(Vector2(0, y), Vector2(size.x, y), Color("b98f5c"), 2.0, 7.0)
		var d := minf(size.y, size.x / float(n) * 0.98)
		for i in n:
			var c := Vector2(size.x * (i + 0.5) / float(n), y)
			var tex: Texture2D = _empty
			if i < filled:
				tex = _bead(cols[i % cols.size()])
			if tex:
				draw_texture_rect(tex, Rect2(c - Vector2(d, d) / 2.0, Vector2(d, d)), false, Color.WHITE if i < filled else Color(1, 1, 1, 0.8))
			else:
				draw_circle(c, d / 2.0, Color(Palette.INK, 0.12))

class _ScrollIcon extends Control:
	var _tex: Texture2D = load("res://art/xmas/wish/wish_scroll.png") if ResourceLoader.exists("res://art/xmas/wish/wish_scroll.png") else null
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if _tex:
			var w := minf(size.x, size.y * float(_tex.get_width()) / _tex.get_height())
			var h := w * float(_tex.get_height()) / _tex.get_width()
			draw_texture_rect(_tex, Rect2((size.x - w) / 2.0, (size.y - h) / 2.0, w, h), false)
		else:
			WishArt.draw_scroll(self, Rect2(Vector2.ZERO, size), 1.0)

class _Bar extends Control:
	var v := 0.0
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(_sb(Color(Palette.INK, 0.15)), r)
		if v > 0.0:
			draw_style_box(_sb(Palette.TERRACOTTA), Rect2(r.position, Vector2(maxf(size.y, size.x * v), size.y)))
	func _sb(c: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = c
		s.set_corner_radius_all(int(size.y / 2.0))
		return s

## Görev satırı: açıklama + ilerleme çubuğu + ödül malzemeleri, tamamlanınca altın tik.
class _TaskRow extends Control:
	var data: Dictionary
	func _draw() -> void:
		var d: Dictionary = Xmas.TASKS[int(data.i)]
		var f := Ui.FONT
		var done := bool(data.done)
		var txt := TranslationServer.translate("xmas.task." + String(d.id))
		if "%" in txt:
			txt = txt % int(d.n)
		draw_string(f, Vector2(0, 30), txt, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.62, 28, Palette.INK if not done else Palette.INK_SOFT)
		var bw := size.x * 0.4
		var br := Rect2(0, 44, bw, 14)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(7)
		sb.bg_color = Color(Palette.INK, 0.15)
		draw_style_box(sb, br)
		var pv := float(data.p) / float(d.n)
		if pv > 0.0:
			var fb := StyleBoxFlat.new()
			fb.set_corner_radius_all(7)
			fb.bg_color = Palette.GOLD if done else Palette.SAGE
			draw_style_box(fb, Rect2(br.position, Vector2(maxf(14.0, bw * pv), 14)))
		draw_string(f, Vector2(bw + 12, 58), "%d/%d" % [int(data.p), int(d.n)], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.INK_SOFT)
		# ödül: malzeme ikonları
		var x := size.x - 8.0
		for k in (d.give as Dictionary).keys():
			var path := "res://art/xmas/cookie/%s.png" % k
			if ResourceLoader.exists(path):
				var tex: Texture2D = load(path)
				x -= 60.0
				draw_texture_rect(tex, Rect2(x, 4, 56, 56), false, Color(1, 1, 1, 0.5 if done else 1.0))
		if done:
			draw_circle(Vector2(x - 34.0, 32), 22.0, Palette.GOLD)
			draw_polyline(PackedVector2Array([Vector2(x - 44, 32), Vector2(x - 36, 41), Vector2(x - 22, 23)]), Palette.CREAM, 5.0, true)
