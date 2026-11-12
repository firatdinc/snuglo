extends Sheet
## Premium paywall (Swift PremiumPaywallSheet): taç + başlık + 4 fayda + fiyatlı CTA + geri yükle.

func _init() -> void:
	panel_size = Vector2(-1, 1240)
	panel_fabric = 4

func build() -> void:
	panel.inner = 26
	var w := pw()
	var rays := Rays.new()
	Ui.place(rays, Vector2(w / 2.0 - 300, -300), Vector2(600, 600))
	panel.add_child(rays)
	var crown := Ui.icon("ic_crown", Vector2(260, 220))
	add(crown, Vector2((w - 260) / 2.0, -130))
	Ui.pop_in(crown, 0.1, 0.2, 0.6)
	Ui.bob(crown, 8.0, 2.0)
	close_x()
	var y := heading(tr("paywall.title"), 110, 66)
	y = body(tr("paywall.subtitle"), y, 38)
	y += 24
	var benefits := [["ic_energy", "paywall.benefit.energy"], ["ic_sound", "paywall.benefit.ads"],
		["ic_star", "paywall.benefit.cosmetics"], ["ic_lock", "paywall.benefit.levels"]]
	for i in benefits.size():
		var b: Array = benefits[i]
		var row := QuiltCard.new()
		row.fill = Palette.CREAM
		row.radius = 40
		row.depth = 6
		add(row, Vector2(60, y), Vector2(w - 120, 130))
		var ic := Ui.icon(b[0], Vector2(100, 100))
		Ui.place(ic, Vector2(20, 15), ic.size)
		row.add_child(ic)
		var l := Ui.wrap(Ui.label(tr(b[1]), 36, Palette.INK), w - 300)
		Ui.place(l, Vector2(140, 0), Vector2(w - 300, 130))
		row.add_child(l)
		var tick := Ui.label("✓", 52, Palette.SAGE.darkened(0.2), HORIZONTAL_ALIGNMENT_CENTER)
		Ui.place(tick, Vector2(w - 230, 0), Vector2(90, 130))
		row.add_child(tick)
		Ui.pop_in(row, 0.2 + i * 0.08, 0.6)
		y += 146
	y += 20
	var owned := Purchases.is_premium()
	var cta := Ui.button(tr("profile.premium.active") if owned else tr("paywall.cta") % Purchases.get_price(Purchases.PREMIUM), "terracotta", Vector2(w - 140, 160), "ic_crown", 46)
	cta.disabled = owned
	add(cta, Vector2(70, y))
	Ui.pop_in(cta, 0.55, 0.6)
	cta.tapped.connect(func() -> void:
		Ui.punch(cta, 0.1)
		Purchases.buy(Purchases.PREMIUM))
	y += 180
	var rs := Ui.button(tr("paywall.restore"), "sage", Vector2(w - 260, 104), "", 36)
	add(rs, Vector2(130, y))
	rs.tapped.connect(func() -> void: Purchases.restore())
	y += 130
	panel.size.y = y + 30
	_place_panel()
	panel.position.y += 60
	Events.purchase_completed.connect(_on_done)

func _on_done(id: String) -> void:
	if id == Purchases.PREMIUM and is_inside_tree():
		Sfx.play("reward")
		Juice.add_trauma(0.35)
		Main.toast(tr("profile.premium.active"), "ic_crown", Palette.MUSTARD)
		close()
