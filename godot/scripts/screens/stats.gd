extends Screen
## İstatistikler (Swift StatsView): kahraman kart, KPI ızgarası, ömür boyu, paket ilerlemesi
## (17 sahne küçük resmi + çubuk), son 7 gün çubukları, 30 günlük yama ısı haritası, yıldız dağılımı.

var _scroll: DragScroll
var _y := 0.0
var _cw := 0.0
var _st := {}

func build() -> void:
	_st = Progress.stats()
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("flower")
	bg.wash_top = 0.85
	bg.wash_bottom = 0.95
	bg.motes = 8
	bg.size = size
	add_child(bg)
	var top := header("stats.title")
	var sh := Ui.icon_button("ic_share", 120)
	put(sh, Vector2(X0 + W - 150, TOP + 30.0), Vector2(120, 120))
	sh.tapped.connect(_share)
	Ui.pop_in(sh, 0.1)
	_scroll = DragScroll.new()
	put(_scroll, Vector2(X0, top), Vector2(W, H - top))
	_cw = W - 80
	_y = 10.0
	_hero()
	_kpis()
	_lifetime()
	_packs()
	_week()
	_heat()
	_stars()
	_scroll.set_length(_y + BOTTOM + 60)
	var ds := Dev.env("SNUG_SCROLL")
	if ds != "":
		_scroll.scroll_to(float(ds), false)

func _add(c: Control, pos: Vector2, sz: Vector2, parent: Control = null) -> Control:
	Ui.place(c, pos, sz)
	(parent if parent else _scroll.content).add_child(c)
	return c

func _section(key: String) -> void:
	_y += 22
	_add(Ui.title(tr(key), 48, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT), Vector2(50, _y), Vector2(_cw, 62))
	_y += 74

func _card(h: float, fabric := -1, x := 40.0, w := -1.0) -> QuiltCard:
	var c := QuiltCard.new()
	c.fabric = fabric
	c.fill = Palette.CARD
	c.inner = 12.0 if fabric >= 0 else 0.0
	c.radius = 44
	_add(c, Vector2(x, _y), Vector2(_cw if w < 0 else w, h))
	Ui.pop_in(c, minf(_y / 5000.0, 0.35), 0.85)
	return c

func _hero() -> void:
	var c := _card(250, 9)
	var m := Ui.icon("think", Vector2(230, 240), "mascot")
	_add(m, Vector2(20, 4), m.size, c)
	Ui.bob(m, 5.0, 2.6)
	_add(Ui.label(tr("stats.header"), 54, Palette.INK), Vector2(260, 40), Vector2(_cw - 290, 70), c)
	var ps := int(_st.play_streak)
	var line := tr("stats.streakActive") % ps if ps > 0 else tr("stats.streakEmpty")
	var l := Ui.wrap(Ui.label(line, 32, Palette.INK_SOFT), _cw - 300)
	_add(l, Vector2(260, 116), Vector2(_cw - 300, 100), c)
	_y += 270

