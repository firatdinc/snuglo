class_name RewardModal
extends Sheet
## Ortak ödül kutlaması: dönen ışınlar + maskot + başlık + sayarak artan ödül çipleri + Topla.
## Topla → ikonlar üst bara uçar. Ödül sistemi ÖNCEDEN vermiş olmalı (bar bu yüzden "tutulur").
## args: title (metin), subtitle, rewards {coin, gem, key, hint, ticket, cup, energy}, pose
## (maskot pozu), icon (maskot yerine art/ui ikonu), double (true → "İzle 2×", ödüllü reklam
## ödülü bir kez daha verir), on_done (Callable), cta (buton metni).

var _chips: Array[Control] = []
var _rewards := {}
var _doubled := false
var _collect: JuicyButton

func _init() -> void:
	panel_size = Vector2(-1, 1060)
	dismissible = false

func build() -> void:
	_rewards = (args.get("rewards", {}) as Dictionary).duplicate()
	Fly.hold(_rewards)
	var w := pw()
	var rays := Rays.new()
	rays.size = Vector2(760, 760)
	rays.position = Vector2(w / 2.0 - 380, -330)
	panel.add_child(rays)
	panel.move_child(rays, 0)
	var hero: TextureRect
	if args.has("icon"):
		hero = Ui.icon(String(args.icon), Vector2(300, 300))
	else:
		hero = Ui.icon(String(args.get("pose", "cheer")), Vector2(330, 330), "mascot")
	add(hero, Vector2(w / 2.0 - hero.size.x / 2.0, -170))
	Ui.pop_in(hero, 0.15, 0.2, 0.55)
	Ui.bob(hero, 8.0, 1.6)
	var y := heading(String(args.get("title", tr("reward.great"))), 190, 70)
	if String(args.get("subtitle", "")) != "":
		y = body(String(args.subtitle), y, 38)
	y += 30
	# Ödül çipleri
	var keys := []
	for c in _rewards:
		if int(_rewards[c]) > 0:
			keys.append(c)
	var cw := 250.0
	var gap := 24.0
	var per_row := mini(3, maxi(1, keys.size()))
	var rows := int(ceil(keys.size() / float(per_row)))
	for i in keys.size():
		var c: String = keys[i]
		var row := i / per_row
		var in_row := mini(per_row, keys.size() - row * per_row)
		var x0 := (w - (in_row * cw + (in_row - 1) * gap)) / 2.0
		var chip := QuiltCard.new()
		chip.fabric = -1
		chip.fill = Palette.CREAM
		chip.radius = 40
		chip.depth = 8
		add(chip, Vector2(x0 + (i % per_row) * (cw + gap), y + row * 180), Vector2(cw, 160))
		var ic := Ui.icon(Ui.currency_icon(c), Vector2(96, 96))
		ic.position = Vector2((cw - 96) / 2.0, 6)
		chip.add_child(ic)
		var l := Ui.label("+0", 46, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(0, 98)
		l.size = Vector2(cw, 56)
		chip.add_child(l)
		chip.set_meta("c", c)
		chip.set_meta("label", l)
		_chips.append(chip)
		Ui.pop_in(chip, 0.35 + i * 0.12, 0.3)
		var d := 0.45 + i * 0.12
		chip.get_tree().create_timer(d).timeout.connect(func() -> void:
			Ui.tick(l, 0, int(_rewards[c]), 0.7, "+%d"))
	y += rows * 180 + 30
	var bw := w - 160
	_collect = Ui.button(String(args.get("cta", tr("chest.collect"))), "sage", Vector2(bw, 150))
	add(_collect, Vector2(80, y))
	_collect.tapped.connect(_on_collect)
	Ui.pop_in(_collect, 0.6, 0.6)
	y += 170
	if bool(args.get("double", false)) and Ads.rewarded_ready():
		var dbl := Ui.button(tr("reward.double"), "mustard", Vector2(bw, 120))
		add(dbl, Vector2(80, y))
		dbl.tapped.connect(func() -> void:
			dbl.disabled = true
			Ads.show_rewarded(func() -> void:
				_doubled = true
				Wallet.grant(_rewards, "ad_double")
				for k in _rewards:
					_rewards[k] = int(_rewards[k]) * 2
				Fly.hold(_rewards)
				for ch in _chips:
					var cc: String = ch.get_meta("c")
					Ui.tick(ch.get_meta("label"), int(_rewards[cc]) / 2, int(_rewards[cc]), 0.6, "+%d")
					Ui.punch(ch, 0.2)
				Sfx.play("reward")
				dbl.queue_free())
		)
		Ui.pop_in(dbl, 0.7, 0.6)
		y += 140
	panel.size.y = y + 40
	_place_panel()
	panel.position.y += 110
	Sfx.play("reward", 1.0, -2.0, 0.0)
	Juice.haptic("medium")

func _on_collect() -> void:
	_collect.disabled = true
	for ch in _chips:
		var c: String = ch.get_meta("c")
		Fly.currency(ch.global_position + ch.size / 2.0, c, int(_rewards[c]))
		Ui.punch(ch, 0.15)
	var cb: Variant = args.get("on_done")
	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		close()
		if cb is Callable and (cb as Callable).is_valid():
			(cb as Callable).call())
