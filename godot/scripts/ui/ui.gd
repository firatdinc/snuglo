class_name Ui
extends RefCounted
## Kod-tabanlı ekranlar için ortak UI kiti: etiket, ikon, kumaş butonlar, giriş animasyonları,
## sayaçlar, güvenli alan. Renkler yalnız Palette; dokular UiArt/PackArt.

const FONT := preload("res://art/fonts/fredoka_bold.tres")
## Masaüstü önizlemede uzun ekranlarda (en/boy > 1.9) çentik simülasyonu (piksel, 1080 genişlikte).
const SIM_TOP := 130.0
const SIM_BOTTOM := 70.0

static func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

static func vp() -> Vector2:
	return tree().root.get_visible_rect().size

static func reduce_motion() -> bool:
	return Settings.reduce_motion

## Güvenli alan: {top, bottom} viewport pikseli. iOS'ta DisplayServer; masaüstünde uzun
## oranlarda iPhone benzeri simülasyon (SNUG_NOTCH=0 kapatır).
static func insets() -> Dictionary:
	var v := vp()
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var scr := Vector2(DisplayServer.screen_get_size())
		if scr.y > 0 and safe.size.y > 0:
			var k := v.y / scr.y
			return {"top": safe.position.y * k, "bottom": maxf(0.0, (scr.y - safe.end.y) * k)}
	if OS.get_environment("SNUG_NOTCH") == "0":
		return {"top": 0.0, "bottom": 0.0}
	if v.y / v.x > 1.9:
		return {"top": SIM_TOP, "bottom": SIM_BOTTOM}
	return {"top": 0.0, "bottom": 0.0}

static func safe_top() -> float:
	return float(insets().top)

static func safe_bottom() -> float:
	return float(insets().bottom)

## İçerik sütunu: geniş ekranlarda (iPad) ortalanmış en çok 1080 px.
static func col_w() -> float:
	return minf(vp().x, 1080.0)

static func col_x() -> float:
	return (vp().x - col_w()) / 2.0

# ------------------------------------------------------------------ Yapı taşları

static func label(text: String, fs := 40, col := Palette.INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Görsel üstünde okunur başlık: koyu kahve kontur + yumuşak gölge.
static func title(text: String, fs := 64, col := Palette.CREAM, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, fs, col, align)
	l.add_theme_color_override("font_outline_color", Palette.INK)
	l.add_theme_constant_override("outline_size", maxi(6, fs / 6))
	l.add_theme_color_override("font_shadow_color", Color(Palette.INK, 0.45))
	l.add_theme_constant_override("shadow_offset_y", maxi(3, fs / 14))
	l.add_theme_constant_override("shadow_offset_x", 0)
	return l

## Metni max_w genişliğe sığdıran en büyük font boyutu (fs'ten min_fs'e iner; kontür payı dahil).
static func fit_font(text: String, fs: int, max_w: float, min_fs := 16) -> int:
	var f := fs
	while f > min_fs and FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x + maxi(6, f / 6) * 2 > max_w:
		f -= 1
	return f

static func wrap(l: Label, w: float) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = w
	l.size.x = w
	return l

static func place(c: Control, pos: Vector2, sz: Vector2) -> Control:
	c.position = pos
	c.size = sz
	return c

static func icon(name: String, sz: Vector2, dir := "ui") -> TextureRect:
	var t := TextureRect.new()
	t.texture = UiArt.tex(name, dir)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size = sz
	t.pivot_offset = sz / 2.0
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func tex_rect(tex: Texture2D, sz: Vector2, cover := false) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size = sz
	t.pivot_offset = sz / 2.0
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

## Kumaş hap buton. skin: terracotta | sage | mustard | square.
static func button(text: String, skin := "terracotta", sz := Vector2(600, 150), icon_name := "", fs := 0) -> JuicyButton:
	var b := JuicyButton.new()
	b.text = text
	b.skin = UiArt.tex("btn_" + skin)
	b.color = {"terracotta": Palette.TERRACOTTA, "sage": Palette.SAGE, "mustard": Palette.MUSTARD}.get(skin, Palette.CARD)
	if icon_name != "":
		b.icon = UiArt.tex(icon_name)
	b.font_size = fs if fs > 0 else int(sz.y * 0.36)
	b.size = sz
	return b

## Kare yastık üzerinde ikon buton.
static func icon_button(icon_name: String, side := 120.0) -> JuicyButton:
	var b := JuicyButton.new()
	b.skin = UiArt.tex("btn_square")
	b.icon = UiArt.tex(icon_name)
	b.icon_scale = 0.66
	b.size = Vector2(side, side)
	return b

## Yuvarlak köşeli dikdörtgen poligonu.
static func rrect(r: Rect2, rad: float, seg := 6) -> PackedVector2Array:
	rad = minf(rad, minf(r.size.x, r.size.y) / 2.0)
	var pts := PackedVector2Array()
	var cs := [r.position + Vector2(rad, rad), Vector2(r.end.x - rad, r.position.y + rad), r.end - Vector2(rad, rad), Vector2(r.position.x + rad, r.end.y - rad)]
	for k in 4:
		for i in seg + 1:
			var a := PI + k * PI / 2.0 + i * (PI / 2.0) / seg
			var q: Vector2 = cs[k] + Vector2(cos(a), sin(a)) * rad
			if pts.is_empty() or pts[pts.size() - 1].distance_to(q) > 0.5:
				pts.append(q)
	if pts.size() > 2 and pts[0].distance_to(pts[pts.size() - 1]) <= 0.5:
		pts.resize(pts.size() - 1)
	return pts

## Dikişli rozet sayısı (kırmızı-turuncu kumaş damla).
static func badge(text: String, col := Palette.BAD) -> Control:
	var b := Badge.new()
	b.text = text
	b.col = col
	return b

# ------------------------------------------------------------------ Hareket

## Yaylanarak belir (TRANS_BACK). from: başlangıç ölçeği.
static func pop_in(n: CanvasItem, delay := 0.0, from := 0.5, dur := 0.42) -> Tween:
	if n is Control:
		(n as Control).pivot_offset = (n as Control).size / 2.0
	n.scale = Vector2(from, from)
	n.modulate.a = 0.0
	var tw := n.create_tween().set_parallel()
	if reduce_motion():
		n.scale = Vector2.ONE
		tw.tween_property(n, "modulate:a", 1.0, 0.2).set_delay(delay * 0.5)
		return tw
	tw.tween_property(n, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(n, "modulate:a", 1.0, 0.14).set_delay(delay)
	return tw

## Aşağıdan kayarak gel.
static func slide_in(n: Control, delay := 0.0, dy := 80.0) -> Tween:
	var to := n.position
	n.position = to + Vector2(0, dy)
	n.modulate.a = 0.0
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "position", to, 0.5 if not reduce_motion() else 0.01).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(n, "modulate:a", 1.0, 0.2).set_delay(delay)
	return tw

## Sıra ile belirme.
static func stagger(nodes: Array, step := 0.05, start := 0.0) -> void:
	var i := 0
	for n in nodes:
		if is_instance_valid(n):
			pop_in(n, start + i * step, 0.7)
		i += 1

## Sonsuz hafif süzülme (y ekseni, faz ile).
static func bob(n: CanvasItem, amp := 10.0, period := 2.4, phase := 0.0) -> void:
	if reduce_motion():
		return
	var b := Bobber.new()
	b.amp = amp
	b.period = period
	b.phase = phase
	n.add_child(b)

## Tek seferlik "punch": hızlı büyü + yaylan.
static func punch(n: CanvasItem, amount := 0.18) -> void:
	if n is Control:
		(n as Control).pivot_offset = (n as Control).size / 2.0
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector2.ONE * (1.0 + amount), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Sallanma (reddetme / dikkat).
static func shake(n: Control, amount := 14.0) -> void:
	var x := n.position.x
	var tw := n.create_tween()
	for i in 4:
		tw.tween_property(n, "position:x", x + amount * (1.0 if i % 2 == 0 else -1.0) * (1.0 - i * 0.22), 0.05)
	tw.tween_property(n, "position:x", x, 0.06)

## Sayı sayarak artır: label.text = fmt % değer.
static func tick(l: Label, from: int, to: int, dur := 0.8, fmt := "%d", sound := true) -> Tween:
	var tw := l.create_tween()
	var last := [from]
	tw.tween_method(func(v: float) -> void:
		var iv := int(round(v))
		l.text = fmt % iv
		if sound and iv != last[0] and iv % maxi(1, absi(to - from) / 12) == 0:
			Sfx.play("click", 1.6 + randf() * 0.3, -18.0, 0.0)
		last[0] = iv, float(from), float(to), dur if not reduce_motion() else 0.05).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return tw

static func fmt_time(sec: float) -> String:
	var s := maxi(0, int(sec))
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]

