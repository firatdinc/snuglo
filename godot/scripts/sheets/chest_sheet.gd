extends Sheet
## Ödül sandığı (hasır dikiş sandığı): 5 çözümde bir dolar, açmak 1 anahtar ister.
## Aç → tam ekran ChestOpening sekansı (kademe tırmanışı, patlama, ödül kartları, Topla / İzle 2×).
## Dev: SNUG_AUTOOPEN=1.

var _chest: TextureRect
var _rays: Rays
var _btn: JuicyButton
var _tier: Label
var _busy := false

func _init() -> void:
	panel_size = Vector2(-1, 1100)

func build() -> void:
	var w := pw()
	var y := banner_title(tr("chest.title")) + 30
	var ready := Chest.has_chest()
	var sub := Ui.label(tr("chest.ready") if ready else tr("chest.progress") % [Chest.progress, Chest.goal], 38, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(sub, Vector2(40, y - 4), Vector2(w - 80, 54))
	y += 70
	_rays = Rays.new()
	_rays.alpha = 0.0
	_rays.count = 16
	add(_rays, Vector2((w - 760) / 2.0, y - 160), Vector2(760, 760))
	var cw := minf(w - 200, 560.0)
	var ch := cw * 340.0 / 489.0
	_chest = Ui.tex_rect(UiArt.tex("chest_closed"), Vector2(cw, ch))
	add(_chest, Vector2((w - cw) / 2.0, y + 40))
	_chest.pivot_offset = Vector2(cw / 2.0, ch)
	if not ready:
		_chest.modulate = Color(0.75, 0.72, 0.7)
	Ui.bob(_chest, 6.0, 1.8)
	# Bekleyen sandık sayısı rozeti
	if Chest.pending > 1:
		var b := Ui.badge("×%d" % Chest.pending, Palette.MUSTARD.darkened(0.1))
		b.position = Vector2(cw - 40, 0)
		_chest.add_child(b)
	_tier = Ui.title("", 58, Palette.CREAM)
	add(_tier, Vector2(0, y + ch * 0.25), Vector2(w, 80))
	_tier.modulate.a = 0.0
	y += ch + 90
	# İlerleme çubuğu + anahtarlar
	var bar := Widgets.StitchBar.new()
	bar.value = float(Chest.progress) / Chest.goal
	bar.col = Palette.MUSTARD
	add(bar, Vector2(120, y), Vector2(w - 240, 36))
	var pl := Ui.label(tr("chest.progress") % [Chest.progress, Chest.goal], 30, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(pl, Vector2(40, y + 40), Vector2(w - 80, 44))
	y += 100
	# Olasılıklar (Apple 3.1.1: rastgele ödül + satın alınabilir anahtar → açmadan önce göster)
	var odds := Ui.wrap(Ui.label(Chest.odds_text(), 27, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER), w - 120)
	add(odds, Vector2(60, y), Vector2(w - 120, 76))
	y += 86
	var kk := Ui.icon("ic_key", Vector2(80, 80))
	add(kk, Vector2(w / 2.0 - 120, y))
	var kl := Ui.label(tr("shop.keysOwned") % Wallet.keys, 38, Palette.INK)
	add(kl, Vector2(w / 2.0 - 30, y), Vector2(400, 80))
	y += 110
	if Chest.can_open():
		_btn = Ui.button(tr("chest.tapToOpen"), "terracotta", Vector2(w - 200, 160), "ic_key", 56)
		add(_btn, Vector2(100, y))
		_btn.tapped.connect(_open_chest)
		var hit := Control.new()
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		add(hit, _chest.position, _chest.size)
		hit.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventScreenTouch and not e.pressed:
				_open_chest())
		y += 180
	else:
		var why := tr("shop.info.keys.body") if ready else tr("chest.progress") % [Chest.progress, Chest.goal]
		y = body(why, y, 32) + 20
		var shop := Ui.button(tr("shop.keysSection"), "mustard", Vector2(w - 200, 140), "ic_shop", 50)
		add(shop, Vector2(100, y))
		shop.tapped.connect(func() -> void:
			close()
			Main.open_shop())
		y += 160
	panel.size.y = y + 40
	_place_panel()
	close_x()
	if Dev.env("SNUG_AUTOOPEN") != "" and Chest.can_open():
		get_tree().create_timer(0.7).timeout.connect(_open_chest)

func _open_chest() -> void:
	if _busy or not Chest.can_open():
		return
	_busy = true
	dismissible = false
	if _btn:
		_btn.disabled = true
	# Ödül baştan belirlenir (anahtar harcandı); tam ekran açılış sekansı patlamada verir,
	# erken kapanırsa kendi _exit_tree'si verir.
	var r := Chest.open(false)
	if r.is_empty():
		_busy = false
		dismissible = true
		return
	Sfx.play("click", 0.9, -4.0)
	Ui.punch(_chest, 0.12)
	ChestOpening.play(r, close)
