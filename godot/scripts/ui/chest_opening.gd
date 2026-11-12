class_name ChestOpening
extends Control
## Tam ekran sandık açılışı (motion design): karartma → dikişli yorgan zemin + dönen ışınlar +
## süzülen keçe pırıltıları → sandık yaylanarak düşer → kademe tırmanışı (her basamakta daha sert
## sallanma, ışın rengi, kumaş harfli kademe adı değişimi, yükselen ses/titreşim; "az kaldı"
## titremesi) → beyaz patlama, kapak açılır, ikon yağmuru → ödül kartları sayarak açılır → Topla
## (üst bara uçuş) / İzle 2×. Ekonomi Chest ile aynı: ödül patlamada Chest.grant ile verilir;
## patlamadan önce kapanırsa _exit_tree verir. Kullanım: ChestOpening.play(Chest.open(false), cb).

const TIER_COL := {"common": Color("8fa77a"), "rare": Color("5f86b8"), "epic": Color("9a5aa8"), "legendary": Color("e2a93b")}
const LAYER := 60   # sayfaların (40) üstü, sürüm kapısının (70) ve uçuş katmanının (80) altı

var r: Dictionary
var on_done: Callable
var _granted := false
var _layer: CanvasLayer
var _root: Control
var _dim: ColorRect
var _bg: QuiltBg
var _rays: Rays
var _chest: TextureRect
var _word: FabricWord
var _fx: Fx
var _cards: Array[Control] = []
var _ticks: Array[Tween] = []
var _buttons: Control
var _rewards := {}
var _trauma := 0.0
var _t := 0.0
var _cards_shown := false
var _closing := false
var _chest_home := Vector2.ZERO
var _rm := false

static func play(roll: Dictionary, done: Callable = Callable()) -> ChestOpening:
	var l := CanvasLayer.new()
	l.layer = LAYER
	Main.host.add_child(l)
	var o := ChestOpening.new()
	o.r = roll
	o.on_done = done
	o._layer = l
	l.add_child(o)
	return o

func _ready() -> void:
	_rm = Ui.reduce_motion()
	_rewards = (r.get("rewards", {}) as Dictionary).duplicate()
	var vp := Ui.vp()
	size = vp
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	_dim = ColorRect.new()
	_dim.color = Color(0.12, 0.06, 0.03, 0.0)
	_dim.size = vp
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_root = Control.new()
	_root.size = vp
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.modulate.a = 0.0
	add_child(_root)
	_bg = QuiltBg.new()
	_bg.size = vp
	_root.add_child(_bg)
	var cy := vp.y * 0.47
	_rays = Rays.new()
	_rays.count = 18
	_rays.alpha = 0.0
	_rays.speed = 0.5
	_rays.col = TIER_COL.common
	var rs := vp.x * 1.7
	_rays.size = Vector2(rs, rs)
	_rays.position = Vector2(vp.x / 2.0 - rs / 2.0, cy - rs / 2.0)
	_root.add_child(_rays)
	var vig := TextureRect.new()
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.47)
	g.fill_to = Vector2(1.05, 1.05)
	var gr := Gradient.new()
	gr.set_color(0, Color(0.1, 0.05, 0.02, 0.0))
	gr.set_color(1, Color(0.1, 0.05, 0.02, 0.82))
	g.gradient = gr
	vig.texture = g
	vig.size = vp
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(vig)
	var cw := minf(vp.x * 0.74, 800.0)
	var ch := cw * 340.0 / 489.0
	_chest = Ui.tex_rect(UiArt.tex("chest_closed"), Vector2(cw, ch))
	_chest_home = Vector2((vp.x - cw) / 2.0, cy - ch / 2.0)
	_chest.position = _chest_home
	_chest.pivot_offset = Vector2(cw / 2.0, ch)
	_root.add_child(_chest)
	_fx = Fx.new()
	_root.add_child(_fx)
	_buttons = Control.new()
	_buttons.size = vp
	_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_buttons)
	_run()

func _exit_tree() -> void:
	if not _granted and not r.is_empty():
		Chest.grant(r)
		_granted = true

func _process(dt: float) -> void:
	_t += dt
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - dt * 1.6)
		var s := _trauma * _trauma
		_root.position = Vector2(26.0 * s * sin(_t * 41.0), 20.0 * s * sin(_t * 37.0 + 1.3))
	else:
		_root.position = Vector2.ZERO

func _shake(a: float) -> void:
	if not _rm:
		_trauma = clampf(_trauma + a, 0.0, 1.0)

