class_name XmasKit
extends RefCounted
## Noel mini oyunlarının ortak araçları: keçe kar yağışı, ASMR sesi, kutlama, poster paylaşımı.

## ASMR sesi: dosya varsa onu, yoksa yedeği çalar; her seferinde hafif perde/ses farkı.
static func asmr(name: String, fallback := "place", pitch := 1.0, vol_db := 0.0) -> void:
	if Settings.get_value("asmr") == false:
		Sfx.play(fallback, pitch, vol_db - 6.0)
		return
	if Sfx.has_sound(name):
		Sfx.play(name, pitch, vol_db, 0.08)
	else:
		Sfx.play(fallback, pitch, vol_db)

## Buton/kart üst kenarına yığılmış keçe kar kümesi. r: çizilen yüzey, seed: düğüme özgü
## (her butonda farklı ama sabit biçim). Yalnız Noel açıkken çağırın.
static var _cap_tex := {}

static func _cap(name: String) -> Texture2D:
	if not _cap_tex.has(name):
		var p := "res://art/xmas/snow_cap_%s.png" % name
		_cap_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _cap_tex[name]

static func draw_snow_cap(ci: CanvasItem, r: Rect2, seed_i: int, rad := 36.0) -> void:
	# ChatGPT keçe kar parçaları varsa: kare/küçük öğe → tek parça "round"; geniş → sol+orta(döşe)+sağ.
	var L := _cap("left")
	var M := _cap("mid")
	var R := _cap("right")
	var O := _cap("round")
	var ch := clampf(r.size.y * 0.42, 22.0, 70.0)
	if O and r.size.x <= 220.0 and r.size.x <= r.size.y * 1.4:   # yalnız küçük kare ikon butonlar
		var sz := Vector2(r.size.x * 1.06, r.size.x * 1.06 * O.get_height() / float(O.get_width()))
		ci.draw_texture_rect(O, Rect2(Vector2(r.position.x - r.size.x * 0.03, r.position.y - sz.y * 0.32), sz), false)
		return
	if L and M and R:
		var k := ch / float(M.get_height())
		var lw := L.get_width() * k
		var rw := R.get_width() * k
		var y := r.position.y - ch * 0.32
		var x0 := r.position.x - ch * 0.06
		var x1 := r.end.x + ch * 0.06
		if x1 - x0 < lw + rw:
			var s := (x1 - x0) / (lw + rw)
			lw *= s
			rw *= s
		# Orta parça uçların yumuşatılmış iç kenarının ALTINDAN geçer → dikiş görünmez.
		var mw := M.get_width() * k
		var ms := x0 + lw * 0.68
		var me := x1 - rw * 0.68
		var x := ms
		while x < me - 0.5:
			var w := minf(mw, me - x)
			ci.draw_texture_rect_region(M, Rect2(x, y, w, ch), Rect2(0, 0, w / k, M.get_height()))
			x += w
		ci.draw_texture_rect(L, Rect2(x0, y, lw, L.get_height() * k), false)
		ci.draw_texture_rect(R, Rect2(x1 - rw, y, rw, R.get_height() * k), false)
		return
	# Keçe kar parçaları henüz yoksa hiç çizme (görsel konsept: yalnız ChatGPT kumaş dokuları).
	return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var w := r.size.x
	var h := clampf(r.size.y * 0.22, 10.0, 34.0)
	var inset := minf(rad * 0.55, w * 0.18)
	var x0 := r.position.x + inset * 0.4
	var x1 := r.end.x - inset * 0.4
	var y := r.position.y + 2.0
	# Kar gövdesi: üstte tümsekli, altta damlayan dalgalı kenar.
	var top := PackedVector2Array()
	var bumps := maxi(3, int((x1 - x0) / maxf(h * 1.6, 18.0)))
	for i in bumps + 1:
		var t := float(i) / bumps
		var x := lerpf(x0, x1, t)
		var lift := h * (0.55 + rng.randf() * 0.45) * sin(PI * clampf(t * 1.08 - 0.04, 0.0, 1.0)) ** 0.35
		top.append(Vector2(x, y - lift))
	var bot := PackedVector2Array()
	var drips := bumps * 2
	for i in range(drips, -1, -1):
		var t := float(i) / drips
		var x := lerpf(x0, x1, t)
		var d := h * (0.25 + (0.55 * rng.randf() if i % 2 == 0 else 0.1))
		bot.append(Vector2(x, y + d))
	var poly := top + bot
	var smooth := Geometry2D.offset_polygon(poly, h * 0.18, Geometry2D.JOIN_ROUND)
	if smooth.is_empty():
		return
	var body: PackedVector2Array = smooth[0]
	ci.draw_set_transform(Vector2(0, 3), 0.0, Vector2.ONE)
	ci.draw_colored_polygon(body, Color(0.25, 0.3, 0.4, 0.18))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_colored_polygon(body, Color(0.97, 0.98, 1.0))
	# Gölge alt kenar + parıltı noktaları (keçe dokusu hissi).
	var ring := body.duplicate()
	ring.append(body[0])
	ci.draw_polyline(ring, Color(0.72, 0.8, 0.9, 0.9), maxf(1.5, h * 0.08), true)
	for i in maxi(2, bumps / 2):
		var px := lerpf(x0 + h, x1 - h, rng.randf())
		ci.draw_circle(Vector2(px, y - h * 0.25 * rng.randf()), maxf(1.5, h * 0.09), Color(1, 1, 1, 0.95))

