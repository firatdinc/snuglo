class_name Fly
extends RefCounted
## Para birimi uçuşu: ikonlar kaynaktan patlar, kavisle üst bardaki yuvaya uçar; her varışta
## yuva zıplar, sayı ilerler, nota yükselir. Üst bar yoksa ekranın üstüne uçup kaybolur.

static func target_bar(c: String) -> TopBar:
	var best: TopBar = null
	for n in Ui.tree().get_nodes_in_group("topbar"):
		var b := n as TopBar
		if b and b.is_visible_in_tree() and b.has_slot(c):
			if best == null or _layer_index(b) >= _layer_index(best):
				best = b
	return best

static func _layer_index(n: Node) -> int:
	var p := n.get_parent()
	while p and not (p is CanvasLayer):
		p = p.get_parent()
	return (p as CanvasLayer).layer if p else 0

## from: global konum. amount: verilen miktar (ikon sayısı ondan türetilir, 3..12).
static func currency(from: Vector2, c: String, amount: int, delay := 0.0) -> void:
	if amount <= 0:
		return
	var host: Node = Main.fx_layer
	var bar := target_bar(c)
	var n := clampi(int(sqrt(float(amount)) * 1.4), 3, 12)
	if Ui.reduce_motion():
		n = 1
	var to := bar.slot_pos(c) if bar else Vector2(Ui.vp().x / 2.0, Ui.safe_top() + 40)
	var tex := UiArt.tex(Ui.currency_icon(c))
	for i in n:
		var s := Sprite2D.new()
		s.texture = tex
		var k := 92.0 / maxf(1.0, tex.get_height())
		s.scale = Vector2.ZERO
		s.position = from
		host.add_child(s)
		var burst := from + Vector2.from_angle(randf() * TAU) * randf_range(60, 190)
		var tw := s.create_tween()
		tw.tween_interval(delay + i * 0.045)
		tw.tween_callback(func() -> void: Sfx.play("click", 1.8 + randf() * 0.4, -16.0, 0.0))
		tw.set_parallel()
		tw.tween_property(s, "position", burst, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", Vector2(k, k), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.set_parallel(false)
		tw.tween_interval(0.08 + (n - i) * 0.02)
		var ctrl := burst + Vector2(randf_range(-260, 260), randf_range(-60, 160))
		tw.tween_method(func(t: float) -> void:
			var a := burst.lerp(ctrl, t)
			var b := ctrl.lerp(to, t)
			s.position = a.lerp(b, t)
			s.scale = Vector2(k, k) * lerpf(1.0, 0.7, t)
			s.rotation = sin(t * 6.0) * 0.3, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var idx := i
		tw.tween_callback(func() -> void:
			Sfx.note(mini(idx, 11), "place", -12.0)
			Juice.haptic("tick")
			if bar and is_instance_valid(bar):
				bar.arrive(c, float(idx + 1) / n)
			s.queue_free())

## Ödül sözlüğünü toplu uçur: {"coin": 50, "gem": 1}.
static func rewards(from: Vector2, r: Dictionary) -> void:
	var d := 0.0
	for c in r:
		if int(r[c]) > 0:
			currency(from, String(c), int(r[c]), d)
			d += 0.18

## Uçuş öncesi bar(lar)ı "eski" bakiyeye sabitle (ödül zaten verildiyse).
static func hold(r: Dictionary) -> void:
	for n in Ui.tree().get_nodes_in_group("topbar"):
		for c in r:
			if int(r[c]) > 0:
				var real := Energy.current if c == "energy" else Wallet.balance(String(c))
				(n as TopBar).set_display(String(c), real - int(r[c]))
