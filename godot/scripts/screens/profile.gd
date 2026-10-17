extends Screen
## Profil (Swift ProfileView): kimlik (maskot), XP kartı, premium kartı, hızlı bağlantılar
## (başarımlar, istatistik, liderlik, ayarlar), kozmetik özeti.

var _scroll: DragScroll
var _y := 0.0
var _cw := 0.0

func build() -> void:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("lake")
	bg.wash_top = 0.8
	bg.wash_bottom = 0.95
	bg.motes = 10
	bg.size = size
	add_child(bg)
	var top := header("profile.title", true)
	_scroll = DragScroll.new()
	put(_scroll, Vector2(X0, top), Vector2(W, H - top))
	_cw = W - 80
	_y = 10.0
	_identity()
	_xp()
	_premium()
	_links()
	_cosmetics()
	_scroll.set_length(_y + BOTTOM + 60)

func _add(c: Control, pos: Vector2, sz: Vector2, parent: Control = null) -> Control:
	Ui.place(c, pos, sz)
	(parent if parent else _scroll.content).add_child(c)
	return c

func _card(h: float, fabric := -1) -> QuiltCard:
	var c := QuiltCard.new()
	c.fabric = fabric
	c.fill = Palette.CARD
	c.inner = 14.0 if fabric >= 0 else 0.0
	c.radius = 48
	_add(c, Vector2(40, _y), Vector2(_cw, h))
	Ui.pop_in(c, minf(_y / 4000.0, 0.3), 0.85)
	return c

func _identity() -> void:
	var c := _card(300, 0)
	var m := Ui.icon("wave", Vector2(260, 280), "mascot")
	_add(m, Vector2(30, 10), m.size, c)
	Ui.bob(m, 6.0, 2.4)
	_add(Ui.label(tr("profile.identity.title"), 58, Palette.INK), Vector2(310, 40), Vector2(_cw - 340, 76), c)
	_add(Ui.label(tr("profile.subtitle"), 34, Palette.INK_SOFT), Vector2(310, 112), Vector2(_cw - 340, 50), c)
	var chips := [["ic_star", "%d" % Progress.total_completed()], ["ic_trophy", "%d" % Achievements.unlocked_count()], ["ic_heart", "%d" % Progress.play_streak]]
	for i in chips.size():
		var ch := QuiltCard.new()
		ch.fill = Palette.CREAM
		ch.radius = 34
		ch.depth = 5
		_add(ch, Vector2(310 + i * 196, 186), Vector2(180, 74), c)
		_add(Ui.icon(chips[i][0], Vector2(56, 56)), Vector2(10, 9), Vector2(56, 56), ch)
		_add(Ui.label(chips[i][1], 36, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER), Vector2(66, 0), Vector2(104, 74), ch)
	_y += 324

func _xp() -> void:
	var c := _card(230, 2)
	var ring := Widgets.XpRing.new()
	ring.level = XP.level
	ring.frac = XP.fraction
	_add(ring, Vector2(36, 34), Vector2(160, 160), c)
	_add(Ui.label(tr("level.label") % XP.level, 50, Palette.INK), Vector2(230, 34), Vector2(_cw - 260, 66), c)
	var bar := Widgets.StitchBar.new()
	bar.col = Palette.MUSTARD
	bar.value = XP.fraction
	_add(bar, Vector2(232, 112), Vector2(_cw - 290, 40), c)
	_add(Ui.label("%d / %d XP" % [XP.into_level, XP.for_next], 30, Palette.INK_SOFT), Vector2(232, 156), Vector2(_cw - 290, 44), c)
	_y += 254

func _premium() -> void:
	var c := _card(220, 4)
	c.pressable = not Purchases.is_premium()
	c.mouse_filter = Control.MOUSE_FILTER_STOP if c.pressable else Control.MOUSE_FILTER_IGNORE
	c.glow = c.pressable
	var cr := Ui.icon("ic_crown", Vector2(160, 140))
	_add(cr, Vector2(36, 40), cr.size, c)
	Ui.bob(cr, 5.0, 2.0)
	if Purchases.is_premium():
		_add(Ui.label(tr("profile.premium.active"), 48, Palette.INK), Vector2(230, 0), Vector2(_cw - 260, 220), c)
	else:
		_add(Ui.label(tr("profile.premium.upgrade.title"), 46, Palette.INK), Vector2(230, 36), Vector2(_cw - 260, 64), c)
		_add(Ui.label(tr("profile.premium.upgrade.subtitle"), 30, Palette.INK_SOFT), Vector2(230, 100), Vector2(_cw - 260, 46), c)
		var b := Ui.button(tr("common.upgrade"), "mustard", Vector2(260, 70), "", 32)
		_add(b, Vector2(230, 140), b.size, c)
		b.tapped.connect(func() -> void: Main.open("premium"))
		c.tapped.connect(func() -> void: Main.open("premium"))
	_y += 244

func _links() -> void:
	var items := [["ic_trophy", "profile.link.achievements", func() -> void: Main.push("achievements")],
		["ic_stats", "profile.link.stats", func() -> void: Main.push("stats")],
		["ic_star", "profile.link.bestScores", func() -> void:
			if GameCenter.is_supported():
				GameCenter.show_leaderboards()
			else:
				Main.toast(tr("leaderboard.notSignedIn.title"), "ic_trophy", Palette.TERRACOTTA)],
		["ic_settings", "profile.settings.title", func() -> void: Main.push("settings")]]
	var w := (_cw - 24) / 2.0
	for i in items.size():
		var it: Array = items[i]
		var c := QuiltCard.new()
		c.pressable = true
		c.fabric = [1, 3, 5, 8][i]
		c.inner = 12
		c.radius = 44
		_add(c, Vector2(40 + (i % 2) * (w + 24), _y), Vector2(w, 220))
		Ui.pop_in(c, 0.2 + i * 0.05, 0.7)
		_add(Ui.icon(it[0], Vector2(110, 110)), Vector2((w - 110) / 2.0, 24), Vector2(110, 110), c)
		var l := Ui.label(tr(it[1]), 34, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_add(l, Vector2(20, 140), Vector2(w - 40, 56), c)
		c.tapped.connect(it[2])
		if i % 2 == 1:
			_y += 244

func _cosmetics() -> void:
	_y += 10
	var c := _card(220)
	_add(Ui.label(tr("fabric.title"), 36, Palette.INK_SOFT), Vector2(40, 22), Vector2(_cw - 80, 50), c)
	var fid := Cosmetics.selected_fabric
	_add(Ui.label(tr("fabric." + fid), 48, Palette.INK), Vector2(40, 70), Vector2(_cw * 0.5, 64), c)
	_add(Ui.label("%s: %s" % [tr("board.title"), tr("board." + Cosmetics.selected_board)], 30, Palette.INK_SOFT), Vector2(40, 140), Vector2(_cw - 80, 50), c)
	for i in 4:
		var p := QuiltCard.new()
		p.fabric = (Cosmetics.FABRICS.map(func(f: Dictionary) -> String: return f.id).find(fid) * 3 + i * 4) % 12
		p.radius = 22
		p.depth = 5
		p.rotation = (i - 1.5) * 0.08
		_add(p, Vector2(_cw - 420 + i * 92, 40), Vector2(100, 100), c)
	var edit := Ui.button(tr("settings.title"), "sage", Vector2(320, 70), "ic_settings", 30)
	_add(edit, Vector2(_cw - 360, 140), edit.size, c)
	edit.tapped.connect(func() -> void: Main.push("settings"))
	_y += 240
