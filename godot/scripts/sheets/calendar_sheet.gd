extends Sheet
## 30 günlük giriş takvimi (Swift DailyCalendarView): 5 sütunlu yama ızgarası, artan ödül
## (coin; her 7. günde gem). Alınanlar soluk + tik, bugün altın nabız. Al → ödül hücreden uçar.

const COLS := 5

var _cells := {}     # gün → QuiltCard
var _claim: JuicyButton
var _fx: Fx

func _init() -> void:
	panel_size = Vector2(-1, 1400)

func build() -> void:
	var w := pw()
	var y := banner_title(tr("calendar.title"), minf(w - 120, 620.0))
	y = body(tr("calendar.subtitle"), y + 10, 30)
	y += 20
	var through := DailyReward.calendar_claimed_through()
	var can := DailyReward.can_claim_calendar()
	var today := DailyReward.calendar_day()
	var gap := 14.0
	var gx := 50.0
	var cell := (w - gx * 2 - gap * (COLS - 1)) / COLS
	var ch := minf(cell * 0.9, 150.0)
	for d in range(1, DailyReward.CALENDAR_LENGTH + 1):
		var i := d - 1
		var r := DailyReward.calendar_reward(d)
		var gem := int(r.get("gem", 0)) > 0
		var claimed := d <= through and not (can and d >= today)
		var is_today := can and d == today
		var c := QuiltCard.new()
		c.fabric = 5 if gem else -1
		c.fill = Palette.CARD
		c.radius = 26
		c.depth = 6
		c.glow = is_today
		c.locked = false
		Ui.place(c, Vector2(gx + (i % COLS) * (cell + gap), y + (i / COLS) * (ch + gap)), Vector2(cell, ch))
		panel.add_child(c)
		_cells[d] = c
		var dl := Ui.label(str(d), 24, Palette.INK_SOFT)
		Ui.place(dl, Vector2(14, 4), Vector2(60, 34))
		c.add_child(dl)
		var ic := Ui.icon("ic_gem" if gem else "coin", Vector2(ch * 0.42, ch * 0.42))
		Ui.place(ic, Vector2((cell - ch * 0.42) / 2.0, ch * 0.16), Vector2(ch * 0.42, ch * 0.42))
		c.add_child(ic)
		var amt := Ui.label("+%d" % (int(r.gem) if gem else int(r.coin)), 28, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(amt, Vector2(0, ch * 0.6), Vector2(cell, ch * 0.34))
		c.add_child(amt)
		if claimed:
			c.modulate = Color(1, 1, 1, 0.5)
			var ck := Ui.title("✓", 56, Palette.SAGE)
			Ui.place(ck, Vector2(0, 0), Vector2(cell, ch))
			c.add_child(ck)
		Ui.pop_in(c, 0.05 + i * 0.012, 0.5)
		if is_today:
			var bd := Ui.badge("!")
			bd.position = Vector2(cell - 40, -14)
			c.add_child(bd)
	var rows := int(ceil(DailyReward.CALENDAR_LENGTH / float(COLS)))
	y += rows * (ch + gap) + 20
	var bw := w - 160
	_claim = Ui.button(tr("calendar.claimDay") % today if can else tr("calendar.comeBack"), "terracotta" if can else "sage", Vector2(bw, 140))
	_claim.disabled = not can
	add(_claim, Vector2(80, y))
	_claim.tapped.connect(_on_claim)
	Ui.pop_in(_claim, 0.4, 0.6)
	y += 160
	panel.size.y = y + 40
	_place_panel()
	close_x()
	_fx = Fx.new()
	add_child(_fx)

func _on_claim() -> void:
	var res := DailyReward.claim_calendar()
	if res.is_empty():
		return
	_claim.disabled = true
	var d := int(res.day)
	var reward: Dictionary = res.reward
	var c: QuiltCard = _cells.get(d)
	var at := c.global_position + c.size / 2.0 if c else panel.global_position + panel.size / 2.0
	Fly.hold(reward)
	Fly.rewards(at, reward)
	if c:
		c.glow = false
		Ui.punch(c, 0.3)
		var ck := Ui.title("✓", 56, Palette.SAGE)
		Ui.place(ck, Vector2.ZERO, c.size)
		c.add_child(ck)
		Ui.pop_in(ck, 0.1, 2.0)
	var big := int(reward.get("gem", 0)) > 0
	_fx.confetti(at, 40 if not big else 90, PI * 0.8, -PI / 2, 1300.0 if not big else 1800.0)
	Sfx.play("reward", 1.0, -2.0, 0.0)
	Juice.haptic("medium")
	if big:
		Juice.add_trauma(0.3)
	get_tree().create_timer(1.4).timeout.connect(close)