# ------------------------------------------------------------------ Akış

func _run() -> void:
	var vp := Ui.vp()
	var tw := create_tween()
	tw.tween_property(_dim, "color:a", 0.72, 0.2)
	tw.parallel().tween_property(_root, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(_rays, "alpha", 0.16, 0.5)
	await tw.finished
	await _drop_in()
	var target: int = Chest.TIERS.find(String(r.get("tier", "common")))
	for step in target + 1:
		await _tier_step(step, step == target)
	if target < Chest.TIERS.size() - 1 and not _rm and randf() < 0.5:
		await _tease(target + 1)
		await _tier_step(target, true, true)
	await _charge(target)
	_burst(target)
	await get_tree().create_timer(0.45 if not _rm else 0.1).timeout
	_show_cards()
	await get_tree().create_timer(0.55 + _cards.size() * 0.12 if not _rm else 0.2).timeout
	_show_buttons()

func _drop_in() -> void:
	if _rm:
		Ui.pop_in(_chest, 0.0, 0.8, 0.25)
		await get_tree().create_timer(0.3).timeout
		return
	_chest.position = _chest_home + Vector2(0, -Ui.vp().y * 0.6)
	_chest.scale = Vector2(0.85, 1.15)
	var tw := _chest.create_tween()
	tw.tween_property(_chest, "position", _chest_home, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		Sfx.play("snap", 0.7, -2.0)
		Juice.haptic("heavy")
		_shake(0.45)
		var foot := _chest_home + Vector2(_chest.size.x / 2.0, _chest.size.y)
		_fx.puff(foot + Vector2(-_chest.size.x * 0.35, 0), 6, Palette.CREAM, 30.0)
		_fx.puff(foot + Vector2(_chest.size.x * 0.35, 0), 6, Palette.CREAM, 30.0))
	tw.tween_property(_chest, "scale", Vector2(1.28, 0.72), 0.06)
	tw.tween_property(_chest, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.62).timeout

## Kademe basamağı: sandık sallanır (basamakla sertleşir), ışın rengi değişir, yazı değişir.
func _tier_step(step: int, final: bool, settle := false) -> void:
	var tier: String = Chest.TIERS[step]
	var col: Color = TIER_COL[tier]
	_set_word(tr("chest.tier." + tier) + ("!" if step >= 2 else ""), step)
	create_tween().tween_property(_rays, "col", col.lightened(0.25), 0.25)
	create_tween().tween_property(_rays, "alpha", 0.2 + 0.09 * step, 0.25)
	_bg.tint_to(col, 0.3)
	Sfx.play("combo" if not final else "snap", 0.85 + 0.17 * step, -5.0 + step)
	Juice.haptic(["light", "medium", "heavy", "heavy"][step])
	_shake(0.18 + 0.12 * step)
	var ctr := _chest_home + _chest.size * Vector2(0.5, 0.45)
	_fx.sparks(ctr, 8 + step * 5, col.lightened(0.3), 480.0 + step * 120.0)
	if settle:
		Ui.punch(_chest, 0.12)
		await get_tree().create_timer(0.45).timeout
		return
	# Sallanma: basamak arttıkça daha çok, daha hızlı, daha geniş.
	var n := 3 + step
	var amp := 0.07 + step * 0.035
	var tw := _chest.create_tween()
	if _rm:
		await get_tree().create_timer(0.35).timeout
		return
	for i in n:
		var s := 1.0 + 0.015 * (i + step * 2)
		tw.tween_property(_chest, "rotation", amp * (1.0 if i % 2 == 0 else -1.0), 0.035)
		tw.parallel().tween_property(_chest, "scale", Vector2(s, 2.0 - s), 0.035)
		tw.tween_property(_chest, "rotation", 0.0, 0.035)
	tw.tween_property(_chest, "scale", Vector2(0.92, 1.1), 0.06)
	tw.tween_property(_chest, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.08 if not final else 0.03).timeout

## "Az kaldı": bir üst kademenin adı titreyip söner.
func _tease(step: int) -> void:
	var tier: String = Chest.TIERS[step]
	_set_word(tr("chest.tier." + tier) + "?", step)
	create_tween().tween_property(_rays, "col", Color(TIER_COL[tier]).lightened(0.25), 0.15)
	Sfx.play("click", 1.6, -8.0)
	Juice.haptic("tick")
	var w := _word
	var tw := w.create_tween()
	for i in 4:
		tw.tween_property(w, "modulate:a", 0.25, 0.07)
		tw.tween_property(w, "modulate:a", 0.95, 0.07)
	await tw.finished

## Patlamadan önce şişme: sandık büyür, parlar.
func _charge(target: int) -> void:
	if _rm:
		return
	var tw := _chest.create_tween().set_parallel()
	tw.tween_property(_chest, "scale", Vector2(1.16, 0.86), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_chest, "modulate", Color(1.35, 1.25, 1.1), 0.22)
	Sfx.play("click", 0.7 + target * 0.1, -4.0)
	await tw.finished

func _burst(target: int) -> void:
	var tier: String = Chest.TIERS[target]
	var col: Color = TIER_COL[tier]
	var big := target >= 2
	if not _granted:
		Chest.grant(r)
		_granted = true
		Fly.hold(_rewards)
	var vp := Ui.vp()
	_chest.texture = UiArt.tex("chest_open")
	var cw := _chest.size.x
	var ch := cw * 556.0 / 592.0
	var bottom := _chest_home.y + _chest.size.y
	_chest.size = Vector2(cw, ch)
	_chest.position = Vector2(_chest_home.x, bottom - ch)
	_chest_home = _chest.position
	_chest.pivot_offset = Vector2(cw / 2.0, ch)
	_chest.modulate = Color.WHITE
	var tw := _chest.create_tween()
	tw.tween_property(_chest, "scale", Vector2(0.86, 1.2), 0.07)
	tw.tween_property(_chest, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var flash := ColorRect.new()
	flash.color = Color(1, 0.98, 0.92, 0.95)
	flash.size = vp
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.45 if not big else 0.75).finished.connect(flash.queue_free)
	create_tween().tween_property(_rays, "alpha", 0.42 if not big else 0.6, 0.3)
	_rays.speed = 0.9
	Sfx.play("reward", 1.0, 0.0, 0.0)
	if big:
		Sfx.play("solve", 1.05, -3.0)
	Juice.haptic("heavy")
	_shake(0.55 if not big else 0.85)
	var mouth := _chest_home + Vector2(cw / 2.0, ch * 0.35)
	_fx.ring(mouth, cw * 0.55, Palette.CREAM, 14.0)
	_fx.sparks(mouth, 24 + target * 8, col.lightened(0.4), 900.0)
	_fx.confetti(Vector2(-20, vp.y * 0.6), 40 + target * 20, PI * 0.18, -PI * 0.32, 2000.0)
	_fx.confetti(Vector2(vp.x + 20, vp.y * 0.6), 40 + target * 20, PI * 0.18, -PI * 0.68, 2000.0)
	_shower(mouth, target)
	# Kademe yazısı yukarı kayıp hafif büyür.
	if _word:
		var wt := _word.create_tween()
		var wy := minf(_word.position.y - 30.0, _chest_home.y - _word.size.y * 0.92)
		wy = maxf(Ui.safe_top() + 20.0, wy)
		wt.tween_property(_word, "position:y", wy, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Ağızdan kavisle saçılan ödül ikonları (dekoratif; gerçek uçuş Topla'da).
func _shower(from: Vector2, target: int) -> void:
	if _rm:
		return
	var pool: Array = []
	for c in _rewards:
		for i in clampi(int(sqrt(float(int(_rewards[c])))) , 2, 7):
			pool.append(c)
	pool.shuffle()
	var vp := Ui.vp()
	for i in mini(pool.size(), 18 + target * 4):
		var c: String = pool[i]
		var s := TextureRect.new()
		s.texture = UiArt.tex(Ui.currency_icon(c))
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var sz := randf_range(70, 110)
		s.size = Vector2(sz, sz)
		s.pivot_offset = s.size / 2.0
		s.position = from - s.size / 2.0
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(s)
		var vx := randf_range(-760, 760)
		var vy := randf_range(-1900, -1100)
		var spin := randf_range(-9, 9)
		var t0 := i * 0.025
		var tw := s.create_tween()
		tw.tween_interval(t0)
		tw.tween_method(func(t: float) -> void:
			s.position = from - s.size / 2.0 + Vector2(vx * t, vy * t + 2600.0 * t * t)
			s.rotation = spin * t, 0.0, 1.4, 1.4)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.4).set_delay(1.0)
		tw.tween_callback(s.queue_free)

# ------------------------------------------------------------------ Kademe yazısı

func _set_word(text: String, step: int) -> void:
	var vp := Ui.vp()
	var fs := 200
	while fs > 70 and FabricWord.measure(text, fs).x > vp.x - 120:
		fs -= 6
	var old := _word
	if old and is_instance_valid(old):
		# Eskisi yassılarak çıkar.
		old.set_meta("dying", true)
		old.pivot_offset = old.size / 2.0
		var ot := old.create_tween().set_parallel()
		ot.tween_property(old, "scale", Vector2(1.35, 0.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ot.tween_property(old, "modulate:a", 0.0, 0.12)
		ot.chain().tween_callback(old.queue_free)
	var w := FabricWord.new()
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(w)
	w._build(text, fs, "")
	var y := _chest_home.y - fs * 1.55 - 40.0
	w.position = Vector2(vp.x / 2.0 - w.size.x / 2.0, maxf(Ui.safe_top() + 60.0, y))
	w.pivot_offset = w.size / 2.0
	w._play(999.0)   # süresiz; değişimde/patlamada biz yönetiriz
	_word = w

# ------------------------------------------------------------------ Kartlar ve butonlar

func _show_cards() -> void:
	var vp := Ui.vp()
	var keys: Array = []
	for c in ["coin", "hint", "gem", "key", "ticket", "energy"]:
		if int(_rewards.get(c, 0)) > 0:
			keys.append(c)
	for c in _rewards:
		if not c in keys and int(_rewards[c]) > 0:
			keys.append(c)
	var n := keys.size()
	var cw := minf(230.0, (vp.x - 80.0 - (n - 1) * 22.0) / maxf(1.0, n))
	var chh := cw * 0.95
	var total := n * cw + (n - 1) * 22.0
	var y := _chest_home.y + _chest.size.y + 50.0
	for i in n:
		var c: String = keys[i]
		var card := QuiltCard.new()
		card.fabric = [0, 3, 6, 9, 2, 5][i % 6]
		card.inner = 10
		card.radius = 36
		card.depth = 8
		card.size = Vector2(cw, chh)
		var to := Vector2(vp.x / 2.0 - total / 2.0 + i * (cw + 22.0), y)
		card.position = to
		card.pivot_offset = Vector2(cw / 2.0, chh)
		_root.add_child(card)
		var ic := Ui.icon(Ui.currency_icon(c), Vector2(cw * 0.5, cw * 0.5))
		ic.position = Vector2(cw * 0.25, chh * 0.1)
		card.add_child(ic)
		var l := Ui.label("+0", int(cw * 0.22), Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(0, chh * 0.6)
		l.size = Vector2(cw, chh * 0.3)
		card.add_child(l)
		card.set_meta("c", c)
		card.set_meta("label", l)
		_cards.append(card)
		# Yelpaze gibi açıl: sandığın ağzından fırlayıp yerine otur.
		var fan := (i - (n - 1) / 2.0) * 0.12
		if _rm:
			card.modulate.a = 0.0
			card.create_tween().tween_property(card, "modulate:a", 1.0, 0.15)
		else:
			card.position = _chest_home + _chest.size * Vector2(0.5, 0.3) - Vector2(cw / 2.0, chh)
			card.scale = Vector2(0.2, 0.2)
			card.rotation = fan * 3.0
			var tw := card.create_tween()
			tw.tween_interval(i * 0.12)
			tw.tween_callback(func() -> void:
				Sfx.play("place", 1.0 + i * 0.12, -6.0)
				Juice.haptic("light"))
			tw.set_parallel()
			tw.tween_property(card, "position", to, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "rotation", fan * 0.5, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var v := int(_rewards[c])
		get_tree().create_timer((0.2 if _rm else 0.3) + i * 0.12).timeout.connect(func() -> void:
			if is_instance_valid(l):
				_ticks.append(Ui.tick(l, 0, v, 0.8, "+%d")))
	_cards_shown = true

func _show_buttons() -> void:
	if _closing:
		return
	var vp := Ui.vp()
	var bw := minf(vp.x - 200.0, 760.0)
	var y := _cards[0].position.y + _cards[0].size.y + 50.0 if not _cards.is_empty() else vp.y * 0.75
	var collect := Ui.button(tr("chest.collect"), "sage", Vector2(bw, 150))
	collect.position = Vector2((vp.x - bw) / 2.0, y)
	_buttons.add_child(collect)
	collect.tapped.connect(func() -> void:
		collect.disabled = true
		_collect())
	Ui.pop_in(collect, 0.0, 0.6)
	if Ads.rewarded_ready():
		var dbl := Ui.button(tr("reward.double"), "mustard", Vector2(bw, 120))
		dbl.position = Vector2((vp.x - bw) / 2.0, y + 170)
		_buttons.add_child(dbl)
		Ui.pop_in(dbl, 0.1, 0.6)
		dbl.tapped.connect(func() -> void:
			dbl.disabled = true
			Ads.show_rewarded(func() -> void:
				Wallet.grant(_rewards, "ad_double")
				for k in _rewards:
					_rewards[k] = int(_rewards[k]) * 2
				Fly.hold(_rewards)
				for card in _cards:
					var cc: String = card.get_meta("c")
					Ui.tick(card.get_meta("label"), int(_rewards[cc]) / 2, int(_rewards[cc]), 0.6, "+%d")
					Ui.punch(card, 0.2)
				Sfx.play("reward")
				dbl.queue_free()))

## Kartlar çıktıktan sonra dokunuş: sayaçları hemen bitir.
func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch and e.pressed) and not (e is InputEventMouseButton and e.pressed):
		return
	if not _cards_shown:
		return
	for tw in _ticks:
		if tw and tw.is_valid() and tw.is_running():
			tw.custom_step(5.0)

func _collect() -> void:
	if _closing:
		return
	_closing = true
	for tw in _ticks:
		if tw and tw.is_valid() and tw.is_running():
			tw.custom_step(5.0)
	for card in _cards:
		var c: String = card.get_meta("c")
		Fly.currency(card.global_position + card.size / 2.0, c, int(_rewards[c]))
		Ui.punch(card, 0.15)
	var tw := create_tween()
	tw.tween_interval(0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		if on_done.is_valid():
			on_done.call()
		_layer.queue_free())

# ------------------------------------------------------------------ Zemin

## Dikişli yorgan zemin: koyulaştırılmış kumaş kareler, kesik dikişler, yavaş kayma, keçe pırıltıları.
class QuiltBg extends Control:
	const CELL := 220.0
	var _t := 0.0
	var _tint := Color(0.56, 0.65, 0.48)
	var _motes: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 26:
			_motes.append({p = Vector2(randf() * size.x, randf() * size.y), v = randf_range(30, 90), s = randf_range(5, 13),
				ph = randf() * TAU, star = randf() < 0.4})

	func tint_to(c: Color, d: float) -> void:
		create_tween().tween_property(self, "_tint", c, d)

	func _process(dt: float) -> void:
		_t += dt * (0.0 if Ui.reduce_motion() else 1.0)
		for m in _motes:
			m.p.y -= m.v * dt
			m.p.x += sin(_t * 1.3 + m.ph) * 14.0 * dt
			if m.p.y < -20:
				m.p = Vector2(randf() * size.x, size.y + 20)
		queue_redraw()

	func _draw() -> void:
		var off := Vector2(fmod(_t * 14.0, CELL), fmod(_t * 9.0, CELL))
		var cols := int(ceil(size.x / CELL)) + 2
		var rows := int(ceil(size.y / CELL)) + 2
		var shade := Color(0.42, 0.33, 0.28).lerp(_tint.darkened(0.35), 0.35)
		for y in rows:
			for x in cols:
				var rect := Rect2(Vector2(x - 1, y - 1) * CELL + off, Vector2(CELL, CELL))
				var tex := Fabrics.get_tex((x * 7 + y * 3) % 12)
				if tex:
					draw_texture_rect(tex, rect, true, shade)
				else:
					draw_rect(rect, Palette.piece(x + y).darkened(0.5))
		var stitch := Color(Palette.CREAM, 0.35)
		for x in cols + 1:
			var px := (x - 1) * CELL + off.x
			draw_dashed_line(Vector2(px, 0), Vector2(px, size.y), stitch, 3.0, 14.0)
		for y in rows + 1:
			var py := (y - 1) * CELL + off.y
			draw_dashed_line(Vector2(0, py), Vector2(size.x, py), stitch, 3.0, 14.0)
		for m in _motes:
			var a := 0.35 + 0.35 * sin(_t * 3.0 + m.ph)
			var c := Color(Palette.CREAM, a)
			if m.star:
				var s: float = m.s * 1.6
				draw_line(m.p - Vector2(s, 0), m.p + Vector2(s, 0), c, 3.0)
				draw_line(m.p - Vector2(0, s), m.p + Vector2(0, s), c, 3.0)
			else:
				draw_circle(m.p, m.s * 0.6, c)
