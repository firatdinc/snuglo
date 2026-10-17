extends Sheet
## Ödül sandığı (hasır dikiş sandığı): 5 çözümde bir dolar, açmak 1 anahtar ister.
## Aç → beklenti (9×0.09 sn sallanma, artan nabız, tık titreşimleri) → beyaz parlama + ışınlar +
## sandık açılır, kademe rozeti yaylanır → ödül modalı (Topla → üst bara uçuş, İzle → 2×).
## Dev: SNUG_AUTOOPEN=1.

var _chest: TextureRect
var _rays: Rays
var _btn: JuicyButton
var _tier: Label
var _busy := false
var _pending := {}   ## açıldı ama henüz verilmedi (sayfa erken kapanırsa _exit_tree verir)

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
	y += 110
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
	if OS.get_environment("SNUG_AUTOOPEN") != "" and Chest.can_open():
		get_tree().create_timer(0.7).timeout.connect(_open_chest)

const TIER_COL := {"common": Color("8fa77a"), "rare": Color("5f86b8"), "epic": Color("9a5aa8"), "legendary": Color("e2a93b")}

func _exit_tree() -> void:
	if not _pending.is_empty():
		Chest.grant(_pending)
		_pending = {}

func _open_chest() -> void:
	if _busy or not Chest.can_open():
		return
	_busy = true
	dismissible = false
	if _btn:
		_btn.disabled = true
	# Ödül baştan belirlenir (anahtar harcandı); animasyon kademeyi şansla tırmandırır, ödül patlamada verilir.
	var r := Chest.open(false)
	_pending = r
	if r.is_empty():
		_busy = false
		dismissible = true
		return
	_chest.modulate = Color.WHITE
	var target: int = Chest.TIERS.find(String(r.tier))
	var tw := create_tween()
	var rm := Ui.reduce_motion()
	for i in (2 if rm else 8):
		var s := 1.0 + 0.012 * i
		tw.tween_property(_chest, "rotation", 0.09 * (1.0 if i % 2 == 0 else -1.0), 0.045)
		tw.parallel().tween_property(_chest, "scale", Vector2(s, 2.0 - s), 0.045)
		tw.tween_property(_chest, "rotation", 0.0, 0.045)
		if i % 3 == 0:
			tw.tween_callback(func() -> void:
				Juice.haptic("light")
				Sfx.play("click", 0.9 + i * 0.06, -8.0)
				Juice.add_trauma(0.08))
	# Kademe tırmanışı: Sıradan → Nadir → Destansı → Efsanevi; her basamakta daha büyük nabız.
	for step in target + 1:
		tw.tween_callback(_tier_step.bind(step, step == target))
		tw.tween_interval(0.5 if step < target else 0.35)
	# Bir üst kademeye "az kaldı" titremesi (en üstte değilse, yarı şansla).
	if target < Chest.TIERS.size() - 1 and randf() < 0.5 and not rm:
		tw.tween_callback(_tease.bind(target + 1))
		tw.tween_interval(0.5)
		tw.tween_callback(_tier_step.bind(target, true))
		tw.tween_interval(0.3)
	tw.tween_property(_chest, "scale", Vector2(1.12, 0.86), 0.1)
	tw.tween_callback(_burst.bind(r))

## Kademe basamağı: etiket + ışın rengi + sandık zıplaması; final=true ise yerleşir.
func _tier_step(step: int, final: bool) -> void:
	var tier: String = Chest.TIERS[step]
	var col: Color = TIER_COL[tier]
	_tier.text = tr("chest.tier." + tier)
	_tier.add_theme_color_override("font_color", col.lightened(0.15))
	_tier.modulate.a = 1.0
	_tier.position.y = _chest.position.y - 70
	Ui.pop_in(_tier, 0.0, 0.25, 0.6)
	_rays.col = col.lightened(0.3)
	create_tween().tween_property(_rays, "alpha", 0.15 + 0.12 * step, 0.2)
	var k := 1.0 + 0.06 * step
	var tw := _chest.create_tween()
	tw.tween_property(_chest, "scale", Vector2(0.92, 1.1) * k, 0.07)
	tw.tween_property(_chest, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Sfx.play("combo" if not final else "snap", 0.9 + 0.15 * step, -6.0 + step)
	Juice.haptic("medium" if step < 2 else "heavy")
	Juice.add_trauma(0.1 + 0.08 * step)

## Bir üst kademenin adı titreyip söner (beklenti / kıl payı).
func _tease(step: int) -> void:
	var tier: String = Chest.TIERS[step]
	_tier.text = tr("chest.tier." + tier) + "?"
	_tier.add_theme_color_override("font_color", Color(TIER_COL[tier], 0.7))
	var tw := _tier.create_tween()
	for i in 3:
		tw.tween_property(_tier, "modulate:a", 0.25, 0.07)
		tw.tween_property(_tier, "modulate:a", 0.9, 0.07)
	Sfx.play("click", 1.5, -10.0)
	Juice.haptic("tick")

func _burst(r: Dictionary) -> void:
	Chest.grant(r)
	_pending = {}
	_chest.texture = UiArt.tex("chest_open")
	var cw := _chest.size.x
	var ch := cw * 556.0 / 592.0
	var bottom := _chest.position.y + _chest.size.y
	_chest.size = Vector2(cw, ch)
	_chest.position.y = bottom - ch
	_chest.pivot_offset = Vector2(cw / 2.0, ch)
	var tw := _chest.create_tween()
	tw.tween_property(_chest, "scale", Vector2(0.9, 1.15), 0.08)
	tw.tween_property(_chest, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var tier := String(r.get("tier", "common"))
	var big := tier in ["epic", "legendary"]
	# Beyaz parlama
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.9)
	flash.size = size
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.5 if not big else 0.8).finished.connect(flash.queue_free)
	create_tween().tween_property(_rays, "alpha", 0.45 if not big else 0.7, 0.4)
	Sfx.play("reward", 1.0, 0.0, 0.0)
	if big:
		Sfx.play("solve", 1.1, -4.0)
	Juice.haptic("heavy")
	Juice.add_trauma(0.45 if not big else 0.7)
	_tier.position.y = bottom - 30
	Ui.pop_in(_tier, 0.05, 0.3, 0.5)
	var rew: Dictionary = r.get("rewards", {})
	get_tree().create_timer(0.9 if not big else 1.2).timeout.connect(func() -> void:
		var m := Main.reward(tr("chest.reward"), rew, {"double": true, "pose": "cheer", "subtitle": tr("chest.tier." + tier), "cta": tr("chest.collect")})
		if m:
			m.closed.connect(close)
		else:
			close())