## 12 345 → "12.3K" kısaltması (üst bar).
static func short_num(n: int) -> String:
	if n >= 100000:
		return "%dK" % (n / 1000)
	if n >= 10000:
		return "%.1fK" % (n / 1000.0)
	return str(n)

## Para birimi → ikon adı.
static func currency_icon(c: String) -> String:
	return {"coin": "coin", "gem": "ic_gem", "hint": "ic_hint", "key": "ic_key", "ticket": "ic_ticket",
		"cup": "ic_cup", "energy": "ic_energy", "xp": "ic_star"}.get(c, "coin")

## UTC gece yarısına kalan saniye (günlük yenileme).
static func seconds_to_utc_midnight() -> int:
	var now := int(Time.get_unix_time_from_system())
	return 86400 - now % 86400

## Kurdele başlık: art/ui/banner.png yatay 3-dilim (uçlar ~150 px) + kontürlü krem yazı.
static func banner(text: String, w := 640.0, h := 140.0) -> Control:
	var b := Ribbon.new()
	# Uzun başlık (es/tr): önce kurdele uzar (en çok %35), sonra yazı küçülür — "…" ile kesilmesin.
	var fs := int(h * 0.38)
	var need := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + maxi(6, fs / 6) * 2 + h * 1.8
	if need > w:
		w = minf(need + 8.0, w * 1.35)
	fs = fit_font(text, fs, w - h * 1.8, 30)
	b.size = Vector2(w, h)
	var l := title(text, fs, Palette.CREAM)
	l.position = Vector2(h * 0.9, h * 0.04)
	l.size = Vector2(w - h * 1.8, h * 0.7)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.add_child(l)
	return b

class Ribbon extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var t := UiArt.tex("banner")
		if t == null:
			draw_colored_polygon(Ui.rrect(Rect2(Vector2.ZERO, size * Vector2(1, 0.8)), 20), Palette.TERRACOTTA)
			return
		var th := float(t.get_height())
		var k := size.y / th
		var cap := 150.0
		var capw := cap * k
		draw_texture_rect_region(t, Rect2(Vector2.ZERO, Vector2(capw, size.y)), Rect2(0, 0, cap, th))
		draw_texture_rect_region(t, Rect2(Vector2(size.x - capw, 0), Vector2(capw, size.y)), Rect2(t.get_width() - cap, 0, cap, th))
		draw_texture_rect_region(t, Rect2(Vector2(capw - 1, 0), Vector2(size.x - capw * 2 + 2, size.y)), Rect2(cap, 0, t.get_width() - cap * 2, th))
