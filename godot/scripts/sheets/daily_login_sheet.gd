extends Sheet
## 7 günlük giriş ödülü: 6 küçük yama + büyük 7. gün yaması. Bugün parlar; alınanlar dikişli ✓.
## Al → DailyReward.claim_week → bugünün yamasından ikonlar üst bara uçar. Reklamsız/premium bonusu.

var _patches := {}
var _btn: JuicyButton

func _init() -> void:
	panel_size = Vector2(-1, 1200)

func build() -> void:
	var w := pw()
	var y := banner_title(tr("dailyReward.title")) + 30
	var today := DailyReward.week_day()
	var can := DailyReward.can_claim_week()
	var prem := Purchases.ads_removed()
	var sub := Ui.label(tr("dailyReward.day") % today, 38, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(sub, Vector2(40, y - 8), Vector2(w - 80, 50))
	y += 70
	var gap := 20.0
	var pw4 := (w - 80 - gap * 3) / 4.0
	var ph := pw4 * 1.22
	for d in range(1, 8):
		var pos: Vector2
		var sz := Vector2(pw4, ph)
		if d <= 4:
			pos = Vector2(40 + (d - 1) * (pw4 + gap), y)
		elif d <= 6:
			pos = Vector2(40 + (d - 5) * (pw4 + gap), y + ph + gap)
		else:
			pos = Vector2(40 + 2 * (pw4 + gap), y + ph + gap)
			sz = Vector2(pw4 * 2 + gap, ph)
		var claimed := d < today or (d == today and not can)
		var is_today := d == today and can
		_patches[d] = _patch(d, pos, sz, DailyReward.week_reward(d, prem), claimed, is_today)
		Ui.pop_in(_patches[d], 0.08 + d * 0.05, 0.4)
	y += ph * 2 + gap + 50
	if prem:
		var pb := Ui.label("♛ " + tr("dailyReward.premium.bonus"), 32, Palette.MUSTARD.darkened(0.3), HORIZONTAL_ALIGNMENT_CENTER)
		add(pb, Vector2(40, y - 20), Vector2(w - 80, 46))
		y += 40
	_btn = Ui.button(tr("dailyReward.claim.cta") if can else tr("dailyReward.claim.disabled"), "terracotta" if can else "sage", Vector2(w - 160, 150), "", 50)
	_btn.disabled = not can
	add(_btn, Vector2(80, y))
	_btn.tapped.connect(_claim)
	panel.size.y = y + 200
	_place_panel()
	close_x()

func _patch(d: int, pos: Vector2, sz: Vector2, r: Dictionary, claimed: bool, today: bool) -> QuiltCard:
	var c := QuiltCard.new()
	c.fabric = [0, 1, 2, 3, 7, 10, 4][d - 1]
	c.inner = 10
	c.radius = 36
	c.glow = today
	c.locked = claimed
	add(c, pos, sz)
	var dl := Ui.label(tr("dailyReward.day") % d, 28, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(dl, Vector2(0, 14), Vector2(sz.x, 40))
	c.add_child(dl)
	var keys := r.keys()
	var n := keys.size()
	var isz := minf(sz.y * 0.42, (sz.x - 30) / maxf(1, n))
	for i in n:
		var cur: String = keys[i]
		var ic := Ui.icon(Ui.currency_icon(cur), Vector2(isz, isz))
		var x0 := (sz.x - n * isz) / 2.0 + i * isz
		Ui.place(ic, Vector2(x0, 56), Vector2(isz, isz))
		c.add_child(ic)
		var al := Ui.label("%d" % int(r[cur]), 30, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(al, Vector2(x0, 56 + isz - 6), Vector2(isz, 40))
		c.add_child(al)
	if claimed:
		var ck := Check.new()
		Ui.place(ck, Vector2(sz.x / 2.0 - 40, sz.y / 2.0 - 30), Vector2(80, 80))
		c.add_child(ck)
	return c

func _claim() -> void:
	var res := DailyReward.claim_week()
	if res.is_empty():
		return
	_btn.disabled = true
	_btn.text = tr("dailyReward.success.title")
	var p: QuiltCard = _patches[int(res.day)]
	Ui.punch(p, 0.25)
	p.glow = false
	p.locked = true
	var ck := Check.new()
	Ui.place(ck, Vector2(p.size.x / 2.0 - 40, p.size.y / 2.0 - 30), Vector2(80, 80))
	p.add_child(ck)
	Ui.pop_in(ck, 0.1, 0.2)
	var r: Dictionary = res.reward
	Fly.hold(r)
	Fly.rewards(p.global_position + p.size / 2.0, r)
	Sfx.play("reward", 1.0, -2.0)
	Juice.haptic("medium")
	Juice.add_trauma(0.2)
	get_tree().create_timer(1.6).timeout.connect(close)

## İşlenmiş onay işareti (yeşil dikiş).
class Check extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c + Vector2(0, 4), size.x / 2.0, Color(Palette.INK, 0.25))
		draw_circle(c, size.x / 2.0, Palette.SAGE)
		draw_arc(c, size.x / 2.0 - 6, 0, TAU, 32, Color(Palette.STITCH, 0.8), 2.5, true)
		var pts := PackedVector2Array([c + Vector2(-18, 0), c + Vector2(-5, 14), c + Vector2(20, -14)])
		draw_polyline(pts, Palette.CREAM, 9.0, true)