## Düğümün üstüne kar kümesi çocuğu ekler (kendi _draw'ı olmayan/erken dönen kartlar için).
static func cap(n: Control, rad := 36.0) -> void:
	var c := SnowCap.new()
	c.rad = rad
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

class SnowCap extends Control:
	var rad := 36.0
	func _ready() -> void:
		resized.connect(queue_redraw)
	func _draw() -> void:
		if size.x >= 80.0:
			XmasKit.draw_snow_cap(self, Rect2(Vector2.ZERO, size), get_parent().get_instance_id() % 9973, rad)

## Görünümün üstüne keçe kar tanesi katmanı ekler.
static func add_snow(parent: Control, count := 40, front := true) -> Snow:
	var s := Snow.new()
	s.count = count
	s.size = parent.size
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(s)
	if not front:
		parent.move_child(s, 0)
	return s

## Bitiş kutlaması: konfeti + ödül sesi + titreşim.
static func celebrate(node: Control, at: Vector2) -> void:
	Sfx.play("reward")
	asmr("jingle", "levelUp")
	Juice.haptic("success")
	var fx := Fx.new()
	node.add_child(fx)
	fx.confetti(at, 90)
	node.get_tree().create_timer(4.0).timeout.connect(fx.queue_free)

## Node'un o anki görüntüsünü (alt dikdörtgen) paylaş.
static func share_node(node: Control, rect: Rect2, text_key: String) -> void:
	await RenderingServer.frame_post_draw
	var img := node.get_viewport().get_texture().get_image()
	if img:
		var k := float(img.get_width()) / node.get_viewport_rect().size.x
		var r := Rect2i(Vector2i(rect.position * k), Vector2i(rect.size * k)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		if r.size.x > 0 and r.size.y > 0:
			img = img.get_region(r)
	Share.share_image(node, img, TranslationServer.translate(text_key))


## Yavaşça süzülen, salınan keçe kar taneleri (yuvarlak + dikiş halkası).
class Snow extends Control:
	var count := 40
	var _f: Array = []
	var _tex: Array = []
	func _ready() -> void:
		for i in 6:
			var p := "res://art/xmas/flake_%d.png" % i
			if ResourceLoader.exists(p):
				_tex.append(load(p))
		for i in count:
			_f.append(_spawn(true))
	func _spawn(anywhere: bool) -> Dictionary:
		return {"p": Vector2(randf() * size.x, randf() * size.y if anywhere else -30.0),
			"r": randf_range(6.0, 16.0), "v": randf_range(40.0, 110.0), "ph": randf() * TAU,
			"a": randf_range(0.7, 1.0), "t": randi() % 6, "rot": randf() * TAU, "spin": randf_range(-0.6, 0.6)}
	func _process(dt: float) -> void:
		if Ui.reduce_motion():
			return
		for i in _f.size():
			var f: Dictionary = _f[i]
			f.ph += dt * 1.3
			f.p += Vector2(sin(f.ph) * 22.0 * dt, f.v * dt)
			f.rot += f.spin * dt
			if f.p.y > size.y + 30.0:
				_f[i] = _spawn(false)
		queue_redraw()
	func _draw() -> void:
		if not _tex.is_empty():
			for f: Dictionary in _f:
				var t: Texture2D = _tex[int(f.t) % _tex.size()]
				var d: float = f.r * 2.6
				draw_set_transform(f.p, f.rot, Vector2.ONE)
				draw_texture_rect(t, Rect2(-d / 2.0, -d / 2.0, d, d), false, Color(1, 1, 1, f.a))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		for f: Dictionary in _f:
			draw_circle(f.p + Vector2(0, f.r * 0.25), f.r, Color(0.3, 0.2, 0.15, 0.12 * f.a))
			draw_circle(f.p, f.r, Color(1, 1, 1, f.a))
			if f.r > 10.0:
				draw_arc(f.p, f.r * 0.62, 0, TAU, 14, Color(0.78, 0.86, 0.93, f.a), 1.5)
