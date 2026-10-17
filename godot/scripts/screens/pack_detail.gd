extends Screen
## Paket detayı: üstte sahne kahramanı + paket dostu + bilgi kartı, altında 60 bölüm bir yorgan
## gibi dikilmiş yamalar (5'li sıralar). Tamamlanan = kumaş yama + yıldızlar, sıradaki = nabız
## atan krem yama + maskot, kilitli = tebeşir izi + kilit, her 10. = Nook parçası (hediye) yaması.

const PackMap := preload("res://scripts/screens/pack_map.gd")
const COLS := 5

var pack_id := "cozy-beginnings"
var _scroll: DragScroll
var _current := 0

func build() -> void:
	pack_id = String(args.get("pack", "cozy-beginnings"))
	var p := Progress.pack(pack_id)
	if p.is_empty():
		pack_id = "cozy-beginnings"
		p = Progress.pack(pack_id)
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene(pack_id)
	bg.wash_top = 0.0
	bg.wash_bottom = 0.9
	bg.size = size
	add_child(bg)
	_current = Progress.next_unplayed(pack_id)

	var head_h := TOP + 170.0
	_scroll = DragScroll.new()
	_scroll.position = Vector2(0, head_h)
	_scroll.size = Vector2(size.x, H - head_h)
	add_child(_scroll)
	var c := _scroll.content

	# Kahraman: sahne zaten arkada; dost + bilgi kartı
	var hero_h := 400.0
	var fr := Ui.tex_rect(PackArt.animal(pack_id), Vector2(300, 300))
	Ui.place(fr, Vector2(X0 + W - 360, hero_h - 330), Vector2(300, 300))
	c.add_child(fr)
	Ui.pop_in(fr, 0.2, 0.3, 0.55)
	Ui.bob(fr, 8.0, 2.4)

	var info := QuiltCard.new()
	info.fabric = PackArt.fabric(pack_id)
	info.inner = 16
	info.radius = 52
	Ui.place(info, Vector2(X0 + 40, hero_h - 60), Vector2(W - 80, 290))
	c.add_child(info)
	var iw := W - 80
	var g := int(p.grid)
	var t := Ui.label(tr(String(p.title)), 60, Palette.INK)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(t, Vector2(46, 34), Vector2(iw - 92, 76))
	info.add_child(t)
	var sub := Ui.label("%s · %s" % [tr("pack.grid_label.%d" % g), tr(PackArt.difficulty_key(g))], 32, Palette.INK_SOFT)
	Ui.place(sub, Vector2(46, 106), Vector2(iw - 92, 46))
	info.add_child(sub)
	var done := Progress.pack_completed_count(pack_id)
	var bar := Widgets.StitchBar.new()
	bar.value = float(done) / float(p.levels)
	bar.col = Palette.MUSTARD if done >= int(p.levels) else Palette.SAGE
	Ui.place(bar, Vector2(46, 172), Vector2(iw - 400, 38))
	info.add_child(bar)
	var dl := Ui.label("%d/%d" % [done, int(p.levels)], 32, Palette.INK)
	Ui.place(dl, Vector2(46, 214), Vector2(200, 46))
	info.add_child(dl)
	var st := Ui.icon("ic_star", Vector2(64, 64))
	Ui.place(st, Vector2(iw - 330, 160), Vector2(64, 64))
	info.add_child(st)
	var sl := Ui.label("%d/%d" % [Progress.pack_stars(pack_id), int(p.levels) * 3], 40, Palette.INK)
	Ui.place(sl, Vector2(iw - 260, 160), Vector2(220, 64))
	info.add_child(sl)
	if Progress.is_pack_complete(pack_id):
		var seal := PackMap.Seal.new()
		Ui.place(seal, Vector2(iw - 150, -50), Vector2(130, 130))
		info.add_child(seal)
	Ui.slide_in(info, 0.05, 60.0)

	# Yorgan ızgarası
	var gy := hero_h + 270.0
	var gap := 18.0
	var cell := (W - 80.0 - gap * (COLS - 1)) / COLS
	var quilt := QuiltBack.new()
	var rows := int(ceil(float(p.levels) / COLS))
	Ui.place(quilt, Vector2(X0 + 24, gy - 16), Vector2(W - 48, rows * (cell + gap) - gap + 32 + (rows / 2) * 70.0))
	c.add_child(quilt)
	var y := gy
	var cur_y := gy
	for i in range(1, int(p.levels) + 1):
		var col := (i - 1) % COLS
		if col == 0 and i > 1:
			y += cell + gap
			if (i - 1) % 10 == 0:
				var lbl := Ui.label("— %d —" % (i - 1), 28, Color(Palette.INK_SOFT, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
				Ui.place(lbl, Vector2(X0, y - 6), Vector2(W, 60))
				c.add_child(lbl)
				y += 70.0
		var patch := Patch.new()
		patch.n = i
		patch.pack_id = pack_id
		var lid := Progress.level_id(pack_id, i)
		patch.completed = Progress.is_completed(lid)
		patch.stars = Progress.stars(lid)
		patch.playable = Progress.can_play(pack_id, i)
		patch.current = i == _current
		patch.milestone = i % Nook.LEVELS_PER_PIECE == 0
		patch.fabric = (i * 5 + Progress.pack_index(pack_id) * 3) % 12
		Ui.place(patch, Vector2(X0 + 40 + col * (cell + gap), y), Vector2(cell, cell))
		c.add_child(patch)
		if patch.current:
			cur_y = y
		var n := i
		patch.tapped.connect(func() -> void:
			if Progress.can_play(pack_id, n):
				Main.play(Progress.level_id(pack_id, n), false)
			else:
				Ui.shake(patch, 10.0)
				Main.toast(tr("a11y.packLockedHint") if not Progress.is_pack_unlocked(pack_id) else tr("pack.locked"), "ic_lock", Palette.LOCKED.darkened(0.3)))
	quilt.size.y = y + cell + 16.0 - quilt.position.y
	var total := y + cell + 60.0 + BOTTOM
	_scroll.set_length(total)
	if _current > COLS * 2:
		_scroll.scroll_to(cur_y - _scroll.size.y * 0.45, false)

	# Sabit başlık şeridi (geri + bar) kaydırmanın üstünde
	var strip := QuiltCard.new()
	strip.fabric = PackArt.fabric(pack_id)
	strip.radius = 50
	strip.depth = 12
	put(strip, Vector2(-30, -60), Vector2(size.x + 60, head_h + 50))
	var b := Ui.icon_button("ic_home", 120)
	b.icon = null
	b.text = "‹"
	b.font_size = 84
	b.text_col = Palette.INK
	put(b, Vector2(X0 + 30, TOP + 30), Vector2(120, 120))
	b.tapped.connect(func() -> void: Main.back())
	var tb := TopBar.new()
	tb.align_right = true
	put(tb, Vector2(X0 + 170, TOP + 48), Vector2(W - 200, 90))

func on_resume() -> void:
	Main.replace("pack", args, "none")

## Yorgan sırtı: yamaların arkasında koyu keten zemin + kenar dikişi.
class QuiltBack extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 10), size), 40), Palette.SHADOW)
		draw_colored_polygon(Ui.rrect(r, 40), Palette.BOARD_EDGE)
		draw_colored_polygon(Ui.rrect(r.grow(-8), 34), Palette.BOARD)
		draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-4), 38), 16, 10), Color(Palette.STITCH, 0.8), 3.0)

