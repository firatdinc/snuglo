extends Sheet
## Nook parçası sürprizi (her 10. bölümün ilk çözümü): hediye sallanır (beklenti) → patlar
## (ışın, konfeti, ödül sesi, sarsıntı) → sahne yaması kartı yaylanarak gelir.
## args: pack, piece (0 tabanlı yerleştirme sırası), on_place (Callable), on_later (Callable).

const NookScreen := preload("res://scripts/screens/nook.gd")

var _gift: TextureRect
var _rays: Rays
var _fx: Fx
var _stage: Control

func _init() -> void:
	panel_size = Vector2(-1, 1140)
	dismissible = false

func build() -> void:
	var w := pw()
	_rays = Rays.new()
	_rays.size = Vector2(900, 900)
	_rays.position = Vector2(w / 2.0 - 450, 40)
	_rays.alpha = 0.0
	panel.add_child(_rays)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add(_stage, Vector2.ZERO, panel.size)
	_gift = Ui.icon("ic_gift", Vector2(340, 340))
	add(_gift, Vector2((w - 340) / 2.0, 320))
	_fx = Fx.new()
	add_child(_fx)
	_anticipate()

func _anticipate() -> void:
	var tw := create_tween()
	tw.tween_interval(0.35)
	for i in 6:
		var dir := 1.0 if i % 2 == 0 else -1.0
		tw.tween_callback(func() -> void:
			Juice.haptic("light")
			Sfx.play("click", 0.9 + i * 0.08, -8.0))
		tw.set_parallel()
		tw.tween_property(_gift, "rotation", deg_to_rad(7.0) * dir, 0.08)
		tw.tween_property(_gift, "scale", Vector2.ONE * (1.06 if i % 2 == 0 else 0.97) * (1.0 + i * 0.02), 0.08)
		tw.set_parallel(false)
		tw.tween_property(_gift, "rotation", 0.0, 0.08)
	tw.tween_callback(_burst)

func _burst() -> void:
	var c := panel.global_position + _gift.position + _gift.size / 2.0
	Sfx.play("reward", 1.0, 0.0, 0.0)
	Juice.add_trauma(0.45)
	Juice.haptic("heavy")
	_fx.confetti(c, 90, PI * 0.9, -PI / 2, 1700.0)
	_fx.sparks(c, 26, Palette.GOLD, 900.0)
	_fx.ring(c, 260.0, Palette.CREAM, 22.0)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.85)
	flash.size = size
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	flash.create_tween().tween_property(flash, "color:a", 0.0, 0.45)
	var g := _gift.create_tween().set_parallel()
	g.tween_property(_gift, "scale", Vector2(1.6, 1.6), 0.25)
	g.tween_property(_gift, "modulate:a", 0.0, 0.25)
	create_tween().tween_property(_rays, "alpha", 0.4, 0.4)
	_reveal()

func _reveal() -> void:
	var w := pw()
	var pid := String(args.get("pack", "cozy-beginnings"))
	var k := clampi(int(args.get("piece", 0)), 0, Nook.PIECES_PER_SCENE - 1)
	var y := banner_title(tr("nook.title"), minf(w - 120, 620.0))
	var t := Ui.wrap(Ui.label(tr("nook.reveal.title"), 54, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER), w - 120)
	add(t, Vector2(60, y + 20))
	t.size.y = 140
	Ui.pop_in(t, 0.1, 0.6)
	# Yama kartı
	var geo: Dictionary = NookScreen.SceneCanvas.shard_geometry(pid)
	var idx: int = geo.order[k]
	var csz := Vector2(1000, 1300)
	var poly := PackedVector2Array()
	for p in geo.shards[idx]:
		poly.append(p * csz)
	var card := QuiltCard.new()
	card.fill = Palette.CREAM
	card.radius = 40
	add(card, Vector2((w - 460) / 2.0, y + 180), Vector2(460, 420))
	var sv := NookScreen.ShardView.new()
	sv.setup_raw(PackArt.scene(pid), poly, csz, idx)
	sv.glow = true
	Ui.place(sv, Vector2(30, 30), Vector2(400, 360))
	card.add_child(sv)
	card.rotation = -0.05
	Ui.pop_in(card, 0.15, 0.2, 0.6)
	var fr := Ui.tex_rect(PackArt.animal(pid), Vector2(170, 170))
	add(fr, Vector2((w + 460) / 2.0 - 110, y + 500))
	Ui.pop_in(fr, 0.4, 0.2)
	var lbl := Ui.label(tr("nook.reveal.piece") % [k + 1, Nook.PIECES_PER_SCENE], 34, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(lbl, Vector2(0, y + 620), Vector2(w, 50))
	var by := body(tr("nook.reveal.subtitle"), y + 680, 32)
	var bw := (w - 180) / 2.0
	var later := Ui.button(tr("nook.reveal.later"), "sage", Vector2(bw, 130))
	add(later, Vector2(70, by + 30))
	later.tapped.connect(func() -> void:
		close()
		_call("on_later"))
	var place := Ui.button(tr("nook.reveal.place"), "terracotta", Vector2(bw, 130))
	add(place, Vector2(110 + bw, by + 30))
	place.tapped.connect(func() -> void:
		close()
		if not _call("on_place"):
			Main.push("nook", {"pack": pid, "auto_return": true}))
	Ui.pop_in(later, 0.5, 0.6)
	Ui.pop_in(place, 0.55, 0.6)

func _call(key: String) -> bool:
	var cb: Variant = args.get(key)
	if cb is Callable and (cb as Callable).is_valid():
		(cb as Callable).call()
		return true
	return false
