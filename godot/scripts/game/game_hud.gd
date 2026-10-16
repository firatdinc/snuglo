class_name GameHud
extends CanvasLayer
## Oyun üst barı (başlık, süre, ipucu, geri al) + kazanma paneli.

var game: Game
var _title: Label
var _timer: Label
var _font: Font = preload("res://art/fonts/fredoka_bold.tres")
var _win: Control

func setup(g: Game) -> void:
	game = g
	var vp := g.get_viewport_rect().size
	var top := 90.0
	_title = _label(_pretty(g.lvl.id), 54, Palette.INK)
	_title.position = Vector2(0, top)
	_title.size = Vector2(vp.x, 70)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_timer = _label("0:00", 40, Palette.INK_SOFT)
	_timer.position = Vector2(0, top + 66)
	_timer.size = Vector2(vp.x, 50)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_timer)

	var undo := _button("↶", Palette.piece(3), Vector2(vp.x - 300, top - 4), Vector2(120, 120))
	undo.tapped.connect(g.undo)
	var hint := _button("?", Palette.piece(1), Vector2(vp.x - 160, top - 4), Vector2(120, 120))
	hint.tapped.connect(g.hint)
	var back := _button("‹", Palette.piece(0), Vector2(40, top - 4), Vector2(120, 120))
	back.tapped.connect(g.restart)

func _pretty(id: String) -> String:
	var cut := id.rfind("-")
	return "Level %s" % id.substr(cut + 1)

func _process(_dt: float) -> void:
	if game and not game.done:
		var s := int(game.elapsed)
		_timer.text = "%d:%02d" % [s / 60, s % 60]

func pulse_progress() -> void:
	_timer.pivot_offset = _timer.size / 2.0
	var tw := create_tween()
	tw.tween_property(_timer, "scale", Vector2(1.15, 1.15), 0.08)
	tw.tween_property(_timer, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _label(t: String, fs: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", c)
	return l

func _button(t: String, c: Color, pos: Vector2, sz: Vector2) -> JuicyButton:
	var b := JuicyButton.new()
	b.text = t
	b.color = c
	b.font_size = 64
	b.position = pos
	b.size = sz
	add_child(b)
	return b

## Kazanma paneli: karartma, panel yaylanarak gelir, yıldızlar tek tek "damga" gibi iner.
func show_win(stars: int, secs: float) -> void:
	var vp := game.get_viewport_rect().size
	_win = Control.new()
	_win.size = vp
	add_child(_win)
	var dim := ColorRect.new()
	dim.color = Color(Palette.INK, 0.0)
	dim.size = vp
	_win.add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.35, 0.3)

	var panel := WinPanel.new()
	panel.size = Vector2(vp.x - 160, 760)
	panel.position = Vector2(80, vp.y * 0.5 - 380)
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.4, 0.4)
	panel.modulate.a = 0.0
	_win.add_child(panel)
	var tw := create_tween().set_parallel()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.15)

	var head := _label("Snug!", 120, Palette.INK)
	head.size = Vector2(panel.size.x, 140)
	head.position = Vector2(0, 40)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(head)
	var s := int(secs)
	var t := _label("%d:%02d" % [s / 60, s % 60], 48, Palette.INK_SOFT)
	t.size = Vector2(panel.size.x, 60)
	t.position = Vector2(0, 430)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(t)

	for i in 3:
		var star := StarBadge.new()
		star.filled = i < stars
		star.size = Vector2(170, 170)
		star.position = Vector2(panel.size.x / 2.0 - 85 + (i - 1) * 200, 210 - (30 if i == 1 else 0))
		star.pivot_offset = star.size / 2.0
		star.scale = Vector2.ZERO
		panel.add_child(star)
		var delay := 0.45 + i * 0.22
		var st := create_tween()
		st.tween_interval(delay)
		st.tween_property(star, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		st.tween_callback(func():
			if star.filled:
				Sfx.note(4 + i * 2, "levelUp", -4.0)
				Juice.add_trauma(0.25)
				Juice.haptic("medium")
				game.fx.sparks(panel.position + star.position + star.size / 2.0, 16, Palette.GOLD, 700.0)
			else:
				Sfx.play("click", 0.7, -6.0))
		st.tween_property(star, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var next := JuicyButton.new()
	next.text = "Next"
	next.color = Palette.GOOD
	next.font_size = 60
	next.size = Vector2(panel.size.x - 160, 150)
	next.position = Vector2(80, 540)
	panel.add_child(next)
	next.tapped.connect(func(): Main.next_level())
