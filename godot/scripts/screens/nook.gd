extends Screen
## Sıcak Köşe (Swift NookView v2): paket şeridi → seçili paketin sahnesi 6 yorgan yamasına bölünür;
## yerleşmemiş yamalar karanlık siluet + tebeşir dikiş, sıradaki altın nabız atar. Tepsideki
## parlayan parçayı sürükleyip yuvasına bırak (Nook.place_next_piece). Tam restorasyon → konfeti +
## paket dostu evine döner. Altta: dekor rafı (yerleşen parça sayısıyla açılır), dünya yüzdesi ve
## kurtarılan dostlar. args: pack (seçili), auto_return (yerleştirince geri dön).

const PackMap := preload("res://scripts/screens/pack_map.gd")
const DECOR := ["tea", "plant", "photo", "lamp", "clock", "books", "teddy", "fish", "guitar", "console",
	"sofa", "bed", "fairylights", "starlight", "fireplace", "royal"]
## Dekor k, toplam yerleşen parça ≥ k*DECOR_STEP + 1 olunca açılır (ekonomi yok, yalnız ilerleme).
const DECOR_STEP := 3

var pack_id := ""
var _canvas: SceneCanvas
var _frame: QuiltCard
var _tray: Control
var _tray_piece: ShardView
var _tray_text: Label
var _drag: ShardView
var _drag_off := Vector2.ZERO
var _strip: DragScroll
var _footer_label: Label
var _footer_bar: Widgets.StitchBar
var _friends: DragScroll
var _shelf: DragScroll
var _fx: Fx
var _friend: TextureRect
var _badge: Control

