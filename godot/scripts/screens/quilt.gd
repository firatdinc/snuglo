extends Screen
## Benim Yorganım: çözülen her bölümün yaması 8 sütunlu kişisel yorganda. Boş yuvalar kesikli
## dikiş çerçevesi. Yamaya dokun → anı kartı (bölüm, tarih, süre, ★). Raf: tamamlanmış yorganlar.
## Paylaş: yorgan posteri (SubViewport render) iOS paylaşım sayfasına.
## args: {"archive": n} → n. tamamlanmış yorganı göster (salt okunur).

var _scroll: DragScroll
var _patches: Array = []
var _archive_i := -1
var _grid_rect := Rect2()
var _info: Control
var _flow: SewFlow
var _slots := {}
var _extras: Control   ## ızgara altı (istatistik, devam kartı, raf); dikiş akışında gizlenir

func build() -> void:
	_archive_i = int(args.get("archive", -1))
	_patches = Quilt.archive()[_archive_i] if _archive_i >= 0 and _archive_i < Quilt.completed_count() else Quilt.current()
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("flower")
	bg.wash_top = 0.85
	bg.wash_bottom = 0.95
	bg.motes = 10
	bg.size = size
	add_child(bg)
	var top := header("quilt.title")
	var sh := Ui.icon_button("ic_share", 120)
	put(sh, Vector2(X0 + W - 150, TOP + 30.0), Vector2(120, 120))
	sh.tapped.connect(_share)
	Ui.pop_in(sh, 0.1)
	_scroll = DragScroll.new()
	put(_scroll, Vector2(X0, top), Vector2(W, H - top))
	_fill()
	var dev := Dev.env("SNUG_SEW")
	if (bool(args.get("sew", false)) or dev != "") and _archive_i < 0 and Quilt.pending_count() > 0:
		get_tree().create_timer(0.5).timeout.connect(_open_sew.bind("" if dev in ["", "pick"] else dev))

