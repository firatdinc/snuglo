extends Screen
## Mağaza (Swift ShopView): sahip olunanlar şeridi, Günün Fırsatı, Premium afişi, gem paketleri
## (yüksük), reklamla ücretsiz ödüller, takas (coin→gem, gem→bilet), ipucu/anahtar/reklam kaldır,
## satın alımları geri yükle, debug. Satın alma sonucu Events.purchase_* → balon + yüksük uçuşu.

var _scroll: DragScroll
var _owned := {}            # c → Label
var _y := 0.0
var _cw := 0.0
var _x := 40.0
var _ex := {}               # "coin_gem" → {n, label, btn, max}
var _iap_rows := {}         # product id → JuicyButton
var _last_tap := Vector2.ZERO

func build() -> void:
	add_child(_backdrop())
	var top := header("shop.title", true)
	_scroll = DragScroll.new()
	put(_scroll, Vector2(X0, top), Vector2(W, H - top))
	_cw = W - 80
	_y = 10.0
	_owned_strip()
	_deal()
	_premium()
	_gems()
	_free()
	_exchange()
	_bundles()
	_restore()
	if OS.is_debug_build():
		_debug()
	_scroll.set_length(_y + BOTTOM + 60)
	Events.purchase_completed.connect(_on_bought)
	Events.purchase_failed.connect(func(_id: String) -> void: Main.toast(tr("toast.purchase.failed"), "ic_lock", Palette.TERRACOTTA))
	Events.wallet_changed.connect(func(_c: String, _a: int, _d: int) -> void: _refresh())
	Purchases.entitlements_changed.connect(_refresh)
	var ds := Dev.env("SNUG_SCROLL")
	if ds != "":
		_scroll.scroll_to(float(ds), false)

func _backdrop() -> Control:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("beach")
	bg.wash_top = 0.85
	bg.wash_bottom = 0.95
	bg.motes = 10
	bg.size = size
	return bg

func c_add(c: Control, pos: Vector2, sz := Vector2(-1, -1)) -> Control:
	if sz.x >= 0:
		c.size = sz
	c.position = pos
	_scroll.content.add_child(c)
	return c