## Tek bölüm yaması (hafif: yalnız basınca/nabızda yeniden çizer).
class Patch extends Control:
	signal tapped
	var n := 1
	var pack_id := ""
	var completed := false
	var stars := 0
	var playable := false
	var current := false
	var milestone := false
	var fabric := 0
	var _down := false
	var _press := 0.0
	var _t := 0.0
	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		mouse_filter = Control.MOUSE_FILTER_STOP
		pivot_offset = size / 2.0
		set_process(current)
		if current:
			var m := Ui.icon("idle", Vector2(size.x * 0.5, size.x * 0.5), "mascot")
			m.position = Vector2(size.x * 0.66, -size.x * 0.34)
			add_child(m)
			Ui.bob(m, 6.0, 1.4)
	func _gui_input(e: InputEvent) -> void:
		if e is InputEventScreenTouch or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
			if e.pressed:
				_down = true
				set_process(true)
				Juice.haptic("tick")
			elif _down:
				_down = false
				if Rect2(Vector2.ZERO, size).has_point(e.position) and not DragScroll.recently_dragged():
					Sfx.play("click", 1.0, -5.0)
					tapped.emit()
			accept_event()
	func _process(dt: float) -> void:
		_t += dt
		if _down and DragScroll.recently_dragged():
			_down = false
		_press = move_toward(_press, 1.0 if _down else 0.0, dt * 12.0)
		var k := 1.0 - 0.06 * _press
		if current and not Ui.reduce_motion():
			k *= 1.0 + 0.035 * sin(_t * 4.0)
		scale = Vector2(k, k)
		queue_redraw()
		if not current and _press == 0.0:
			scale = Vector2.ONE
			set_process(false)
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var rad := size.x * 0.16
		var poly := Ui.rrect(r, rad, 4)
		if completed:
			draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 6), size), rad, 4), Palette.SHADOW)
			var tex := Fabrics.get_tex(fabric)
			if tex:
				var uv := PackedVector2Array()
				for p in poly:
					uv.append((p + Vector2(fabric * 37.0, n * 23.0)) / (tex.get_size() * 0.75))
				draw_colored_polygon(poly, Color.WHITE, uv, tex)
			else:
				draw_colored_polygon(poly, Palette.piece(fabric))
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-9), rad - 6, 4), 10, 7), Color(Palette.STITCH, 0.85), 3.0)
			_num(Palette.CREAM, size.y * 0.47)
			var st := UiArt.tex("ic_star")
			var s := size.x * 0.24
			for i in 3:
				var at := Vector2(size.x / 2.0 + (i - 1) * s * 0.95 - s / 2.0, size.y * 0.66 - (s * 0.12 if i == 1 else 0.0))
				draw_texture_rect(st, Rect2(at, Vector2(s, s)), false, Color.WHITE if i < stars else Color(1, 0.97, 0.9, 0.28))
		elif playable:
			draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 6), size), rad, 4), Palette.SHADOW)
			draw_colored_polygon(poly, Palette.CREAM)
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-9), rad - 6, 4), 10, 7), Color(Palette.STITCH_DARK, 0.6), 3.0)
			if current:
				var a := 0.5 + 0.4 * sin(_t * 4.0)
				draw_polyline(Ui.rrect(r.grow(4), rad + 4, 4) + PackedVector2Array([Ui.rrect(r.grow(4), rad + 4, 4)[0]]), Color(Palette.GOLD, a), 9.0, true)
			_num(Palette.INK, size.y * 0.55)
		else:
			draw_colored_polygon(poly, Color(Palette.CARD, 0.35))
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-4), rad, 4), 12, 8), Color(Palette.INK_SOFT, 0.5), 3.0)
			var lk := UiArt.tex("ic_lock")
			var s := size.x * 0.26
			draw_texture_rect(lk, Rect2(Vector2(size.x - s - 12, size.y - s - 10), Vector2(s * 0.75, s)), false, Color(1, 1, 1, 0.75))
			_num(Color(Palette.INK, 0.4), size.y * 0.55)
		if milestone:
			var g := UiArt.tex("ic_gift")
			var s := size.x * 0.36
			draw_texture_rect(g, Rect2(Vector2(-s * 0.2, -s * 0.25), Vector2(s, s)), false, Color.WHITE if not completed else Color(1, 1, 1, 0.9))
		if _press > 0.0:
			draw_colored_polygon(poly, Color(Palette.INK, 0.08 * _press))
	func _num(col: Color, base_y: float) -> void:
		var t := str(n)
		var fs := int(size.x * 0.34)
		var ts := Ui.FONT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var p := Vector2((size.x - ts.x) / 2.0, base_y)
		if col == Palette.CREAM:
			draw_string_outline(Ui.FONT, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(Palette.INK, 0.55))
		draw_string(Ui.FONT, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
