extends Screen
## Oyun içi liderlik (Game Center skorları kendi arayüzümüzde): üstte 4 pano sekmesi
## (toplam bölüm / en hızlı / en iyi seri / endless), Global–Arkadaşlar anahtarı, kendi sıran
## kartı, ilk 100 satır (+ "İlk 200'ü göster" ile 101–200). Giriş yoksa Game Center kartı; altta Apple panosunu açma butonu.

const BOARDS := [
	[GameCenter.TOTAL_LEVELS, "leaderboard.board.totalLevels", "ic_star"],
	[GameCenter.FASTEST_SOLVE, "leaderboard.board.fastestSolve", "ic_energy"],
	[GameCenter.BEST_STREAK, "leaderboard.board.bestStreak", "ic_calendar"],
	[GameCenter.ENDLESS_BEST, "leaderboard.board.endless", "ic_endless"],
]

var _scroll: DragScroll
var _tabs: Array[JuicyButton] = []
var _scope_btns: Array[JuicyButton] = []
var _board := 0
var _friends := false
var _cw := 0.0
var _y := 0.0
var _req := 0   # geç gelen eski cevapları yok saymak için
var _more: JuicyButton

func build() -> void:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("mushroom")
	bg.wash_top = 0.85
	bg.wash_bottom = 0.95
	bg.motes = 8
	bg.size = size
	add_child(bg)
	var top := header("leaderboard.title")
	_cw = W - 80
	# Pano sekmeleri (2×2)
	var tw := (_cw - 20) / 2.0
	for i in BOARDS.size():
		var b := Ui.button(tr(BOARDS[i][1]), "sage", Vector2(tw, 96), BOARDS[i][2], 30)
		put(b, Vector2(X0 + 40 + (i % 2) * (tw + 20), top + (i / 2) * 110), b.size)
		b.tapped.connect(_pick.bind(i))
		Ui.pop_in(b, 0.05 + i * 0.04, 0.8)
		_tabs.append(b)
	top += 230
	# Global / Arkadaşlar
	var sw := (_cw - 20) / 2.0
	for i in 2:
		var s := Ui.button(tr("leaderboard.scope." + ["global", "friends"][i]), "mustard", Vector2(sw, 76), "", 28)
		put(s, Vector2(X0 + 40 + i * (sw + 20), top), s.size)
		s.tapped.connect(_scope.bind(i == 1))
		_scope_btns.append(s)
	top += 96
	_scroll = DragScroll.new()
	put(_scroll, Vector2(X0, top), Vector2(W, H - top - BOTTOM - 130))
	var gcb := Ui.button(tr("leaderboard.openGC"), "terracotta", Vector2(minf(_cw, 640), 110), "ic_trophy", 32)
	put(gcb, Vector2(X0 + (W - gcb.size.x) / 2.0, H - BOTTOM - 120), gcb.size)
	gcb.tapped.connect(func() -> void:
		if GameCenter.authed:
			GameCenter.show_leaderboards(BOARDS[_board][0])
		else:
			GameCenter.sign_in())
	GameCenter.auth_changed.connect(_reload)
	_reload()

func _pick(i: int) -> void:
	if i == _board:
		return
	_board = i
	_reload()

func _scope(friends: bool) -> void:
	if friends == _friends:
		return
	_friends = friends
	_reload()

## Seçili sekme terracotta, seçili kapsam hardal; diğerleri adaçayı.
func _style() -> void:
	for i in _tabs.size():
		_skin(_tabs[i], "terracotta" if i == _board else "sage")
	for i in _scope_btns.size():
		_skin(_scope_btns[i], "mustard" if (i == 1) == _friends else "sage")

func _skin(b: JuicyButton, name: String) -> void:
	b.skin = UiArt.tex("btn_" + name)
	b.color = {"terracotta": Palette.TERRACOTTA, "sage": Palette.SAGE, "mustard": Palette.MUSTARD}[name]
	b.queue_redraw()

func _clear() -> void:
	for c in _scroll.content.get_children():
		c.queue_free()
	_y = 10.0

func _add(c: Control, pos: Vector2, sz: Vector2, parent: Control = null) -> Control:
	Ui.place(c, pos, sz)
	(parent if parent else _scroll.content).add_child(c)
	return c

