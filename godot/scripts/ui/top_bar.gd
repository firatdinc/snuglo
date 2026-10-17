class_name TopBar
extends Control
## Para birimi çubuğu: enerji fincanı (+dolum sayacı), coin düğmesi, gem yüksüğü. Dokunma → Mağaza.
## Fly hedefi: Fly.currency() buradaki ikona uçar; varış anında sayı tıklayarak artar.
## Tüm örnekler "topbar" grubunda; en üstteki görünür örnek uçuş hedefidir.

const PILL_H := 84.0

var currencies := ["energy", "coin", "gem"]
var align_right := false
var tap_to_shop := true
var _pills := {}       # c → {box: Control, label: Label, icon: TextureRect, shown: int, held: bool}
var _timer: Label
var _acc := 0.0

func _ready() -> void:
	add_to_group("topbar")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	Events.wallet_changed.connect(_on_wallet)
	Purchases.entitlements_changed.connect(_refresh_energy)

func _width(c: String) -> float:
	return {"energy": 250.0, "coin": 270.0, "gem": 230.0}.get(c, 230.0)

func _build() -> void:
	var total := 0.0
	for c in currencies:
		total += _width(c)
	var gap := clampf((size.x - total) / maxf(1.0, currencies.size() - 1), 16.0, 40.0)
	total += gap * (currencies.size() - 1)
	var x := size.x - total if align_right else (size.x - total) / 2.0
	for c: String in currencies:
		var w := _width(c)
		var box := QuiltCard.new()
		box.pressable = tap_to_shop
		box.fill = Palette.CARD
		box.radius = PILL_H / 2.0
		box.depth = 6.0
		box.position = Vector2(x + 34, 0)
		box.size = Vector2(w - 34, PILL_H)
		add_child(box)
		var ic := Ui.icon(Ui.currency_icon(c), Vector2(104, 104))
		ic.position = Vector2(x - 6, (PILL_H - 104) / 2.0)
		add_child(ic)
		var l := Ui.label("", 42, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(60, 0)
		l.size = Vector2(w - 34 - 60 - 44, PILL_H)
		box.add_child(l)
		# "+" düğmesi
		var plus := Ui.label("+", 40, Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		var pc := PlusDot.new()
		pc.position = Vector2(w - 34 - 56, (PILL_H - 50) / 2.0)
		pc.size = Vector2(50, 50)
		box.add_child(pc)
		plus.size = pc.size
		pc.add_child(plus)
		if tap_to_shop:
			box.tapped.connect(func() -> void:
				Ui.punch(ic, 0.25)
				if c == "energy" and not Energy.unlimited() and not Energy.is_full():
					Main.open("energy", {})
				else:
					Main.open_shop())
		var shown := Energy.current if c == "energy" else Wallet.balance(c)
		_pills[c] = {"box": box, "label": l, "icon": ic, "shown": shown, "held": false}
		x += w + gap
	if _pills.has("energy"):
		_timer = Ui.title("", 24, Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		var b: Control = _pills.energy.box
		_timer.position = Vector2(b.position.x + 30, PILL_H + 2)
		_timer.size = Vector2(b.size.x - 80, 30)
		add_child(_timer)
	for c in _pills:
		_show(c)
	_refresh_energy()

func _show(c: String) -> void:
	var p: Dictionary = _pills[c]
	if c == "energy" and Energy.unlimited():
		p.label.text = "∞"
	else:
		p.label.text = Ui.short_num(int(p.shown))

func _process(dt: float) -> void:
	_acc += dt
	if _acc >= 0.5:
		_acc = 0.0
		_refresh_energy()

func _refresh_energy() -> void:
	if not _pills.has("energy"):
		return
	var p: Dictionary = _pills.energy
	var cur := Energy.current
	if cur != int(p.shown) and not p.held:
		p.shown = cur
		_show("energy")
	if Energy.unlimited():
		_show("energy")
		_timer.text = tr("energy.unlimited")
	elif Energy.is_full():
		_timer.text = tr("energy.full")
	else:
		_timer.text = tr("energy.next") % Ui.fmt_time(Energy.seconds_until_next())

func _on_wallet(c: String, amount: int, delta: int) -> void:
	if not _pills.has(c):
		return
	var p: Dictionary = _pills[c]
	if p.held:
		return
	var from := int(p.shown)
	p.shown = amount
	if not is_visible_in_tree():
		_show(c)
		return
	Ui.tick(p.label, from, amount, 0.5, "%d", false).finished.connect(func() -> void: _show(c))
	if delta < 0:
		Ui.shake(p.box, 6.0)
	else:
		Ui.punch(p.icon, 0.2)

## Uçuş hedefi (global konum).
func slot_pos(c: String) -> Vector2:
	if not _pills.has(c):
		return Vector2(-1, -1)
	var ic: Control = _pills[c].icon
	return ic.global_position + ic.size / 2.0

func has_slot(c: String) -> bool:
	return _pills.has(c)

## Gösterilen sayıyı geçici değere sabitle (uçuş bitene kadar).
func set_display(c: String, v: int) -> void:
	if not _pills.has(c):
		return
	_pills[c].shown = v
	_pills[c].held = true
	_show(c)
	# Güvenlik: uçuş bu bara gelmezse birkaç sn sonra gerçek bakiyeye dön.
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if is_instance_valid(self) and _pills[c].held:
			arrive(c, 1.0))

## Bir uçan ikon geldi: frac (0..1) kadar hedefe ilerle; 1 → serbest bırak.
func arrive(c: String, frac: float) -> void:
	if not _pills.has(c):
		return
	var p: Dictionary = _pills[c]
	var real := Energy.current if c == "energy" else Wallet.balance(c)
	var v := int(lerpf(float(p.shown), float(real), clampf(frac, 0.0, 1.0)))
	p.shown = v
	_show(c)
	Ui.punch(p.icon, 0.3)
	if frac >= 1.0:
		p.held = false
		p.shown = real
		_show(c)

class PlusDot extends Control:
	func _draw() -> void:
		draw_circle(size / 2.0 + Vector2(0, 3), size.x / 2.0, Palette.MUSTARD.darkened(0.35))
		draw_circle(size / 2.0, size.x / 2.0, Palette.MUSTARD)
		draw_arc(size / 2.0, size.x / 2.0 - 5, 0, TAU, 24, Color(Palette.STITCH, 0.7), 2.0)