func _section(key: String, hint_key := "") -> void:
	_y += 24
	var l := Ui.title(tr(key), 50, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	c_add(l, Vector2(_x + 10, _y), Vector2(_cw, 64))
	_y += 64
	if hint_key != "":
		var h := Ui.title(tr(hint_key), 30, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
		c_add(h, Vector2(_x + 12, _y), Vector2(_cw, 40))
		_y += 44
	_y += 10

func _card(fabric: int, h: float, inner := 14.0, x := -1.0, w := -1.0) -> QuiltCard:
	var c := QuiltCard.new()
	c.fabric = fabric
	c.inner = inner
	c.radius = 44
	c_add(c, Vector2(_x if x < 0 else x, _y), Vector2(_cw if w < 0 else w, h))
	Ui.pop_in(c, 0.05 + minf(_y / 4000.0, 0.4), 0.85)
	return c

func _lbl(parent: Control, text: String, fs: int, pos: Vector2, sz: Vector2, col := Palette.INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Ui.label(text, fs, col, align)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(l, pos, sz)
	parent.add_child(l)
	return l

func _icon(parent: Control, name: String, pos: Vector2, s: float) -> TextureRect:
	var ic := Ui.icon(name, Vector2(s, s))
	ic.position = pos
	parent.add_child(ic)
	return ic

# ------------------------------------------------------------------ Bölümler

func _owned_strip() -> void:
	var items := ["ticket", "key", "hint"]
	var w := (_cw - 40) / 3.0
	for i in items.size():
		var c: String = items[i]
		var chip := QuiltCard.new()
		chip.fill = Palette.CARD
		chip.radius = 40
		chip.depth = 6
		c_add(chip, Vector2(_x + i * (w + 20), _y), Vector2(w, 90))
		_icon(chip, Ui.currency_icon(c), Vector2(14, 5), 80)
		_owned[c] = _lbl(chip, str(Wallet.balance(c)), 42, Vector2(100, 0), Vector2(w - 120, 90), Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.pop_in(chip, 0.05 + i * 0.05, 0.6)
	_y += 110

func _deal() -> void:
	_section("shop.deal.section")
	var d := Wallet.daily_deal()
	var c := _card(1, 310)
	var rays := Rays.new()
	Ui.place(rays, Vector2(-30, -40), Vector2(330, 330))
	rays.alpha = 0.25
	c.add_child(rays)
	var ic := _icon(c, Ui.currency_icon(String(d.earn)), Vector2(40, 50), 190)
	Ui.bob(ic, 6.0, 2.2)
	var amt := Ui.title("+%d" % int(d.amount), 56)
	Ui.place(amt, Vector2(30, 200), Vector2(210, 70))
	c.add_child(amt)
	_lbl(c, tr(String(d.title)), 46, Vector2(270, 34), Vector2(_cw - 300, 60))
	var m := Ui.wrap(Ui.label(tr(String(d.message)), 30, Palette.INK_SOFT), _cw - 310)
	Ui.place(m, Vector2(270, 94), Vector2(_cw - 310, 80))
	c.add_child(m)
	var btn: JuicyButton
	if Wallet.deal_claimed():
		btn = Ui.button(tr("shop.deal.claimed"), "sage", Vector2(_cw - 310, 100), "", 40)
		btn.disabled = true
	elif d.kind == "ad":
		btn = Ui.button(tr("shop.pack.watch.ad"), "sage", Vector2(_cw - 310, 100), "ic_star", 40)
		btn.tapped.connect(func() -> void:
			if Wallet.deal_claimed():
				return
			if not Ads.rewarded_ready():
				Main.toast(tr("shop.claim.adNotReady"), "ic_sound", Palette.TERRACOTTA)
				Ui.shake(btn)
				return
			Ads.show_rewarded(func() -> void:
				if Wallet.claim_ad_deal(d):
					_celebrate(btn, String(d.earn), int(d.amount))
				_mark_deal_done(btn)))
	else:
		btn = Ui.button("%d" % int(d.cost), "mustard", Vector2(_cw - 310, 100), Ui.currency_icon(String(d.from)), 44)
		btn.tapped.connect(func() -> void:
			if Wallet.deal_claimed():
				return
			if Wallet.redeem_deal(d):
				_celebrate(btn, String(d.earn), int(d.amount))
				_mark_deal_done(btn)
			else:
				Main.toast(tr("shop.claim.insufficient"), Ui.currency_icon(String(d.from)), Palette.TERRACOTTA)
				Ui.shake(btn))
		btn.set_meta("cost", [String(d.from), int(d.cost)])
		btn.denied.connect(func() -> void:
			Main.toast(tr("shop.claim.insufficient"), Ui.currency_icon(String(d.from)), Palette.TERRACOTTA)
			Ui.shake(btn))
	Ui.place(btn, Vector2(270, 172), btn.size)
	c.add_child(btn)
	_iap_rows["deal"] = btn
	_y += 330

## Fırsat alındı: buton "Alındı" olur ve kapanır (yarına kadar).
func _mark_deal_done(btn: JuicyButton) -> void:
	btn.remove_meta("cost")
	btn.icon = null
	btn.text = tr("shop.deal.claimed")
	btn.disabled = true

func _premium() -> void:
	_y += 20
	var c := _card(4, 280)
	c.glow = not Purchases.is_premium()
	c.pressable = true
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	var crown := _icon(c, "ic_crown", Vector2(36, 56), 160)
	Ui.bob(crown, 6.0, 2.0)
	_lbl(c, tr("paywall.title"), 50, Vector2(220, 36), Vector2(_cw - 250, 64))
	_lbl(c, tr("paywall.subtitle"), 32, Vector2(220, 98), Vector2(_cw - 250, 44), Palette.INK_SOFT)
	var b: JuicyButton
	if Purchases.is_premium():
		b = Ui.button(tr("shop.owned"), "sage", Vector2(_cw - 280, 96), "", 36)
		b.disabled = true
	else:
		b = Ui.button(Purchases.get_price(Purchases.PREMIUM), "mustard", Vector2(_cw - 280, 96), "", 42)
		b.tapped.connect(func() -> void: Main.open("premium"))
	Ui.place(b, Vector2(220, 154), b.size)
	c.add_child(b)
	c.tapped.connect(func() -> void:
		if not Purchases.is_premium():
			Main.open("premium"))
	_y += 300

func _gems() -> void:
	_section("shop.gems.section", "shop.gems.hint")
	var w := (_cw - 24) / 2.0
	var h := 330.0
	var packs: Array = Purchases.GEM_PACKS
	for i in packs.size():
		var p: Dictionary = packs[i]
		var col := i % 2
		var x := _x + col * (w + 24)
		if i == packs.size() - 1 and packs.size() % 2 == 1:
			x = _x + (_cw - w) / 2.0
		var c := QuiltCard.new()
		c.fabric = [5, 9, 11, 1, 4][i % 5]
		c.inner = 12
		c.radius = 44
		c.glow = bool(p.best)
		c.pressable = true
		c_add(c, Vector2(x, _y), Vector2(w, h))
		Ui.pop_in(c, 0.05 + i * 0.06, 0.7)
		# Yüksük yığını: paket büyüdükçe daha çok yüksük
		var n := mini(i + 1, 4)
		for k in n:
			var ic := _icon(c, "ic_gem", Vector2(w / 2.0 - 60 + (k - (n - 1) / 2.0) * 44, 26 + absf(k - (n - 1) / 2.0) * 10), 120)
			ic.rotation = (k - (n - 1) / 2.0) * 0.12
		_lbl(c, "%d" % int(p.gems), 56, Vector2(0, 150), Vector2(w, 70), Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		var b := Ui.button(Purchases.get_price(String(p.id)), "mustard", Vector2(w - 60, 92), "", 38)
		Ui.place(b, Vector2(30, 224), b.size)
		c.add_child(b)
		var id := String(p.id)
		b.tapped.connect(func() -> void: _buy(id, b))
		c.tapped.connect(func() -> void: _buy(id, b))
		if bool(p.best):
			var rib := Ui.badge(tr("shop.bestValue"), Palette.TERRACOTTA)
			rib.fs = 26
			rib.position = Vector2(w / 2.0 - 110, -22)
			c.add_child(rib)
		if col == 1 or i == packs.size() - 1:
			_y += h + 24

func _free() -> void:
	_section("shop.packs.section", "shop.packs.hint")
	var packs: Array = Wallet.AD_PACKS
	var w := (_cw - 48) / 3.0
	for i in packs.size():
		var p: Dictionary = packs[i]
		var c := QuiltCard.new()
		c.fabric = [2, 6, 3][i % 3]
		c.inner = 10
		c.radius = 40
		c_add(c, Vector2(_x + i * (w + 24), _y), Vector2(w, 300))
		Ui.pop_in(c, 0.05 + i * 0.06, 0.7)
		_icon(c, Ui.currency_icon(String(p.earn)), Vector2((w - 110) / 2.0, 22), 110)
		_lbl(c, "+%d" % int(p.amount), 44, Vector2(0, 130), Vector2(w, 56), Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		var b := Ui.button(tr("shop.free"), "sage", Vector2(w - 40, 84), "", 34)
		Ui.place(b, Vector2(20, 196), b.size)
		c.add_child(b)
		b.tapped.connect(func() -> void: _watch_for(String(p.earn), int(p.amount), b))
	_y += 324

func _exchange() -> void:
	_section("shop.exchange.section", "shop.exchange.hint")
	_ex_row("coin_gem", "coin", "gem", Wallet.COIN_PER_GEM, 10)
	_ex_row("gem_ticket", "gem", "ticket", Wallet.GEM_PER_TICKET, 5)

func _ex_row(key: String, from: String, to: String, rate: int, mx: int) -> void:
	var c := _card(8, 220)
	# Kur: 100 [coin] → 1 [gem]
	_icon(c, Ui.currency_icon(from), Vector2(30, 34), 74)
	_lbl(c, "%d" % rate, 38, Vector2(104, 34), Vector2(110, 74))
	_lbl(c, "→", 44, Vector2(206, 34), Vector2(50, 74), Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_icon(c, Ui.currency_icon(to), Vector2(256, 34), 74)
	_lbl(c, "1", 38, Vector2(334, 34), Vector2(50, 74))
	# Adım: [-] n [+]
	var minus := Ui.icon_button("ic_home", 84)
	minus.icon = null
	minus.text = "−"
	minus.font_size = 56
	minus.text_col = Palette.INK
	Ui.place(minus, Vector2(_cw - 330, 30), Vector2(84, 84))
	c.add_child(minus)
	var nl := _lbl(c, "1", 50, Vector2(_cw - 246, 30), Vector2(110, 84), Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var plus := Ui.icon_button("ic_home", 84)
	plus.icon = null
	plus.text = "+"
	plus.font_size = 56
	plus.text_col = Palette.INK
	Ui.place(plus, Vector2(_cw - 136, 30), Vector2(84, 84))
	c.add_child(plus)
	var btn := Ui.button("", "mustard", Vector2(_cw - 60, 80), Ui.currency_icon(from), 36)
	Ui.place(btn, Vector2(30, 126), btn.size)
	c.add_child(btn)
	var st := {"n": 1, "label": nl, "btn": btn, "max": mx, "from": from, "to": to, "rate": rate}
	_ex[key] = st
	minus.tapped.connect(func() -> void:
		st.n = maxi(1, int(st.n) - 1)
		Ui.punch(nl, 0.2)
		_refresh())
	plus.tapped.connect(func() -> void:
		st.n = mini(mx, int(st.n) + 1)
		Ui.punch(nl, 0.2)
		_refresh())
	btn.tapped.connect(func() -> void:
		if Wallet.exchange(from, to, int(st.n)):
			_celebrate(btn, to, int(st.n))
			Main.toast(tr("shop.exchange.success.title"), Ui.currency_icon(to), Palette.SAGE))
	btn.denied.connect(func() -> void: Ui.shake(btn))
	_y += 244

func _bundles() -> void:
	_section("shop.hintsSection")
	_iap_row(Purchases.HINTS_SMALL, "ic_hint", "sku.hintsSmall.title", "sku.hintsSmall.body", 0)
	_section("shop.oneTime")
	# Anahtar sandık açar (rastgele ödül) → olasılıklar satın almadan önce görünür (Apple 3.1.1).
	_iap_row(Purchases.KEYS_SMALL, "ic_key", "sku.keysSmall.title", tr("shop.info.keys.body") + "\n" + Chest.odds_text(), 3)
	_iap_row(Purchases.REMOVE_ADS, "ic_sound", "sku.removeAds.title", "sku.removeAds.body", 7)

func _iap_row(id: String, icon: String, title: String, body: String, fabric: int) -> void:
	# Açıklama 5 satıra kadar (es/tr uzun, anahtarda olasılıklar); kart yüksekliği satır sayısına göre.
	var m := Ui.wrap(Ui.label(tr(body), 27, Palette.INK_SOFT), _cw - 480)
	m.max_lines_visible = 5
	m.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var lines := clampi(roundi(Ui.FONT.get_multiline_string_size(tr(body), HORIZONTAL_ALIGNMENT_LEFT, _cw - 480, 27).y / Ui.FONT.get_height(27)), 1, 5)
	var h := 120.0 + lines * 36.0
	var c := _card(fabric, h)
	_icon(c, icon, Vector2(30, (h - 140) / 2.0), 140)
	_lbl(c, tr(title), Ui.fit_font(tr(title), 44, _cw - 480, 32), Vector2(190, 26), Vector2(_cw - 470, 60))
	Ui.place(m, Vector2(190, 90), Vector2(_cw - 480, lines * 36.0 + 8))
	c.add_child(m)
	var b := Ui.button(Purchases.get_price(id), "mustard", Vector2(240, 100), "", 38)
	Ui.place(b, Vector2(_cw - 270, (h - 100) / 2.0), b.size)
	c.add_child(b)
	b.tapped.connect(func() -> void: _buy(id, b))
	_iap_rows[id] = b
	_y += h + 22

func _restore() -> void:
	_y += 20
	var b := Ui.button(tr("shop.restore"), "sage", Vector2(_cw - 160, 120), "", 42)
	c_add(b, Vector2(_x + 80, _y))
	b.tapped.connect(func() -> void:
		Ui.punch(b, 0.1)
		Purchases.restore())
	_y += 150

func _debug() -> void:
	_section("shop.debug.section")
	var opts := [["shop.debug.add.coins", "coin", 500], ["shop.debug.add.gems", "gem", 100], ["shop.debug.add.tickets", "ticket", 5]]
	var w := (_cw - 40) / 3.0
	for i in opts.size():
		var o: Array = opts[i]
		var b := Ui.button(tr(o[0]), "terracotta", Vector2(w, 100), "", 26)
		c_add(b, Vector2(_x + i * (w + 20), _y))
		b.tapped.connect(func() -> void:
			Wallet.add(String(o[1]), int(o[2]), "debug")
			_celebrate(b, String(o[1]), int(o[2])))
	_y += 130

# ------------------------------------------------------------------ Eylemler

func _buy(id: String, b: Control) -> void:
	_last_tap = b.global_position + b.size / 2.0
	Ui.punch(b, 0.12)
	Purchases.buy(id)

func _watch_for(earn: String, amount: int, b: JuicyButton) -> void:
	if not Ads.rewarded_ready():
		Main.toast(tr("shop.claim.adNotReady"), "ic_sound", Palette.TERRACOTTA)
		Ui.shake(b)
		return
	Ads.show_rewarded(func() -> void:
		if earn == "energy":
			Energy.add(amount)
		else:
			Wallet.add(earn, amount, "ad")
		_celebrate(b, earn, amount))

## Ödül zaten verildi: barı tut, ikonları butondan uçur.
func _celebrate(from: Control, c: String, amount: int) -> void:
	Fly.hold({c: amount})
	Fly.currency(from.global_position + from.size / 2.0, c, amount)
	Sfx.play("reward", 1.0, -4.0)
	Juice.haptic("medium")

func _on_bought(id: String) -> void:
	if not is_inside_tree():
		return
	var from := _last_tap if _last_tap != Vector2.ZERO else size / 2.0
	var gp := Purchases.gem_pack(id)
	Main.toast(tr("toast.purchase.done"), "ic_crown" if id == Purchases.PREMIUM else "ic_gem", Palette.SAGE)
	if not gp.is_empty():
		Fly.hold({"gem": int(gp.gems)})
		Fly.currency(from, "gem", int(gp.gems))
	elif id == Purchases.HINTS_SMALL:
		Fly.currency(from, "hint", Purchases.HINTS_PER_PACK)
	elif id == Purchases.KEYS_SMALL:
		Fly.currency(from, "key", Purchases.KEYS_PER_PACK)
	Sfx.play("reward")
	Juice.add_trauma(0.2)
	_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	for c in _owned:
		var l: Label = _owned[c]
		var v := str(Wallet.balance(c))
		if l.text != v:
			l.text = v
			Ui.punch(l, 0.25)
	for k in _ex:
		var st: Dictionary = _ex[k]
		(st.label as Label).text = str(st.n)
		var cost := int(st.n) * int(st.rate)
		var have := Wallet.balance(String(st.from))
		var b: JuicyButton = st.btn
		if have >= cost:
			b.text = "%s · %d" % [tr("shop.exchange.confirm"), cost]
			b.disabled = false
		else:
			b.text = tr("shop.exchange.need") % (cost - have)
			b.disabled = true
	if _iap_rows.has(Purchases.REMOVE_ADS):
		var rb: JuicyButton = _iap_rows[Purchases.REMOVE_ADS]
		if Purchases.ads_removed():
			rb.text = tr("shop.owned")
			rb.disabled = true
	if _iap_rows.has("deal"):
		var db: JuicyButton = _iap_rows.deal
		if Wallet.deal_claimed():
			db.disabled = true
		elif db.has_meta("cost"):
			var cc: Array = db.get_meta("cost")
			db.disabled = Wallet.balance(String(cc[0])) < int(cc[1])

func on_enter() -> void:
	_refresh()

func _ready() -> void:
	super()
	_refresh()
