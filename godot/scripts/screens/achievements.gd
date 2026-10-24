extends Screen
## Başarımlar (Swift AchievementsView): üstte açılan sayısı + Liderlik butonu; kategoriye göre
## (levels / skill / streak) dikişli kartlar: rozet, başlık, açıklama, ilerleme çubuğu, ödül çipleri.

var _scroll: DragScroll
var _y := 0.0
var _cw := 0.0

func build() -> void:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("mushroom")
	bg.wash_top = 0.85
	bg.wash_bottom = 0.95
	bg.motes = 8
	bg.size = size
	add_child(bg)
	var top := header("achievements.title")
	_scroll = DragScroll.new()
	put(_scroll, Vector2(X0, top), Vector2(W, H - top))
	_cw = W - 80
	_y = 10.0
	var list := Achievements.all()
	_summary(list)
	for cat in ["levels", "skill", "streak"]:
		_section("achievement.category." + cat)
		var items := list.filter(func(a: Dictionary) -> bool: return a.cat == cat)
		# Açılanlar önce değil: sıradaki hedef üstte (açılmamış en yakın), sonra diğerleri doğal sırada.
		for a in items:
			_row(a)
	_scroll.set_length(_y + BOTTOM + 60)
	var ds := Dev.env("SNUG_SCROLL")
	if ds != "":
		_scroll.scroll_to(float(ds), false)

func _add(c: Control, pos: Vector2, sz: Vector2, parent: Control = null) -> Control:
	Ui.place(c, pos, sz)
	(parent if parent else _scroll.content).add_child(c)
	return c

func _summary(list: Array) -> void:
	var c := QuiltCard.new()
	c.fabric = 1
	c.inner = 14
	c.radius = 48
	_add(c, Vector2(40, _y), Vector2(_cw, 250))
	Ui.pop_in(c, 0.05, 0.8)
	var rays := Rays.new()
	_add(rays, Vector2(-40, -50), Vector2(340, 340), c)
	var ic := Ui.icon("ic_trophy", Vector2(190, 210))
	_add(ic, Vector2(40, 20), ic.size, c)
	Ui.bob(ic, 6.0, 2.4)
	var n := Achievements.unlocked_count()
	_add(Ui.label("%d / %d" % [n, list.size()], 72, Palette.INK), Vector2(260, 30), Vector2(_cw - 290, 90), c)
	var bar := Widgets.StitchBar.new()
	bar.col = Palette.MUSTARD
	bar.value = float(n) / float(maxi(1, list.size()))
	_add(bar, Vector2(264, 122), Vector2(_cw - 310, 34), c)
	var lb := Ui.button(tr("leaderboard.title"), "sage", Vector2(_cw - 310, 74), "ic_trophy", 32)
	_add(lb, Vector2(260, 162), lb.size, c)
	lb.tapped.connect(func() -> void: Main.push("leaderboard"))
	_y += 270

func _section(key: String) -> void:
	_y += 20
	_add(Ui.title(tr(key), 48, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT), Vector2(50, _y), Vector2(_cw, 62))
	_y += 74

func _row(a: Dictionary) -> void:
	var unlocked: bool = a.unlocked
	var h := 200.0
	var c := QuiltCard.new()
	c.fabric = 9 if unlocked else -1
	c.fill = Palette.CARD
	c.inner = 12.0 if unlocked else 0.0
	c.radius = 44
	c.locked = false
	_add(c, Vector2(40, _y), Vector2(_cw, h))
	Ui.pop_in(c, minf(_y / 6000.0, 0.35), 0.85)
	var ic := Ui.icon("ic_trophy", Vector2(130, 150))
	_add(ic, Vector2(26, 24), ic.size, c)
	if not unlocked:
		ic.modulate = Color(0.55, 0.5, 0.48, 0.55)
		var lk := Ui.icon("ic_lock", Vector2(56, 64))
		_add(lk, Vector2(98, 112), lk.size, c)
	var rw := _reward_width(a.reward)
	var tw := _cw - 190 - rw - 30
	var t := Ui.label(tr(String(a.title)), 40, Palette.INK if unlocked else Palette.INK_SOFT)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_add(t, Vector2(176, 24), Vector2(tw, 56), c)
	var d := Ui.wrap(Ui.label(tr(String(a.description)), 28, Palette.INK_SOFT), tw)
	d.max_lines_visible = 2
	_add(d, Vector2(176, 78), Vector2(tw, 70), c)
	if not unlocked and int(a.target) > 1:
		var bar := Widgets.StitchBar.new()
		bar.col = Palette.SAGE
		bar.value = float(a.current) / float(a.target)
		_add(bar, Vector2(176, 150), Vector2(tw - 130, 28), c)
		_add(Ui.label("%d/%d" % [int(a.current), int(a.target)], 26, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(176 + tw - 125, 140), Vector2(125, 46), c)
	elif unlocked:
		var ok := Ui.badge("✓", Palette.SAGE)
		ok.position = Vector2(_cw - 64, -14)
		c.add_child(ok)
	# Ödül çipleri (sağda dikey)
	var keys := (a.reward as Dictionary).keys()
	var ry := (h - keys.size() * 54) / 2.0
	for k in keys:
		var ic2 := Ui.icon(Ui.currency_icon(String(k)), Vector2(46, 46))
		_add(ic2, Vector2(_cw - rw - 24, ry + 4), ic2.size, c)
		if not unlocked:
			ic2.modulate.a = 0.6
		_add(Ui.label("%d" % int(a.reward[k]), 30, Palette.INK, HORIZONTAL_ALIGNMENT_LEFT), Vector2(_cw - rw + 28, ry), Vector2(rw - 40, 54), c)
		ry += 54
	_y += h + 18

func _reward_width(r: Dictionary) -> float:
	var mx := 0
	for k in r:
		mx = maxi(mx, str(int(r[k])).length())
	return 76.0 + mx * 18.0
