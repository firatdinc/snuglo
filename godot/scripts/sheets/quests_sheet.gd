extends Sheet
## Günlük görevler (3) + haftalık meydan okuma. Her satır: ikon, metin, dikişli çubuk, ödül,
## Al / Alındı / ilerleme. Al → Quests.claim → ikonlar üst bara uçar, satır "damga" ile kapanır.

var _rows: Control

func _init() -> void:
	style = "bottom"
	panel_size = Vector2(-1, 1300)

func build() -> void:
	var w := pw()
	var y := banner_title(tr("quest.header"), 780) + 30
	var cd := Ui.label(tr("menu.refresh") % Ui.fmt_time(_to_midnight()), 30, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(cd, Vector2(40, y - 8), Vector2(w - 80, 44))
	_rows = Control.new()
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add(_rows, Vector2(0, y + 50), Vector2(w, 1000))
	var h := _fill(true)
	panel.size.y = y + 50 + h + 70
	_place_panel()
	close_x()

func _to_midnight() -> int:
	var d: Dictionary = Time.get_datetime_dict_from_system()
	return 86400 - (int(d.hour) * 3600 + int(d.minute) * 60 + int(d.second))

func _fill(animate := false) -> float:
	for c in _rows.get_children():
		c.queue_free()
	var w := pw()
	var y := 0.0
	var qs := Quests.today()
	var icons := {"solve_levels": "ic_star", "solve_under": "ic_energy", "no_hint": "ic_hint", "perfect": "ic_trophy"}
	for q: Dictionary in qs:
		var row := _row(y, String(icons.get(q.kind, "ic_star")), tr(String(q.text)) % int(q.arg), int(q.progress), int(q.goal),
			q.reward, bool(q.complete), bool(q.claimed), func(at: Vector2) -> void:
				var r := Quests.claim(int(q.id))
				_after_claim(r, at))
		if animate:
			Ui.slide_in(row, 0.1 + y / 2000.0, 60)
		y += 196
	# Haftalık
	y += 20
	var head := Ui.label(tr("weekly.title"), 46, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(head, Vector2(40, y), Vector2(w - 80, 64))
	_rows.add_child(head)
	y += 76
	var wk := Quests.weekly()
	var wr := _row(y, "ic_calendar", tr(String(wk.text)) % int(wk.arg), int(wk.progress), int(wk.goal), wk.reward,
		bool(wk.complete), bool(wk.claimed), func(at: Vector2) -> void:
			var r := Quests.claim_weekly()
			_after_claim(r, at), true)
	if animate:
		Ui.slide_in(wr, 0.35, 60)
	y += 196
	return y

func _row(y: float, icon: String, text: String, prog: int, goal: int, reward: Dictionary, complete: bool, claimed: bool, on_claim: Callable, weekly := false) -> Control:
	var w := pw()
	var card := QuiltCard.new()
	card.fabric = 9 if weekly else -1
	card.fill = Palette.CREAM
	card.inner = 10 if weekly else 0.0
	card.radius = 40
	card.depth = 8
	card.glow = complete and not claimed
	if claimed:
		card.modulate = Color(1, 1, 1, 0.65)
	Ui.place(card, Vector2(40, y), Vector2(w - 80, 176))
	_rows.add_child(card)
	var cw := w - 80
	var ic := Ui.icon(icon, Vector2(100, 100))
	Ui.place(ic, Vector2(24, 38), Vector2(100, 100))
	card.add_child(ic)
	var t := Ui.label(text, 34, Palette.INK)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(t, Vector2(140, 22), Vector2(cw - 140 - 230, 56))
	card.add_child(t)
	var bar := Widgets.StitchBar.new()
	bar.value = float(prog) / maxf(1.0, goal)
	bar.col = Palette.SAGE if not complete else Palette.MUSTARD
	Ui.place(bar, Vector2(140, 92), Vector2(cw - 140 - 330, 30))
	card.add_child(bar)
	var pl := Ui.label("%d/%d" % [mini(prog, goal), goal], 28, Palette.INK_SOFT)
	Ui.place(pl, Vector2(cw - 180, 82), Vector2(80, 50))
	pl.position.x = 140 + (cw - 140 - 330) + 14
	card.add_child(pl)
	# Ödül çipi
	var rx := cw - 210
	var ri := 0
	for c in reward:
		if int(reward[c]) <= 0:
			continue
		var ri_ic := Ui.icon(Ui.currency_icon(String(c)), Vector2(46, 46))
		Ui.place(ri_ic, Vector2(140 + ri * 130, 128), Vector2(46, 46))
		var rl := Ui.label("+%d" % int(reward[c]), 28, Palette.INK)
		Ui.place(rl, Vector2(190 + ri * 130, 124), Vector2(80, 50))
		card.add_child(ri_ic)
		card.add_child(rl)
		ri += 1
	if claimed:
		var done := Ui.label("✓ " + tr("quest.claimed"), 32, Palette.SAGE.darkened(0.3), HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(done, Vector2(rx, 50), Vector2(190, 76))
		card.add_child(done)
	elif complete:
		var b := Ui.button(tr("quest.claim"), "mustard", Vector2(190, 100), "", 36)
		Ui.place(b, Vector2(rx, 38), Vector2(190, 100))
		card.add_child(b)
		b.tapped.connect(func() -> void:
			b.disabled = true
			on_claim.call(b.global_position + b.size / 2.0))
	return card

func _after_claim(r: Dictionary, at: Vector2) -> void:
	if r.is_empty():
		return
	Fly.hold(r)
	Fly.rewards(at, r)
	Sfx.play("reward", 1.1, -4.0)
	Juice.haptic("medium")
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if is_instance_valid(self):
			_fill())