func build() -> void:
	pack_id = String(args.get("pack", _default_pack()))
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene(pack_id)
	bg.wash_top = 0.6
	bg.wash_bottom = 0.9
	bg.darken = 0.0
	bg.size = size
	add_child(bg)
	var y := header("nook.title", false)
	y -= 10.0
	# Paket şeridi
	_strip = DragScroll.new()
	_strip.horizontal = true
	_strip.position = Vector2(X0, y)
	_strip.size = Vector2(W, 190)
	add_child(_strip)
	_build_strip()
	y += 200.0
	# Esnek: tuval
	var tray_h := 210.0
	var shelf_h := 170.0
	var foot_h := 230.0
	var avail := H - BOTTOM - y - tray_h - shelf_h - foot_h - 40.0
	var cw := W - 80.0
	var ch := minf(avail, cw * 1.3)
	_frame = QuiltCard.new()
	_frame.fabric = 10
	_frame.radius = 46
	_frame.depth = 14
	put(_frame, Vector2(X0 + 40 - 22, y - 22), Vector2(cw + 44, ch + 44))
	_canvas = SceneCanvas.new()
	put(_canvas, Vector2(X0 + 40, y), Vector2(cw, ch))
	y += ch + 40.0
	_tray = QuiltCard.new()
	(_tray as QuiltCard).fill = Palette.CARD
	(_tray as QuiltCard).radius = 44
	put(_tray, Vector2(X0 + 40, y), Vector2(cw, tray_h - 20))
	_tray_text = Ui.label("", 34, Palette.INK)
	_tray_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tray_text.position = Vector2(250, 20)
	_tray_text.size = Vector2(cw - 280, tray_h - 60)
	_tray.add_child(_tray_text)
	y += tray_h
	# Dekor rafı
	_shelf = DragScroll.new()
	_shelf.horizontal = true
	_shelf.position = Vector2(X0 + 20, y)
	_shelf.size = Vector2(W - 40, shelf_h)
	add_child(_shelf)
	_build_shelf()
	y += shelf_h + 10.0
	# Alt: dünya yüzdesi + dostlar
	_footer_label = Ui.label("", 32, Palette.INK)
	put(_footer_label, Vector2(X0 + 50, y), Vector2(W * 0.5, 50))
	var fl2 := Ui.label(tr("nook.friends") % [Nook.unlocked_mascot_count(), Progress.PACKS.size()], 32, Palette.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	put(fl2, Vector2(X0 + W * 0.5, y), Vector2(W * 0.5 - 50, 50))
	_footer_bar = Widgets.StitchBar.new()
	_footer_bar.col = Palette.MUSTARD
	put(_footer_bar, Vector2(X0 + 50, y + 54), Vector2(W - 100, 26))
	_friends = DragScroll.new()
	_friends.horizontal = true
	_friends.position = Vector2(X0 + 20, y + 88)
	_friends.size = Vector2(W - 40, 110)
	add_child(_friends)
	_build_friends()
	_fx = Fx.new()
	add_child(_fx)
	_select(pack_id, false)
	Ui.pop_in(_frame, 0.05, 0.8)
	Ui.pop_in(_canvas, 0.05, 0.8)
	Ui.slide_in(_tray as Control, 0.12)

func _default_pack() -> String:
	for p in Progress.PACKS:
		if Nook.available_pieces(p.id) > 0:
			return p.id
	for p in Progress.PACKS:
		if not Nook.is_restored(p.id):
			return p.id
	return Progress.PACKS[0].id

# ------------------------------------------------------------------ Şerit / raf / dostlar

func _build_strip() -> void:
	for c in _strip.content.get_children():
		c.queue_free()
	var x := 30.0
	for p in Progress.PACKS:
		var id: String = p.id
		var card := QuiltCard.new()
		card.pressable = true
		card.fill = Palette.CARD
		card.radius = 34
		card.depth = 6
		card.glow = id == pack_id
		Ui.place(card, Vector2(x, 14), Vector2(150, 160))
		_strip.content.add_child(card)
		var win := PackMap.SceneWindow.new()
		win.tex = PackArt.scene(id)
		win.radius = 24
		win.grey = Nook.placed_pieces(id) == 0
		Ui.place(win, Vector2(14, 12), Vector2(122, 100))
		card.add_child(win)
		var l := Ui.label("%d/%d" % [Nook.placed_pieces(id), Nook.PIECES_PER_SCENE], 28, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(l, Vector2(0, 112), Vector2(150, 44))
		card.add_child(l)
		if Nook.available_pieces(id) > 0:
			var b := Ui.badge(str(Nook.available_pieces(id)), Palette.MUSTARD.darkened(0.1))
			b.position = Vector2(104, -10)
			card.add_child(b)
		elif Nook.is_restored(id):
			var st := Ui.icon("ic_star", Vector2(48, 48))
			st.position = Vector2(106, -8)
			card.add_child(st)
		card.tapped.connect(func() -> void:
			if id != pack_id:
				_select(id, true))
		x += 170.0
	_strip.set_length(x + 20.0)

func _scroll_strip_to_selected() -> void:
	var i := Progress.pack_index(pack_id)
	_strip.scroll_to(30.0 + i * 170.0 - (_strip.size.x - 150.0) / 2.0, false)

func _placed_total() -> int:
	var n := 0
	for p in Progress.PACKS:
		n += Nook.placed_pieces(p.id)
	return n

func _build_shelf() -> void:
	for c in _shelf.content.get_children():
		c.queue_free()
	var total := _placed_total()
	var plank := Plank.new()
	var item := 128.0
	var gap := 18.0
	var len := 30.0 + DECOR.size() * (item + gap) + 20.0
	Ui.place(plank, Vector2(0, 112), Vector2(len, 46))
	_shelf.content.add_child(plank)
	var x := 30.0
	for k in DECOR.size():
		var id: String = DECOR[k]
		var need := k * DECOR_STEP + 1
		var unlocked := total >= need
		var tex := PackArt.decor(id)
		var hit := QuiltCard.new()
		hit.pressable = true
		hit.fill = Color(0, 0, 0, 0)
		hit.depth = 0
		hit.stitch = false
		Ui.place(hit, Vector2(x, 0), Vector2(item, 124))
		_shelf.content.add_child(hit)
		if tex:
			var t := Ui.tex_rect(tex, Vector2(item, 118))
			if not unlocked:
				t.modulate = Color(0.16, 0.12, 0.12, 0.42)
			hit.add_child(t)
			if unlocked:
				Ui.bob(t, 3.0, 2.6 + k * 0.13, k)
		else:
			var ph := Ui.icon("ic_lock" if not unlocked else "ic_heart", Vector2(80, 80))
			ph.position = Vector2((item - 80) / 2.0, 30)
			hit.add_child(ph)
		var dn := id
		hit.tapped.connect(func() -> void:
			if unlocked:
				Main.toast(tr("nook.decor." + dn), "", Palette.SAGE)
				Ui.punch(hit, 0.2)
			else:
				Main.toast(tr("nook.decor.unlock") % (need - total), "ic_lock", Palette.LOCKED.darkened(0.3))
				Ui.shake(hit, 8.0))
		x += item + gap
	_shelf.set_length(len)

func _build_friends() -> void:
	for c in _friends.content.get_children():
		c.queue_free()
	var x := 20.0
	for p in Progress.PACKS:
		var got := Nook.is_mascot_unlocked(p.id)
		var t := Ui.tex_rect(PackArt.animal(p.id), Vector2(100, 100))
		t.position = Vector2(x, 4)
		if not got:
			t.modulate = Color(0.25, 0.2, 0.2, 0.5)
		_friends.content.add_child(t)
		x += 112.0
	_friends.set_length(x + 10.0)

# ------------------------------------------------------------------ Seçim / tepsi

func _select(id: String, animate: bool) -> void:
	pack_id = id
	args["pack"] = id
	_canvas.setup(PackArt.scene(id), id, Nook.placed_pieces(id), Nook.available_pieces(id) > 0)
	if animate:
		Ui.punch(_canvas, 0.04)
		Sfx.play("click", 1.1, -6.0)
		_build_strip()
	_scroll_strip_to_selected()
	_refresh_tray()
	_refresh_footer()
	_show_friend(Nook.is_restored(id), false)

func _refresh_footer() -> void:
	var pct := int(round(Nook.completion() * 100.0))
	_footer_label.text = tr("nook.world.restored") % pct
	_footer_bar.value = Nook.completion()

func _refresh_tray() -> void:
	if _tray_piece and is_instance_valid(_tray_piece):
		_tray_piece.queue_free()
	_tray_piece = null
	var avail := Nook.available_pieces(pack_id)
	if Nook.is_restored(pack_id):
		_tray_text.text = tr("nook.scene.done")
		var st := Ui.tex_rect(PackArt.animal(pack_id), Vector2(170, 170))
		st.position = Vector2(40, 10)
		st.name = "tray_icon"
		_clear_tray_icon()
		_tray.add_child(st)
	elif avail > 0:
		_clear_tray_icon()
		_tray_text.text = tr("nook.drag.hint") + "\n" + tr("nook.pieces.ready") % avail
		var idx: int = _canvas.order[Nook.placed_pieces(pack_id)]
		_tray_piece = ShardView.new()
		_tray_piece.setup(_canvas, idx)
		_tray_piece.glow = true
		_tray_piece.position = Vector2(30, 15)
		_tray_piece.size = Vector2(190, 160)
		_tray.add_child(_tray_piece)
		_tray_piece.gui_input.connect(_on_piece_input)
		_tray_piece.mouse_filter = Control.MOUSE_FILTER_STOP
		Ui.pop_in(_tray_piece, 0.2, 0.3)
		if UiArt.tex("ic_hand"):
			var hand := Ui.icon("ic_hand", Vector2(100, 100))
			hand.position = Vector2(150, 90)
			hand.name = "tray_icon"
			_tray.add_child(hand)
			if not Ui.reduce_motion():
				var tw := hand.create_tween().set_loops()
				tw.tween_property(hand, "position", Vector2(150, 50), 0.6).set_trans(Tween.TRANS_SINE)
				tw.tween_property(hand, "position", Vector2(150, 90), 0.6).set_trans(Tween.TRANS_SINE)
	else:
		_clear_tray_icon()
		var c := Progress.pack_completed_count(pack_id)
		var need := (Nook.earned_pieces(pack_id) + 1) * Nook.LEVELS_PER_PIECE - c
		_tray_text.text = tr("nook.locked.hint") % maxi(1, need)
		var lk := Ui.icon("ic_lock", Vector2(130, 130))
		lk.position = Vector2(60, 30)
		lk.name = "tray_icon"
		_tray.add_child(lk)

func _clear_tray_icon() -> void:
	var n := _tray.get_node_or_null("tray_icon")
	if n:
		n.name = "old_icon"
		n.queue_free()

func _show_friend(on: bool, animate: bool) -> void:
	if _friend and is_instance_valid(_friend):
		_friend.queue_free()
		_friend = null
	if _badge and is_instance_valid(_badge):
		_badge.queue_free()
		_badge = null
	if not on:
		return
	var s := minf(_canvas.size.x * 0.42, 380.0)
	_friend = Ui.tex_rect(PackArt.animal(pack_id), Vector2(s, s))
	_friend.position = Vector2(_canvas.size.x - s - 10, _canvas.size.y - s - 10)
	_canvas.add_child(_friend)
	_badge = Ribbon.new()
	_badge.text = tr("nook.restored.badge")
	_badge.position = Vector2(24, 24)
	_badge.size = Vector2(300, 80)
	_canvas.add_child(_badge)
	if animate:
		Ui.pop_in(_friend, 0.1, 0.1, 0.6)
		Ui.pop_in(_badge, 0.3, 0.3)
	Ui.bob(_friend, 7.0, 2.0)

# ------------------------------------------------------------------ Sürükle-bırak

func _on_piece_input(e: InputEvent) -> void:
	if _drag != null or _tray_piece == null:
		return
	if (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		var at: Vector2 = _tray_piece.get_global_transform_with_canvas() * e.position
		_begin_drag(at)
		_tray_piece.accept_event()

func _begin_drag(at: Vector2) -> void:
	_drag = ShardView.new()
	_drag.setup(_canvas, _tray_piece.idx)
	# Gerçek tuval ölçeğinde (×1.15) parmak altında yüzer
	var bb := _canvas.shard_bbox(_tray_piece.idx)
	_drag.size = bb.size
	_drag.pivot_offset = bb.size / 2.0
	_drag.glow = true
	_drag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_drag)
	_drag.position = at - bb.size / 2.0 - Vector2(0, 60)
	_drag.scale = Vector2(0.5, 0.5)
	_drag.create_tween().tween_property(_drag, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tray_piece.modulate.a = 0.25
	Sfx.play("click", 1.2, -4.0)
	Juice.haptic("light")
	_canvas.hot = true

func _input(e: InputEvent) -> void:
	if _drag == null:
		return
	if e is InputEventScreenDrag or (e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		var p: Vector2 = e.position
		_drag.position = p - _drag.size / 2.0 - Vector2(0, 60)
		_drag.rotation = clampf((e.relative.x if "relative" in e else 0.0) * 0.004, -0.12, 0.12)
		var local := _canvas.get_global_transform_with_canvas().affine_inverse() * (p - Vector2(0, 60))
		_canvas.set_hover(_canvas.hits_target(local))
	elif (e is InputEventScreenTouch and not e.pressed) or (e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		var p: Vector2 = e.position
		var local := _canvas.get_global_transform_with_canvas().affine_inverse() * (p - Vector2(0, 60))
		_drop(_canvas.hits_target(local))

func _drop(ok: bool) -> void:
	var d := _drag
	_drag = null
	_canvas.hot = false
	_canvas.set_hover(false)
	if ok:
		var bb := _canvas.shard_bbox(d.idx)
		var dest := _canvas.global_position + bb.position
		var tw := d.create_tween().set_parallel()
		tw.tween_property(d, "position", dest, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(d, "scale", Vector2.ONE, 0.14)
		tw.tween_property(d, "rotation", 0.0, 0.14)
		tw.chain().tween_callback(func() -> void:
			d.queue_free()
			_place())
	else:
		Juice.haptic("light")
		Sfx.play("error", 1.0, -10.0)
		var back := _tray_piece.get_global_transform_with_canvas() * Vector2.ZERO if _tray_piece else d.position
		var tw := d.create_tween().set_parallel()
		tw.tween_property(d, "position", back, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "scale", Vector2(0.5, 0.5), 0.3)
		tw.chain().tween_callback(func() -> void:
			d.queue_free()
			if _tray_piece:
				_tray_piece.modulate.a = 1.0
				Ui.punch(_tray_piece, 0.15))

func _place() -> void:
	var k := Nook.place_next_piece(pack_id)
	if k < 0:
		_refresh_tray()
		return
	var idx: int = _canvas.order[k]
	_canvas.placed = k + 1
	_canvas.available = Nook.available_pieces(pack_id) > 0
	_canvas.flash(idx)
	Sfx.play("snap", 0.8, 0.0)
	Sfx.note(k + 2, "place", -2.0)
	Juice.haptic("medium")
	Juice.add_trauma(0.2)
	var ctr := _canvas.global_position + _canvas.shard_bbox(idx).get_center()
	_fx.sparks(ctr, 22, Palette.GOLD, 700.0)
	_fx.ring(ctr, 180.0, Palette.CREAM, 16.0)
	var restored := Nook.is_restored(pack_id)
	if restored:
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			Sfx.play("reward", 1.0, 0.0, 0.0)
			Juice.add_trauma(0.45)
			Juice.haptic("heavy")
			_fx.confetti(Vector2(-20, size.y * 0.55), 80, PI * 0.2, -PI * 0.3, 2100.0)
			_fx.confetti(Vector2(size.x + 20, size.y * 0.55), 80, PI * 0.2, -PI * 0.7, 2100.0)
			_show_friend(true, true)
			_build_friends())
	_refresh_tray()
	_refresh_footer()
	_build_strip()
	_build_shelf()
	if args.get("auto_return", false):
		get_tree().create_timer(2.6 if restored else 1.2).timeout.connect(func() -> void:
			if is_inside_tree() and Main.top() == self:
				Main.back())

# ================================================================== Çizim sınıfları

## Sahne tuvali: sahne 6 düzensiz yamaya bölünür (paket başına deterministik).
class SceneCanvas extends Control:
	var tex: Texture2D
	var shards: Array = []       # normalize (0..1) poligonlar, hücre sırasıyla
	var order: Array = []        # yerleştirme sırası: order[k] = shard indeksi
	var placed := 0
	var available := false
	var hot := false
	var _hover := false
	var _t := 0.0
	var _flash := {}             # idx → 0..1
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	func setup(t: Texture2D, seed_id: String, placed_n: int, avail: bool) -> void:
		tex = t
		var g := shard_geometry(seed_id)
		shards = g.shards
		order = g.order
		placed = placed_n
		available = avail
		queue_redraw()
	func set_hover(v: bool) -> void:
		if v != _hover:
			_hover = v
			if v:
				Juice.haptic("tick")
				Sfx.play("click", 1.6, -12.0)
	func flash(idx: int) -> void:
		_flash[idx] = 1.0
	func target() -> int:
		return order[placed] if placed < order.size() else -1
	func px(idx: int) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in shards[idx]:
			out.append(p * size)
		return out
	func shard_bbox(idx: int) -> Rect2:
		var pts := px(idx)
		var r := Rect2(pts[0], Vector2.ZERO)
		for p in pts:
			r = r.expand(p)
		return r
	func hits_target(local: Vector2) -> bool:
		var t := target()
		if t < 0 or not available:
			return false
		if Geometry2D.is_point_in_polygon(local, px(t)):
			return true
		return local.distance_to(shard_bbox(t).get_center()) < size.x * 0.16
	func _process(dt: float) -> void:
		_t += dt
		for k in _flash.keys():
			_flash[k] = maxf(0.0, _flash[k] - dt * 1.6)
			if _flash[k] <= 0.0:
				_flash.erase(k)
		queue_redraw()
	func _draw() -> void:
		if tex == null or shards.is_empty():
			return
		var ts := tex.get_size()
		var tgt := target()
		for k in order.size():
			var idx: int = order[k]
			var poly := px(idx)
			var uv := PackMap.SceneWindow.cover_uv(poly, size, ts)
			var is_placed := k < placed
			if is_placed:
				draw_colored_polygon(poly, Color.WHITE, uv, tex)
			else:
				draw_colored_polygon(poly, Color(0.2, 0.16, 0.18), uv, tex)
		# Dikişler üstte
		for k in order.size():
			var idx: int = order[k]
			var poly := px(idx)
			var is_placed := k < placed
			if is_placed:
				draw_multiline(PieceShape.dashes(poly, 14, 10), Color(Palette.STITCH, 0.55), 3.0)
			else:
				draw_multiline(PieceShape.dashes(poly, 12, 10), Color(Palette.CREAM, 0.35), 3.0)
			if idx == tgt and available:
				var a := 0.06 + 0.14 * (0.5 + 0.5 * sin(_t * TAU / 1.1))
				if hot:
					a = 0.32 if _hover else 0.22
				draw_colored_polygon(poly, Color(Palette.GOLD, a))
				draw_multiline(PieceShape.dashes(poly, 16, 8), Color(Palette.GOLD, 0.9), 5.0)
			if _flash.has(idx):
				draw_colored_polygon(poly, Color(1, 1, 1, _flash[idx] * 0.9))
		# Çerçeve kenarı
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(Palette.INK, 0.35), false, 4.0)

	## 2×3 ızgara, iç köşeler kaydırılmış, iç kenarlar dalgalı (ortak kenar iki yamada aynı).
	static func shard_geometry(seed_id: String) -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(seed_id.hash()) + 7
		var V := {}
		for j in 4:
			for i in 3:
				var p := Vector2(i / 2.0, j / 3.0)
				if i == 1:
					p.x += rng.randf_range(-0.1, 0.1)
				if j == 1 or j == 2:
					p.y += rng.randf_range(-0.07, 0.07)
				V[Vector2i(i, j)] = p
		var edges := {}
		var edge := func(a: Vector2i, b: Vector2i) -> PackedVector2Array:
			var key := "%d,%d-%d,%d" % ([a.x, a.y, b.x, b.y] if (a.x < b.x or (a.x == b.x and a.y < b.y)) else [b.x, b.y, a.x, a.y])
			var lo := a if (a.x < b.x or (a.x == b.x and a.y < b.y)) else b
			var hi := b if lo == a else a
			if not edges.has(key):
				var pa: Vector2 = V[lo]
				var pb: Vector2 = V[hi]
				var border := (lo.x == hi.x and (lo.x == 0 or lo.x == 2)) or (lo.y == hi.y and (lo.y == 0 or lo.y == 3))
				var pts := PackedVector2Array()
				if border:
					pts = PackedVector2Array([pa, pb])
				else:
					var n := (pb - pa).orthogonal().normalized()
					var amp := rng.randf_range(0.018, 0.034) * (1.0 if rng.randf() < 0.5 else -1.0)
					var waves := 1.0 if rng.randf() < 0.5 else 2.0
					for s in 13:
						var t := s / 12.0
						pts.append(pa.lerp(pb, t) + n * sin(t * PI * waves) * amp)
				edges[key] = pts
			var e: PackedVector2Array = edges[key]
			if lo != a:
				var r := PackedVector2Array()
				for q in range(e.size() - 1, -1, -1):
					r.append(e[q])
				return r
			return e
		var shards := []
		for j in 3:
			for i in 2:
				var a := Vector2i(i, j)
				var b := Vector2i(i + 1, j)
				var c := Vector2i(i + 1, j + 1)
				var d := Vector2i(i, j + 1)
				var poly := PackedVector2Array()
				for pair in [[a, b], [b, c], [c, d], [d, a]]:
					var e: PackedVector2Array = edge.call(pair[0], pair[1])
					for q in e.size() - 1:
						poly.append(e[q])
				shards.append(poly)
		var order := [0, 1, 2, 3, 4, 5]
		for q in range(order.size() - 1, 0, -1):
			var r := rng.randi_range(0, q)
			var tmp = order[q]
			order[q] = order[r]
			order[r] = tmp
		return {"shards": shards, "order": order}

## Tek yama görünümü (tepsi / sürükleme / açılış kartı): tuval UV'leriyle, kutuya sığdırılmış.
class ShardView extends Control:
	var canvas_size := Vector2.ONE
	var tex: Texture2D
	var poly := PackedVector2Array()   # tuval pikseli
	var idx := 0
	var glow := false
	var _t := 0.0
	func setup(c: SceneCanvas, i: int) -> void:
		setup_raw(c.tex, c.px(i), c.size, i)
	func setup_raw(t: Texture2D, p: PackedVector2Array, csz: Vector2, i: int) -> void:
		tex = t
		poly = p
		canvas_size = csz
		idx = i
	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()
	func _draw() -> void:
		if tex == null or poly.is_empty():
			return
		var bb := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			bb = bb.expand(p)
		var k := minf(size.x / bb.size.x, size.y / bb.size.y)
		var off := (size - bb.size * k) / 2.0
		var pts := PackedVector2Array()
		for p in poly:
			pts.append((p - bb.position) * k + off)
		var uv := PackMap.SceneWindow.cover_uv(poly, canvas_size, tex.get_size())
		var sh := PackedVector2Array()
		for p in pts:
			sh.append(p + Vector2(0, 8))
		if glow:
			var a := 0.35 + 0.3 * sin(_t * 5.0)
			var halo := Geometry2D.offset_polygon(pts, 10.0, Geometry2D.JOIN_ROUND)
			if not halo.is_empty():
				draw_colored_polygon(halo[0], Color(Palette.GOLD, a))
		draw_colored_polygon(sh, Color(Palette.INK, 0.3))
		draw_colored_polygon(pts, Color.WHITE, uv, tex)
		draw_multiline(PieceShape.dashes(pts, 12, 8), Color(Palette.STITCH, 0.85), 3.0)

## Keçe raf tahtası.
class Plank extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 8), size), 16), Palette.SHADOW)
		draw_colored_polygon(Ui.rrect(r, 16), Palette.BOARD_EDGE.darkened(0.15))
		draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 0), Vector2(size.x, size.y * 0.45)), 14), Palette.BOARD_EDGE)
		draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-7), 10), 14, 9), Color(Palette.STITCH, 0.6), 2.5)

## Kurdele rozet ("Tamamlandı").
class Ribbon extends Control:
	var text := ""
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var w := Ui.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x + 90.0
		size.x = w
		pivot_offset = size / 2.0
		rotation = -0.06
	func _draw() -> void:
		var h := size.y
		var w := size.x
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 26, h / 2.0), Vector2(w, h), Vector2(0, h), Vector2(26, h / 2.0)])
		var sh := PackedVector2Array()
		for p in pts:
			sh.append(p + Vector2(0, 6))
		draw_colored_polygon(sh, Color(Palette.INK, 0.3))
		draw_colored_polygon(pts, Palette.TERRACOTTA)
		draw_multiline(PieceShape.dashes(PackedVector2Array([Vector2(30, 9), Vector2(w - 30, 9), Vector2(w - 30, h - 9), Vector2(30, h - 9)]), 10, 7), Color(Palette.STITCH, 0.8), 2.5)
		var ts := Ui.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40)
		draw_string(Ui.FONT, Vector2((w - ts.x) / 2.0, h / 2.0 + 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Palette.CREAM)
