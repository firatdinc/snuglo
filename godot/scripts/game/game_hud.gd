class_name GameHud
extends Control
## Oyun HUD'u (Game'in çocuğu, sarsılmaz): duraklat, başlık, coin cebi, süre hapı, zincir rozeti,
## alt güçlendirme barı (ipucu / göz at / yeniden diz). Mantık GameScreen'de; HUD yalnız gösterir
## ve sinyal yayar.

signal pause_pressed
signal powerup(kind: String)

const KINDS := ["hint", "peek", "shuffle"]
const ICONS := {"hint": "ic_hint", "peek": "ic_peek", "shuffle": "ic_restart"}
const NAMES := {"hint": "powerup.hint", "peek": "powerup.peek", "shuffle": "powerup.shuffle"}

var top_h := 0.0          ## HUD'un kapladığı üst yükseklik (tahta alanı bunun altından başlar)
var bottom_h := 0.0       ## alt güç barı yüksekliği
var _timer_pill: QuiltCard
var _timer_label: Label
var _timer_icon: Control
var _chain: Control
var _btns := {}
var _urgent := false
var _pulse_t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## title: büyük başlık, sub: küçük alt başlık; relaxed: süre yukarı sayar (kalp ikonu).
func setup(title: String, sub: String, relaxed: bool) -> void:
	var vp := Ui.vp()
	size = vp
	var x0 := Ui.col_x()
	var w := Ui.col_w()
	var y := Ui.safe_top() + 24.0
	var pause := Ui.icon_button("ic_pause", 120)
	Ui.place(pause, Vector2(x0 + 30, y), Vector2(120, 120))
	add_child(pause)
	pause.tapped.connect(func() -> void: pause_pressed.emit())
	Ui.pop_in(pause, 0.1)
	var bar := TopBar.new()
	bar.currencies = ["coin"]
	bar.tap_to_shop = false
	Ui.place(bar, Vector2(x0 + w - 300, y + 18), Vector2(270, 110))
	add_child(bar)
	var t := Ui.title(title, 50, Palette.CREAM)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(t, Vector2(x0 + 170, y - 2), Vector2(w - 480, 70))
	add_child(t)
	var s := Ui.title(sub, 32, Palette.CREAM)
	s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(s, Vector2(x0 + 170, y + 66), Vector2(w - 480, 44))
	add_child(s)
	Ui.pop_in(t, 0.05, 0.7)
	# Süre hapı
	_timer_pill = QuiltCard.new()
	_timer_pill.fill = Palette.CARD
	_timer_pill.radius = 42
	_timer_pill.depth = 6
	Ui.place(_timer_pill, Vector2(x0 + (w - 250) / 2.0, y + 130), Vector2(250, 84))
	add_child(_timer_pill)
	if relaxed:
		_timer_icon = Ui.icon("ic_zen" if UiArt.tex("ic_zen") else "ic_heart", Vector2(70, 70))
	else:
		_timer_icon = Clock.new()
	Ui.place(_timer_icon, Vector2(14, 7), Vector2(70, 70))
	_timer_pill.add_child(_timer_icon)
	_timer_label = Ui.label("0:00", 46, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(_timer_label, Vector2(84, 0), Vector2(150, 84))
	_timer_pill.add_child(_timer_label)
	Ui.pop_in(_timer_pill, 0.15, 0.6)
	top_h = y + 130 + 84 + 24
	# Güç barı
	var bs := 150.0
	var gap := 70.0
	var by := vp.y - Ui.safe_bottom() - bs - 66.0
	bottom_h = vp.y - by + 10.0
	var bx := (vp.x - (bs * 3 + gap * 2)) / 2.0
	for i in KINDS.size():
		var k: String = KINDS[i]
		var b := PowerButton.new()
		b.skin = UiArt.tex("btn_square")
		b.icon = UiArt.tex(ICONS[k]) if UiArt.tex(ICONS[k]) else UiArt.tex("ic_hint")
		b.icon_scale = 0.62
		Ui.place(b, Vector2(bx + i * (bs + gap), by), Vector2(bs, bs))
		add_child(b)
		var nl := Ui.title(tr(NAMES[k]), 30, Palette.CREAM)
		Ui.place(nl, Vector2(-30, bs + 6), Vector2(bs + 60, 40))
		b.add_child(nl)
		b.tapped.connect(func() -> void: powerup.emit(k))
		b.denied.connect(func() -> void: powerup.emit(k))
		_btns[k] = b
		Ui.pop_in(b, 0.2 + i * 0.07, 0.4)

func set_time(sec: float, urgent: bool) -> void:
	_timer_label.text = Ui.fmt_time(ceilf(sec) if urgent or sec > 0 else sec)
	if urgent != _urgent:
		_urgent = urgent
		_timer_pill.fill = Palette.BAD.lightened(0.35) if urgent else Palette.CARD
		_timer_pill.queue_redraw()
		_timer_label.add_theme_color_override("font_color", Palette.CREAM if urgent else Palette.INK)

func _process(dt: float) -> void:
	if _urgent and _timer_pill and not Ui.reduce_motion():
		_pulse_t += dt
		var s := 1.0 + 0.06 * maxf(0.0, sin(_pulse_t * TAU))
		_timer_pill.scale = Vector2(s, s)

## Güç butonu durumu: label (örn "×3", "30", "∞", "FREE"), cost: "count" | "gem" | "ad" | "free" | "none".
func set_power(kind: String, label: String, cost: String, enabled: bool) -> void:
	var b: PowerButton = _btns.get(kind)
	if b == null:
		return
	b.disabled = not enabled
	b.set_cost(label, cost)

func set_chain(n: int) -> void:
	if _chain:
		_chain.queue_free()
		_chain = null
	if n < 2:
		return
	var c := Ui.badge(tr("chain.label") % n, Palette.MUSTARD.darkened(0.15))
	(c as Badge).fs = 28
	c.position = _timer_pill.position + Vector2(_timer_pill.size.x + 20, 18)
	add_child(c)
	_chain = c
	Ui.pop_in(c, 0.3, 0.3)

## Ekranın ortasında yaylanan yazı (övgü, kombo). Yukarı süzülüp söner.
func pop_text(text: String, at: Vector2, fs := 84, col := Palette.CREAM, hold := 0.7) -> void:
	var l := Ui.title(text, fs, col)
	l.size = Vector2(900, fs * 1.6)
	l.position = at - l.size / 2.0
	add_child(l)
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(0.3, 0.3)
	l.rotation = randf_range(-0.08, 0.08)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 90, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(l, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(l.queue_free)

## Girişte harcanan enerji: "-5" fincanı yukarı süzülür.
func float_energy(n: int) -> void:
	var box := Control.new()
	box.size = Vector2(240, 100)
	box.position = _timer_pill.position + Vector2(_timer_pill.size.x / 2.0 - 120, 100)
	add_child(box)
	var ic := Ui.icon("ic_energy", Vector2(90, 90))
	ic.position = Vector2(20, 5)
	box.add_child(ic)
	var l := Ui.title("-%d" % n, 56, Palette.CREAM)
	Ui.place(l, Vector2(110, 0), Vector2(120, 100))
	box.add_child(l)
	Ui.pop_in(box, 0.4, 0.4)
	var tw := box.create_tween()
	tw.tween_interval(1.1)
	tw.set_parallel()
	tw.tween_property(box, "position:y", box.position.y - 120, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(box, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(box.queue_free)

func power_center(kind: String) -> Vector2:
	var b: Control = _btns.get(kind)
	return b.global_position + b.size / 2.0 if b else Vector2.ZERO

## Kare yastık güç butonu + köşede maliyet çipi.
class PowerButton extends JuicyButton:
	var _chip: CostChip
	func set_cost(label: String, cost: String) -> void:
		if _chip == null:
			_chip = CostChip.new()
			add_child(_chip)
		_chip.text = label
		_chip.cost = cost
		_chip.visible = cost != "none"
		var w := maxf(70.0, Ui.FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x + (66.0 if cost in ["gem", "ad"] else 34.0))
		_chip.size = Vector2(w, 58)
		_chip.position = Vector2(size.x - w + 18, -18)
		_chip.queue_redraw()

class CostChip extends Control:
	var text := ""
	var cost := "count"
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var col: Color = {"count": Palette.SAGE, "gem": Palette.MUSTARD, "ad": Palette.TERRACOTTA, "free": Palette.SAGE}.get(cost, Palette.SAGE)
		var r := Rect2(Vector2.ZERO, size)
		draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 4), size), size.y / 2.0), col.darkened(0.35))
		draw_colored_polygon(Ui.rrect(r, size.y / 2.0), col)
		draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-6), size.y / 2.0 - 6), 7, 5), Color(Palette.STITCH, 0.7), 2.0)
		var x := 16.0
		if cost == "gem":
			var t := UiArt.tex("ic_gem")
			draw_texture_rect(t, Rect2(Vector2(8, 6), Vector2(44, 44)), false)
			x = 54.0
		elif cost == "ad":
			# Oynat üçgeni (video)
			var c := Vector2(30, size.y / 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -12), c + Vector2(13, 0), c + Vector2(-9, 12)]), Palette.CREAM)
			x = 50.0
		var fs := 32
		var ts := Ui.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var px := x + (size.x - x - 12 - ts.x) / 2.0
		draw_string(Ui.FONT, Vector2(px, size.y / 2.0 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)

## Dikişli kumaş saat (süre hapı ikonu; sanat gelene kadar).
class Clock extends Control:
	var _t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		var r := size.x * 0.42
		draw_circle(c + Vector2(0, 4), r, Palette.SHADOW)
		draw_circle(c, r, Palette.TERRACOTTA)
		draw_circle(c, r - 7, Palette.CREAM)
		draw_arc(c, r - 12, 0, TAU, 32, Color(Palette.STITCH_DARK, 0.5), 2.0, true)
		draw_line(c, c + Vector2.from_angle(_t * TAU / 60.0 - PI / 2) * (r - 14), Palette.INK, 4.0, true)
		draw_line(c, c + Vector2.from_angle(_t * TAU / 3600.0 - PI / 3) * (r - 22), Palette.INK, 5.0, true)
		draw_circle(c, 4, Palette.MUSTARD)