func _reload() -> void:
	_style()
	_clear()
	if not GameCenter.authed and GameCenter.is_supported():
		_message("leaderboard.notSignedIn.title", "leaderboard.notSignedIn.body", "leaderboard.signIn",
			func() -> void: GameCenter.sign_in())
		return
	_add(Ui.label("…", 48, Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(40, 60), Vector2(_cw, 80))
	_req += 1
	var req := _req
	GameCenter.load_board(BOARDS[_board][0], _friends, func(rows: Array, me: Dictionary, err: String) -> void:
		if req != _req or not is_inside_tree():
			return
		_show(rows, me, err))

func _show(rows: Array, me: Dictionary, err: String) -> void:
	_clear()
	if err == "auth":
		_message("leaderboard.notSignedIn.title", "leaderboard.notSignedIn.body", "leaderboard.signIn",
			func() -> void: GameCenter.sign_in())
		return
	if err != "":
		_message("leaderboard.error.title", "leaderboard.error.body", "common.retry", _reload)
		return
	if not me.is_empty():
		_me_card(me)
	if rows.is_empty():
		_message("leaderboard.empty.title", "leaderboard.empty.body")
		return
	for r in rows:
		_row(r)
	if rows.size() >= GameCenter.PAGE:
		_more_button()
	_scroll.set_length(_y + 40)

## İlk 100 doluysa listenin sonunda 101–200'ü getiren buton.
func _more_button() -> void:
	_more = Ui.button(tr("leaderboard.showTop200"), "mustard", Vector2(minf(_cw, 620), 100), "", 32)
	_add(_more, Vector2(40 + (_cw - _more.size.x) / 2.0, _y + 10), _more.size)
	_more.tapped.connect(_load_more)
	_y += 130

func _load_more() -> void:
	_more.disabled = true
	var req := _req
	GameCenter.load_board(BOARDS[_board][0], _friends, func(rows: Array, _me: Dictionary, err: String) -> void:
		if req != _req or not is_inside_tree():
			return
		if err != "":
			_more.disabled = false
			Main.toast(tr("leaderboard.error.title"), "ic_trophy", Palette.TERRACOTTA)
			return
		_y -= 130
		_more.queue_free()
		for r in rows:
			_row(r)
		_scroll.set_length(_y + 40), GameCenter.PAGE + 1)

func _me_card(me: Dictionary) -> void:
	var c := QuiltCard.new()
	c.fabric = 1
	c.inner = 12
	c.radius = 44
	c.glow = true
	_add(c, Vector2(40, _y), Vector2(_cw, 170))
	Ui.pop_in(c, 0.0, 0.85)
	var ic := Ui.icon("ic_trophy", Vector2(110, 124))
	_add(ic, Vector2(30, 23), ic.size, c)
	Ui.bob(ic, 5.0, 2.4)
	_add(Ui.label(tr("leaderboard.you"), 32, Palette.INK_SOFT), Vector2(170, 26), Vector2(_cw - 200, 46), c)
	_add(Ui.label("#%d" % int(me.rank), 64, Palette.INK), Vector2(170, 66), Vector2(260, 80), c)
	_add(Ui.label(String(me.score), 52, Palette.INK, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(_cw - 330, 56), Vector2(290, 80), c)
	_y += 190

func _row(r: Dictionary) -> void:
	var mine: bool = r.me
	var rank := int(r.rank)
	var c := QuiltCard.new()
	c.fabric = 9 if mine else -1
	c.fill = Palette.CARD
	c.inner = 10.0 if mine else 0.0
	c.radius = 36
	_add(c, Vector2(40, _y), Vector2(_cw, 112))
	Ui.pop_in(c, minf(_y / 5000.0, 0.3), 0.9)
	if rank <= 3:
		var medal := Ui.icon("ic_trophy", Vector2(64, 72))
		medal.modulate = [Palette.MUSTARD, Color(0.82, 0.84, 0.88), Color(0.85, 0.58, 0.38)][rank - 1]
		_add(medal, Vector2(26, 20), medal.size, c)
	else:
		_add(Ui.label("%d" % rank, 38, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(16, 0), Vector2(84, 112), c)
	var nm := Ui.label(String(r.name), 38, Palette.INK)
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_add(nm, Vector2(120, 0), Vector2(_cw - 420, 112), c)
	_add(Ui.label(String(r.score), 38, Palette.INK, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(_cw - 290, 0), Vector2(260, 112), c)
	_y += 126

func _message(title_key: String, body_key: String, cta_key := "", cta := Callable()) -> void:
	var h := 300.0 if cta_key != "" else 220.0
	var c := QuiltCard.new()
	c.fill = Palette.CARD
	c.radius = 44
	_add(c, Vector2(40, _y + 20), Vector2(_cw, h))
	Ui.pop_in(c, 0.0, 0.85)
	_add(Ui.label(tr(title_key), 44, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER), Vector2(30, 24), Vector2(_cw - 60, 60), c)
	var b := Ui.wrap(Ui.label(tr(body_key), 30, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER), _cw - 80)
	_add(b, Vector2(40, 90), Vector2(_cw - 80, 100), c)
	if cta_key != "":
		var btn := Ui.button(tr(cta_key), "sage", Vector2(minf(_cw - 120, 460), 86), "", 32)
		_add(btn, Vector2((_cw - btn.size.x) / 2.0, h - 110), btn.size, c)
		btn.tapped.connect(cta)
	_y += h + 40
	_scroll.set_length(_y)