func _tile(x: float, w: float, icon: String, value: String, key: String, fabric: int) -> void:
	var c := _card(220, fabric, x, w)
	var ic := Ui.icon(icon, Vector2(96, 96))
	_add(ic, Vector2(24, 24), ic.size, c)
	var v := Ui.label(value, 58, Palette.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	v.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_add(v, Vector2(120, 28), Vector2(w - 150, 90), c)
	var k := Ui.label(tr(key), 32, Palette.INK_SOFT)
	k.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_add(k, Vector2(30, 136), Vector2(w - 60, 56), c)

func _grid(items: Array) -> void:
	var w := (_cw - 24) / 2.0
	for i in items.size():
		var it: Array = items[i]
		var x := 40.0 + (i % 2) * (w + 24)
		_tile(x, w, it[0], it[1], it[2], it[3])
		if i % 2 == 1 or i == items.size() - 1:
			_y += 244

func _kpis() -> void:
	_y += 6
	_grid([
		["ic_star", "%d" % int(_st.total_levels), "stats.levelsCompleted", 5],
		["ic_heart", "%d" % int(_st.play_streak), "stats.streak", 0],
		["ic_stats", Progress.format_time(float(_st.avg_time)) if int(_st.total_levels) > 0 else "—", "stats.avgTime", 1],
		["ic_calendar", "%d" % int(_st.daily_solved_total), "stats.dailySolved", 3],
	])

func _lifetime() -> void:
	_section("stats.lifetime.title")
	_grid([
		["ic_star", "%d" % int(_st.stars), "stats.starsEarned", 11],
		["ic_trophy", "%d" % int(_st.perfect), "stats.perfectSolves", 4],
		["ic_energy", Progress.format_time(float(_st.best_time)), "stats.bestTime", 6],
		["ic_heart", "%d" % int(_st.longest_play_streak), "stats.longestStreak", 7],
	])

func _packs() -> void:
	_section("stats.packProgress")
	var packs: Array = _st.packs
	var rh := 150.0
	var c := _card(packs.size() * rh + 30)
	for i in packs.size():
		var p: Dictionary = packs[i]
		var y := 15.0 + i * rh
		var frame := QuiltCard.new()
		frame.fabric = PackArt.fabric(String(p.id))
		frame.radius = 22
		frame.depth = 4
		frame.stitch = false
		_add(frame, Vector2(26, y + 12), Vector2(126, 126), c)
		var th := Ui.tex_rect(PackArt.scene(String(p.id)), Vector2(108, 108), true)
		th.clip_contents = true
		_add(th, Vector2(9, 9), th.size, frame)
		if not p.unlocked:
			th.modulate = Color(0.45, 0.42, 0.4)
			var lk := Ui.icon("ic_lock", Vector2(60, 60))
			_add(lk, Vector2(33, 33), lk.size, frame)
		var t := Ui.label(tr(String(p.title)), 36, Palette.INK if p.unlocked else Palette.INK_SOFT)
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_add(t, Vector2(176, y + 14), Vector2(_cw - 420, 54), c)
		var sl := Ui.label("★ %d/%d" % [int(p.stars), int(p.stars_max)], 28, Palette.MUSTARD.darkened(0.25), HORIZONTAL_ALIGNMENT_RIGHT)
		_add(sl, Vector2(_cw - 250, y + 16), Vector2(210, 50), c)
		var bar := Widgets.StitchBar.new()
		bar.col = Palette.piece(i)
		bar.value = float(p.completed) / maxf(1.0, float(p.total))
		_add(bar, Vector2(176, y + 78), Vector2(_cw - 360, 36), c)
		_add(Ui.label("%d/%d" % [int(p.completed), int(p.total)], 28, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(_cw - 180, y + 72), Vector2(140, 48), c)
	_y += c.size.y + 10

func _week() -> void:
	_section("stats.last7Days")
	var c := _card(340)
	var days: Array = _st.last7
	var cw := (_cw - 80) / 7.0
	for i in days.size():
		var d: Dictionary = days[i]
		var h := 200.0 * float(d.count) / float(Progress.DAILY_LEVELS)
		var bar := Col.new()
		bar.frac = float(d.count) / float(Progress.DAILY_LEVELS)
		bar.today = d.today
		bar.idx = i
		_add(bar, Vector2(40 + i * cw + cw * 0.18, 30), Vector2(cw * 0.64, 220), c)
		var n := Ui.label(String(d.key).substr(8, 2), 28, Palette.INK if d.today else Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		_add(n, Vector2(40 + i * cw, 262), Vector2(cw, 44), c)
		if h <= 0.0:
			pass
	_y += 360

func _heat() -> void:
	_section("stats.heatmap.title")
	var c := _card(330)
	var heat: Array = _st.heatmap30
	var cols := 10
	var gap := 12.0
	var s := minf((_cw - 80 - gap * (cols - 1)) / cols, 70.0)
	var x0 := (_cw - (s * cols + gap * (cols - 1))) / 2.0
	for i in heat.size():
		var p := Patch.new()
		p.on = heat[i]
		p.idx = i
		_add(p, Vector2(x0 + (i % cols) * (s + gap), 30 + (i / cols) * (s + gap)), Vector2(s, s), c)
		if heat[i]:
			Ui.pop_in(p, 0.3 + i * 0.015, 0.2)
	var l := Ui.label(tr("stats.activeDays") % int(_st.active_days_30), 32, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_add(l, Vector2(0, 30 + 3 * (s + gap) + 6), Vector2(_cw, 50), c)
	_y += 350

func _stars() -> void:
	_section("stats.stars.title")
	var dist: Array = _st.star_distribution
	var c := _card(4 * 76 + 40)
	var mx := 1
	for v in dist:
		mx = maxi(mx, int(v))
	for k in range(3, -1, -1):
		var row := 3 - k
		var y := 22.0 + row * 76
		for s in 3:
			var st := Ui.icon("ic_star", Vector2(50, 50))
			st.modulate = Color.WHITE if s < k else Color(1, 1, 1, 0.22)
			_add(st, Vector2(30 + s * 50, y + 8), st.size, c)
		var bar := Widgets.StitchBar.new()
		bar.col = [Palette.LOCKED, Palette.TERRACOTTA, Palette.SAGE, Palette.MUSTARD][k]
		bar.value = float(dist[k]) / float(mx)
		_add(bar, Vector2(200, y + 14), Vector2(_cw - 340, 40), c)
		_add(Ui.label(str(dist[k]), 34, Palette.INK, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(_cw - 130, y), Vector2(90, 66), c)
	_y += c.size.y + 20

## Günlük çözüm sütunu: kumaş dolgulu, bugün altın kenarlı.
class Col extends Control:
	var frac := 0.0
	var today := false
	var idx := 0
	var _k := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		create_tween().tween_property(self, "_k", 1.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2 + idx * 0.05)
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_multiline(PieceShape.dashes(Ui.rrect(r, 16, 3), 8, 6), Color(Palette.INK_SOFT, 0.35), 2.0)
		var h := size.y * frac * _k
		if h > 2.0:
			var b := Rect2(Vector2(0, size.y - h), Vector2(size.x, h))
			var tex := Fabrics.get_tex(idx * 2 + 1)
			var poly := Ui.rrect(b, minf(16.0, h / 2.0), 3)
			if tex:
				var uv := PackedVector2Array()
				for p in poly:
					uv.append(p / (tex.get_size() * 0.75))
				draw_colored_polygon(poly, Color.WHITE, uv, tex)
			else:
				draw_colored_polygon(poly, Palette.piece(idx))
		if today:
			draw_polyline(Ui.rrect(r.grow(5), 20, 3) + PackedVector2Array([Ui.rrect(r.grow(5), 20, 3)[0]]), Palette.GOLD, 5.0, true)

## Isı haritası yaması: oynanan gün kumaş + dikiş, boş gün tebeşir izi.
class Patch extends Control:
	var on := false
	var idx := 0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if on:
			var tex := Fabrics.get_tex((idx * 5) % 12)
			var poly := Ui.rrect(r, 12, 3)
			draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 4), size), 12, 3), Palette.SHADOW)
			if tex:
				var uv := PackedVector2Array()
				for p in poly:
					uv.append(p / (tex.get_size() * 0.75))
				draw_colored_polygon(poly, Color.WHITE, uv, tex)
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-7), 8, 3), 6, 4), Color(Palette.STITCH, 0.8), 2.0)
		else:
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-3), 12, 3), 7, 5), Color(Palette.INK_SOFT, 0.4), 2.5)

## Swift StatsShareCard: ekran görüntüsü + özet metin.
func _share() -> void:
	var lines := ["Snuglo — " + tr("stats.share.title"),
		"★ %d · %s %d" % [int(_st.stars), tr("stats.levelsCompleted"), int(_st.total_levels)],
		"%s %d · %s %d" % [tr("share.streak"), int(_st.play_streak), tr("stats.dailySolved"), int(_st.daily_solved_total)]]
	if float(_st.best_time) > 0.0:
		lines.append("%s %s" % [tr("stats.bestTime"), Progress.format_time(float(_st.best_time))])
	lines.append("Snuglo · " + tr("share.tagline"))
	Share.share(self, "\n".join(lines))
