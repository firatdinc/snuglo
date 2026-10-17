extends Screen
## Günlük bulmaca ekranı: seri alevi (güncel/en iyi), bugünün 5 bulmacası (yama + oyna + geri
## sayım) ve ay takvimi (UTC; gün yaması çözülen sayıya göre dolar, bugün altın çerçeve, ay okları).

var _year := 0
var _month := 0
var _scroll: DragScroll
var _month_card: QuiltCard
var _month_y := 0.0
var _timer: Label
var _acc := 0.0

func build() -> void:
	var d := Progress.local_date(true)
	_year = int(d.year)
	_month = int(d.month)
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("flower")
	bg.wash_top = 0.55
	bg.wash_bottom = 0.85
	bg.size = size
	add_child(bg)
	var y0 := header("menu.dailyPuzzle", true)
	_scroll = DragScroll.new()
	_scroll.position = Vector2(0, y0)
	_scroll.size = Vector2(size.x, H - y0)
	add_child(_scroll)
	var c := _scroll.content
	var y := 10.0
	var cw := W - 80.0

	# Seri kartı
	var sk := QuiltCard.new()
	sk.fabric = 1
	sk.inner = 14
	sk.radius = 48
	Ui.place(sk, Vector2(X0 + 40, y), Vector2(cw, 190))
	c.add_child(sk)
	var fl := Widgets.Flame.new()
	fl.lit = Progress.daily_streak > 0
	Ui.place(fl, Vector2(40, 28), Vector2(110, 134))
	sk.add_child(fl)
	var n := Ui.label(str(Progress.daily_streak), 90, Palette.INK)
	Ui.place(n, Vector2(170, 20), Vector2(200, 150))
	sk.add_child(n)
	var st := Ui.label(tr("daily.streak.title"), 40, Palette.INK)
	Ui.place(st, Vector2(370, 40), Vector2(cw - 410, 56))
	sk.add_child(st)
	var bst := Ui.label(tr("menu.streak.best") % Progress.daily_longest, 32, Palette.INK_SOFT)
	Ui.place(bst, Vector2(370, 100), Vector2(cw - 410, 50))
	sk.add_child(bst)
	Ui.pop_in(sk, 0.05, 0.7)
	y += 220.0

	# Bugün
	var done := Progress.daily_solved_count()
	var all := Progress.is_daily_all_complete()
	var tk := QuiltCard.new()
	tk.fill = Palette.CARD
	tk.radius = 48
	tk.glow = not all
	Ui.place(tk, Vector2(X0 + 40, y), Vector2(cw, 380))
	c.add_child(tk)
	var tl := Ui.label(tr("daily.today"), 46, Palette.INK)
	Ui.place(tl, Vector2(44, 26), Vector2(cw * 0.5, 60))
	tk.add_child(tl)
	_timer = Ui.label("", 30, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	Ui.place(_timer, Vector2(cw * 0.4, 30), Vector2(cw * 0.6 - 44, 54))
	tk.add_child(_timer)
	var ps := (cw - 88.0 - 4 * 24.0) / 5.0
	for i in Progress.DAILY_LEVELS:
		var p := DayPatch.new()
		p.count = Progress.DAILY_LEVELS if i < done else 0
		p.label = str(i + 1)
		p.fabric = i * 2 + 1
		p.today = i == done and not all
		Ui.place(p, Vector2(44 + i * (ps + 24), 100), Vector2(ps, ps))
		tk.add_child(p)
		Ui.pop_in(p, 0.15 + i * 0.06, 0.4)
	var bw := cw - 88.0
	var play := Ui.button(tr("daily.allDone") if all else tr("daily.play") % (done + 1), "sage" if all else "terracotta", Vector2(bw, 120))
	Ui.place(play, Vector2(44, 120 + ps), Vector2(bw, 120))
	play.disabled = all
	play.tapped.connect(func() -> void: Main.play("daily-%d" % Progress.daily_next_index(), false))
	play.denied.connect(func() -> void: Main.toast(tr("complete.dailyComeBack"), "ic_calendar", Palette.SAGE))
	tk.add_child(play)
	tk.size.y = 120 + ps + 150
	Ui.pop_in(tk, 0.1, 0.7)
	y += tk.size.y + 30.0

	# Ay takvimi
	_month_y = y
	_build_month()
	_tick()

func _build_month() -> void:
	if _month_card:
		_month_card.queue_free()
	var cw := W - 80.0
	var card := QuiltCard.new()
	card.fabric = 9
	card.inner = 14
	card.radius = 48
	_month_card = card
	Ui.place(card, Vector2(X0 + 40, _month_y), Vector2(cw, 900))
	_scroll.content.add_child(card)
	var prev := Ui.icon_button("ic_home", 100)
	prev.icon = null
	prev.text = "‹"
	prev.font_size = 70
	prev.text_col = Palette.INK
	Ui.place(prev, Vector2(36, 30), Vector2(100, 100))
	card.add_child(prev)
	prev.tapped.connect(func() -> void: _shift(-1))
	var nxt := Ui.icon_button("ic_home", 100)
	nxt.icon = null
	nxt.text = "›"
	nxt.font_size = 70
	nxt.text_col = Palette.INK
	Ui.place(nxt, Vector2(cw - 136, 30), Vector2(100, 100))
	card.add_child(nxt)
	nxt.tapped.connect(func() -> void: _shift(1))
	var today := Progress.local_date(true)
	var is_now := _year == int(today.year) and _month == int(today.month)
	nxt.disabled = is_now
	var t := Ui.label("%s %d" % [tr("month.%d" % _month), _year], 46, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(t, Vector2(150, 40), Vector2(cw - 300, 80))
	card.add_child(t)
	var gx := 40.0
	var gap := 10.0
	var cell := (cw - gx * 2 - gap * 6) / 7.0
	for wd in 7:
		var l := Ui.label(tr("weekday.short.%d" % ((wd + 1) % 7)), 28, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(l, Vector2(gx + wd * (cell + gap), 140), Vector2(cell, 40))
		card.add_child(l)
	var days := Progress.daily_month(_year, _month)
	var first: Dictionary = days[0]
	var wd0: int = Time.get_datetime_dict_from_unix_time(Progress.day_number(first.key) * 86400 + 43200).weekday
	var col := (wd0 + 6) % 7
	var row := 0
	var ut := Progress.utc_key()
	for dd: Dictionary in days:
		var p := DayPatch.new()
		p.count = int(dd.count)
		p.label = str(dd.day)
		p.fabric = (int(dd.day) * 7) % 12
		p.today = dd.key == ut
		p.future = String(dd.key) > ut
		Ui.place(p, Vector2(gx + col * (cell + gap), 190 + row * (cell + gap)), Vector2(cell, cell))
		card.add_child(p)
		col += 1
		if col >= 7:
			col = 0
			row += 1
	var rows := row + (1 if col > 0 else 0)
	card.size.y = 190 + rows * (cell + gap) + 30
	_scroll.set_length(_month_y + card.size.y + 60 + BOTTOM)
	Ui.pop_in(card, 0.15, 0.85)

func _shift(d: int) -> void:
	_month += d
	if _month < 1:
		_month = 12
		_year -= 1
	elif _month > 12:
		_month = 1
		_year += 1
	_build_month()

func _process(dt: float) -> void:
	_acc += dt
	if _acc >= 1.0:
		_acc = 0.0
		_tick()

func _tick() -> void:
	if _timer:
		_timer.text = tr("menu.refresh") % Ui.fmt_time(Ui.seconds_to_utc_midnight())

func on_resume() -> void:
	Main.replace("daily", args, "none")

## Gün yaması: count/5 dolu → tam kumaş + yıldız; kısmi → krem + alttan dolan kumaş şerit;
## boş → tebeşir izi. today → altın nabız; future → soluk.
class DayPatch extends Control:
	var count := 0
	var label := ""
	var fabric := 0
	var today := false
	var future := false
	var _t := 0.0
	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(today)
	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var rad := size.x * 0.18
		var poly := Ui.rrect(r, rad, 4)
		var frac := clampf(count / float(Progress.DAILY_LEVELS), 0.0, 1.0)
		if count > 0:
			draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 4), size), rad, 4), Palette.SHADOW)
			draw_colored_polygon(poly, Palette.CREAM)
			var fr := Rect2(Vector2(0, size.y * (1.0 - frac)), Vector2(size.x, size.y * frac))
			var fp := Ui.rrect(fr, minf(rad, fr.size.y / 2.0), 4) if frac < 1.0 else poly
			var tex := Fabrics.get_tex(fabric)
			if tex and fp.size() > 2:
				var uv := PackedVector2Array()
				for p in fp:
					uv.append((p + Vector2(fabric * 31.0, 0)) / (tex.get_size() * 0.75))
				draw_colored_polygon(fp, Color.WHITE, uv, tex)
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-6), rad - 4, 4), 8, 6), Color(Palette.STITCH, 0.8), 2.0)
		else:
			draw_colored_polygon(poly, Color(Palette.CARD, 0.5 if not future else 0.25))
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-3), rad, 4), 9, 6), Color(Palette.INK_SOFT, 0.45 if not future else 0.2), 2.5)
		if today:
			var a := 0.55 + 0.4 * sin(_t * 4.0)
			var g := Ui.rrect(r.grow(4), rad + 4, 4)
			g.append(g[0])
			draw_polyline(g, Color(Palette.GOLD, a), 7.0, true)
		var fs := int(size.x * 0.36)
		var ts := Ui.FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var at := Vector2((size.x - ts.x) / 2.0, size.y / 2.0 + fs * 0.36)
		if count >= Progress.DAILY_LEVELS:
			draw_string_outline(Ui.FONT, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 7, Color(Palette.INK, 0.6))
			draw_string(Ui.FONT, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)
		else:
			draw_string(Ui.FONT, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Palette.INK, 0.35 if future else 0.8))