## Kaydırma içeriğini (pending kartı + yorgan + raf) baştan kurar.
func _fill(settle := -1) -> void:
	for c in _scroll.content.get_children():
		c.queue_free()
	_info = null
	var y := 10.0
	# Alt başlık: n/64 + toplam
	var sub := tr("quilt.progress") % [_patches.size(), Quilt.QUILT_SIZE]
	if _archive_i >= 0:
		sub = tr("quilt.archived") % (_archive_i + 1)
	var l := Ui.label(sub, 36, Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(l, Vector2(40, y), Vector2(W - 80, 50))
	_scroll.content.add_child(l)
	y += 70.0
	if _archive_i < 0 and Quilt.pending_count() > 0:
		y = _pending_card(y)
	# Yorgan kasnağı
	var cw := W - 80.0
	var cell := cw / float(Quilt.COLS)
	var rows := Quilt.QUILT_SIZE / Quilt.COLS
	var frame := QuiltCard.new()
	frame.fabric = 10
	frame.radius = 40
	frame.depth = 14
	Ui.place(frame, Vector2(40 - 24, y - 24), Vector2(cw + 48, cell * rows + 48))
	_scroll.content.add_child(frame)
	_grid_rect = Rect2(Vector2(40, y), Vector2(cw, cell * rows))
	var fresh := Quilt.pending_stitch if _archive_i < 0 else -1
	var fresh_slot := int(_patches[fresh].get("slot", fresh)) if fresh >= 0 and fresh < _patches.size() else -1
	var slots := Quilt.by_slot(_patches)
	_slots.clear()
	for i in Quilt.QUILT_SIZE:
		var pos := Vector2(40 + (i % Quilt.COLS) * cell, y + (i / Quilt.COLS) * cell)
		if not (slots[i] as Dictionary).is_empty():
			var pv := PatchView.new()
			pv.set_patch(slots[i])
			Ui.place(pv, pos + Vector2(1, 1), Vector2(cell - 2, cell - 2))
			pv.pivot_offset = pv.size / 2.0
			_scroll.content.add_child(pv)
			var idx := i
			pv.tapped.connect(func() -> void: _show_info(idx, pv))
			if i == fresh_slot:
				_stitch_in(pv)
			elif i == settle:
				Ui.punch(pv, 0.25)
		else:
			var slot := _EmptySlot.new()
			Ui.place(slot, pos + Vector2(2, 2), Vector2(cell - 4, cell - 4))
			_scroll.content.add_child(slot)
			_slots[i] = slot
			slot.hot = _flow != null
			var si := i
			slot.tapped.connect(func() -> void: _slot_tapped(si))
	if _archive_i < 0:
		Quilt.pending_stitch = -1
	y += cell * rows + 60.0
	_extras = Control.new()
	_extras.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_extras.position = Vector2(0, y)
	_extras.visible = _flow == null
	_scroll.content.add_child(_extras)
	y = _fill_extras(y)
	_scroll.set_length(y + BOTTOM + 60)

## Izgaranın altı: istatistik şeridi, (bekleyen yoksa) sıradaki bölüm kartı, raf. y = içerik mutlak y'si.
func _fill_extras(y0: float) -> float:
	var y := 0.0
	var cw := W - 80.0
	var host := _extras
	if _archive_i < 0:
		var gold := 0
		for q in (Quilt.archive() + [Quilt.current()]):
			for p in q:
				if int(p.get("s", 0)) >= 3:
					gold += 1
		var stats := [["ic_stats", str(Quilt.total()), "quilt.stat.total"], ["ic_star", str(gold), "quilt.stat.gold"],
			["ic_crown", str(Quilt.completed_count()), "quilt.stat.done"]]
		var sw := (cw - 40.0) / 3.0
		for i in 3:
			var sc := QuiltCard.new()
			sc.fill = Palette.CARD
			sc.radius = 32
			sc.inner = 0
			Ui.place(sc, Vector2(40 + i * (sw + 20.0), y), Vector2(sw, 190))
			host.add_child(sc)
			var ic := Ui.icon(stats[i][0], Vector2(56, 56))
			Ui.place(ic, Vector2(sw / 2.0 - 28.0, 16), Vector2(56, 56))
			sc.add_child(ic)
			var n := Ui.title(stats[i][1], 56, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
			Ui.place(n, Vector2(0, 72), Vector2(sw, 70))
			sc.add_child(n)
			var lb := Ui.label(tr(stats[i][2]), 26, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
			lb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			Ui.place(lb, Vector2(8, 140), Vector2(sw - 16, 40))
			sc.add_child(lb)
			Ui.pop_in(sc, 0.15 + i * 0.06, 0.85)
		y += 230.0
		var target := Progress.continue_target()
		if Quilt.pending_count() == 0 and target != "":
			var card := QuiltCard.new()
			card.fill = Palette.CARD
			card.radius = 44
			card.inner = 0
			card.pressable = true
			Ui.place(card, Vector2(40, y), Vector2(cw, 250))
			host.add_child(card)
			var t := Ui.wrap(Ui.label(tr("quilt.next"), 36, Palette.INK), cw - 60.0)
			Ui.place(t, Vector2(30, 24), Vector2(cw - 60.0, 100))
			card.add_child(t)
			var b := Ui.button(tr("quilt.nextCta"), "sage", Vector2(cw - 60.0, 86))
			Ui.place(b, Vector2(30, 138), Vector2(cw - 60.0, 86))
			card.add_child(b)
			b.tapped.connect(func() -> void: Main.play(Progress.continue_target()))
			card.tapped.connect(func() -> void: Main.play(Progress.continue_target()))
			y += 290.0
	# Raf: tamamlanmış yorganlar
	if _archive_i < 0 or Quilt.completed_count() > 0:
		var t := Ui.title(tr("quilt.shelf"), 48, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
		Ui.place(t, Vector2(50, y), Vector2(cw, 62))
		host.add_child(t)
		y += 80.0
	var mini := 180.0
	if Quilt.completed_count() > 0:
		for qi in Quilt.completed_count():
			var q: Array = Quilt.archive()[qi]
			var card := QuiltCard.new()
			card.fill = Palette.CARD
			card.radius = 28
			card.pressable = true
			Ui.place(card, Vector2(40.0 + (qi % 4) * (mini + 30.0), y + (qi / 4) * (mini + 30.0)), Vector2(mini, mini))
			host.add_child(card)
			var thumb := _Thumb.new()
			thumb.patches = q
			Ui.place(thumb, Vector2(14, 14), Vector2(mini - 28, mini - 28))
			card.add_child(thumb)
			var n := qi
			card.tapped.connect(func() -> void: Main.push("quilt", {"archive": n}))
		y += ceili(Quilt.completed_count() / 4.0) * (mini + 30.0)
	elif _archive_i < 0:
		# Boş raf: soluk hayalet yorgan + açıklama
		var gh := QuiltCard.new()
		gh.fill = Palette.CARD
		gh.radius = 28
		gh.modulate.a = 0.45
		Ui.place(gh, Vector2(40, y), Vector2(mini, mini))
		host.add_child(gh)
		var gt := _Thumb.new()
		gt.patches = []
		gt.ghost = true
		Ui.place(gt, Vector2(14, 14), Vector2(mini - 28, mini - 28))
		gh.add_child(gt)
		var e := Ui.wrap(Ui.label(tr("quilt.shelfEmpty"), 30, Palette.CREAM), cw - mini - 40.0)
		Ui.place(e, Vector2(40 + mini + 30.0, y + 20.0), Vector2(cw - mini - 40.0, 140))
		host.add_child(e)
		y += mini + 30.0
	return y0 + y

func _pending_card(y: float) -> float:
	var cw := W - 80.0
	var card := QuiltCard.new()
	card.fill = Palette.CARD
	card.radius = 44
	card.inner = 0
	card.pressable = true
	card.glow = true
	Ui.place(card, Vector2(40, y), Vector2(cw, 220))
	_scroll.content.add_child(card)
	var pv := PatchView.new()
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.set_patch(Quilt.pending()[0])
	pv.show_trim = false
	Ui.place(pv, Vector2(26, 26), Vector2(168, 168))
	card.add_child(pv)
	var t := Ui.label(tr("sew.pendingCard") % Quilt.pending_count(), 40, Palette.INK)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(t, Vector2(220, 34), Vector2(cw - 250, 56))
	card.add_child(t)
	var b := Ui.button(tr("sew.cta"), "terracotta", Vector2(cw - 260, 86))
	Ui.place(b, Vector2(220, 106), Vector2(cw - 260, 86))
	card.add_child(b)
	b.tapped.connect(func() -> void: _open_sew())   # JuicyButton _ready'de STOP'a döner → dokunuşu kendisi alır
	card.tapped.connect(func() -> void: _open_sew())
	Ui.pop_in(card, 0.1, 0.8)
	return y + 250.0

## Dikiş akışı: tepsiden kumaş seç, boş kareye dokun/sürükle, yakınlaşıp diker (SewFlow).
func _open_sew(dev := "") -> void:
	if _archive_i >= 0 or Quilt.pending_count() == 0 or _flow != null:
		return
	_scroll.pad_end = 520.0
	_scroll.scroll_to(_grid_rect.position.y - 90.0, false)
	_flow = SewFlow.new()
	_flow.host = self
	_flow.dev = dev
	_flow.on_done = _after_sew
	if _extras:
		_extras.visible = false
	_flow.closed.connect(func() -> void:
		_flow = null
		if _extras:
			_extras.visible = true
		_scroll.pad_end = 0.0
		_set_hot(false))
	add_child(_flow)

func _after_sew() -> void:
	Quilt.pending_stitch = -1
	_patches = Quilt.current()
	var last_slot := int(_patches[_patches.size() - 1].get("slot", -1)) if not _patches.is_empty() else -1
	_fill(last_slot)

# SewFlow arayüzü ---------------------------------------------------

func set_slots_hot(on: bool) -> void:
	_set_hot(on)

func _set_hot(on: bool) -> void:
	for sl in _slots.values():
		if is_instance_valid(sl):
			sl.hot = on

func slot_rect(i: int) -> Rect2:
	var cell := (W - 80.0) / float(Quilt.COLS)
	return Rect2(_scroll.global_position + Vector2(40 + (i % Quilt.COLS) * cell, _grid_rect.position.y + (i / Quilt.COLS) * cell - _scroll.offset), Vector2(cell, cell))

## Küresel noktanın altındaki BOŞ yuva (yoksa -1).
func slot_at(pos: Vector2) -> int:
	for i in _slots:
		if is_instance_valid(_slots[i]) and (_slots[i] as Control).get_global_rect().has_point(pos):
			return int(i)
	return -1

func hover_slot(i: int, set_id: String, ci: int) -> void:
	for k in _slots:
		var sl = _slots[k]
		if is_instance_valid(sl):
			sl.ghost_ci = ci if k == i else -1
			sl.ghost_set = set_id
			sl.queue_redraw()

func _slot_tapped(i: int) -> void:
	if _flow:
		_flow.choose_slot(i)

func _stitch_in(pv: PatchView) -> void:
	pv.stitch_in = 0.0
	pv.scale = Vector2.ONE * 1.6
	pv.modulate.a = 0.0
	var tw := pv.create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(pv, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(pv, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		Asmr.hit("felt_pop", "medium", "place")
		Asmr.stitch_run(pv, 8, 0.085))
	tw.tween_method(func(v: float) -> void:
		pv.stitch_in = v
		pv.queue_redraw(), 0.0, 1.0, 0.7)
	tw.tween_callback(func() -> void: Asmr.hit("scissors", "light"))

func _show_info(idx: int, pv: PatchView) -> void:
	if DragScroll.recently_dragged():
		return
	if _info:
		_info.queue_free()
	var p: Dictionary = (Quilt.by_slot(_patches) as Array)[idx]
	Ui.punch(pv, 0.12)
	Asmr.hit("felt_pop", "tick", "click", 1.05, -8.0)
	var card := QuiltCard.new()
	card.fill = Palette.CARD
	card.radius = 40
	card.inner = 0
	var w := W - 160.0
	var cy := pv.position.y + pv.size.y + 20.0
	if cy + 260 > _grid_rect.end.y:
		cy = pv.position.y - 280.0
	Ui.place(card, Vector2(80, cy), Vector2(w, 250))
	_scroll.content.add_child(card)
	var big := PatchView.new()
	big.set_patch(p)
	Ui.place(big, Vector2(24, 24), Vector2(200, 200))
	card.add_child(big)
	var name := _level_label(String(p.get("id", "")))
	var t := Ui.label(name, 40, Palette.INK)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(t, Vector2(250, 30), Vector2(w - 280, 56))
	card.add_child(t)
	var date := Time.get_date_string_from_unix_time(int(p.get("t", 0)))
	var line := "%s  ·  %s  ·  %s" % ["★".repeat(int(p.get("s", 0))), Ui.fmt_time(float(p.get("sec", 0))), date]
	var d := Ui.label(line, 32, Palette.INK_SOFT)
	Ui.place(d, Vector2(250, 100), Vector2(w - 280, 50))
	card.add_child(d)
	var n := Ui.label(tr("quilt.patchNo") % (idx + 1), 28, Palette.INK_SOFT)
	Ui.place(n, Vector2(250, 160), Vector2(w - 280, 44))
	card.add_child(n)
	Ui.pop_in(card, 0.0, 0.7, 0.3)
	_info = card
	card.pressable = true
	card.tapped.connect(func() -> void:
		card.queue_free()
		_info = null)

static func _level_label(id: String) -> String:
	var head := id.get_slice("-", 0)
	var tail := id.rsplit("-", true, 1)
	var num := tail[1] if tail.size() > 1 else ""
	match head:
		"daily":
			return TranslationServer.translate("quilt.kind.daily")
		"tower":
			return "%s · %s" % [TranslationServer.translate("tower.title"), num]
		"endless":
			return TranslationServer.translate("quilt.kind.endless")
	var pid := tail[0]
	var key := "pack.%s.title" % pid
	var nm := TranslationServer.translate(key)
	if nm == key:
		nm = pid.capitalize()
	return "%s · %s" % [nm, num]

# ------------------------------------------------------------------ Poster

## Yorganı tek başına (başlık + yamalar) yüksek çözünürlüklü PNG'ye çizer.
static func render_poster(patches: Array, tree: SceneTree, side_px := 2048, wallpaper := false) -> Image:
	var vp := SubViewport.new()
	var sz := Vector2i(1290, 2796) if wallpaper else Vector2i(side_px, int(side_px * 1.25))
	vp.size = sz
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var root := Control.new()
	root.size = Vector2(sz)
	vp.add_child(root)
	var bg := ColorRect.new()
	bg.color = Palette.BG_BOTTOM
	bg.size = Vector2(sz)
	root.add_child(bg)
	var margin := sz.x * 0.08
	var cw := sz.x - margin * 2.0
	var cell := cw / float(Quilt.COLS)
	var rows := Quilt.QUILT_SIZE / Quilt.COLS
	var gy := (sz.y - cell * rows) / 2.0 + (sz.y * 0.04 if not wallpaper else sz.y * 0.06)
	var frame := QuiltCard.new()
	frame.fabric = 10
	frame.radius = cell * 0.4
	frame.depth = cell * 0.12
	frame.position = Vector2(margin - cell * 0.25, gy - cell * 0.25)
	frame.size = Vector2(cw + cell * 0.5, cell * rows + cell * 0.5)
	root.add_child(frame)
	var bys := Quilt.by_slot(patches)
	for i in Quilt.QUILT_SIZE:
		var pos := Vector2(margin + (i % Quilt.COLS) * cell, gy + (i / Quilt.COLS) * cell)
		var c: Control
		if not (bys[i] as Dictionary).is_empty():
			var pv := PatchView.new()
			pv.set_patch(bys[i])
			c = pv
		else:
			c = _EmptySlot.new()
		c.position = pos + Vector2(3, 3)
		c.size = Vector2(cell - 6, cell - 6)
		root.add_child(c)
	var title := Label.new()
	title.text = TranslationServer.translate("quilt.posterTitle")
	title.add_theme_font_size_override("font_size", int(sz.x * 0.07))
	title.add_theme_color_override("font_color", Palette.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, gy - cell * 1.6)
	title.size = Vector2(sz.x, cell)
	root.add_child(title)
	var foot := Label.new()
	foot.text = "Snuglo"
	foot.add_theme_font_size_override("font_size", int(sz.x * 0.035))
	foot.add_theme_color_override("font_color", Palette.INK_SOFT)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.position = Vector2(0, gy + cell * rows + cell * 0.6)
	foot.size = Vector2(sz.x, cell * 0.6)
	root.add_child(foot)
	tree.root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img

func _share() -> void:
	Sfx.play("click")
	var img: Image = await render_poster(_patches, get_tree())
	Share.share_image(self, img, tr("quilt.shareText") % _patches.size())

# ------------------------------------------------------------------ Yardımcı çizimler

class _EmptySlot extends Control:
	signal tapped
	var hot := false          ## dikiş akışında seçilebilir: ChatGPT çizimi vurgu çerçevesi nefes alır
	var ghost_ci := -1        ## sürüklenen kumaşın bu kareye "önizlemesi"
	var ghost_set := ""
	var _t := 0.0
	var _press := false
	static var hot_tex: Texture2D
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		if hot_tex == null and ResourceLoader.exists("res://art/quilt/slot_hot.png"):
			hot_tex = load("res://art/quilt/slot_hot.png")
	func _process(dt: float) -> void:
		if hot:
			_t += dt
			queue_redraw()
	func _draw() -> void:
		var s := minf(size.x, size.y)
		draw_rect(Rect2(Vector2.ZERO, Vector2(s, s)), Color(Palette.CARD, 0.35))
		var e := s * 0.08
		var pts := PackedVector2Array([Vector2(e, e), Vector2(s - e, e), Vector2(s - e, s - e), Vector2(e, s - e), Vector2(e, e)])
		draw_polyline(pts, Color(Palette.STITCH_DARK, 0.45), maxf(1.0, s * 0.02))
		if ghost_ci >= 0:
			var tex := Fabrics.get_tex(ghost_ci, ghost_set)
			if tex:
				var sq := PackedVector2Array([Vector2.ZERO, Vector2(s, 0), Vector2(s, s), Vector2(0, s)])
				var uv := PackedVector2Array()
				for q in sq:
					uv.append(q / (s * 1.7) + Vector2(0.2, 0.2))
				draw_colored_polygon(sq, Color(1, 1, 1, 0.85), uv, tex)
		if hot and hot_tex:
			var k := 1.0 + 0.05 * sin(_t * 4.0)
			var r := Rect2(Vector2(s, s) * (1.0 - k) / 2.0, Vector2(s, s) * k)
			draw_texture_rect(hot_tex, r, false, Color(1, 1, 1, 0.75 + 0.25 * sin(_t * 4.0)))
	func _gui_input(e: InputEvent) -> void:
		if not hot:
			return
		if e is InputEventScreenTouch:
			if e.pressed:
				_press = true
			elif _press:
				_press = false
				if not DragScroll.recently_dragged():
					tapped.emit()

class _Thumb extends Control:
	var patches: Array = []
	var ghost := false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := size.x / float(Quilt.COLS)
		if ghost:
			for i in Quilt.QUILT_SIZE:
				draw_rect(Rect2(Vector2(i % Quilt.COLS, i / Quilt.COLS) * c, Vector2(c, c)).grow(-1), Palette.piece((i * 3 + i / Quilt.COLS) % Palette.PIECES.size()))
		for i in patches.size():
			var p: Dictionary = patches[i]
			var si := int(p.get("slot", i))
			var cols: Array = p.get("c", [0])
			var col := Palette.piece(int(p.ci) if p.has("ci") else (int(cols[0]) if not cols.is_empty() else 0))
			draw_rect(Rect2(Vector2(si % Quilt.COLS, si / Quilt.COLS) * c, Vector2(c, c)).grow(-1), col)
