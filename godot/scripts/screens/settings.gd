extends Screen
## Ayarlar (Swift SettingsView): Ses & His, Oynanış, Görünüm (kumaş seti + tahta), Bildirimler
## (yalnız destekleniyorsa), Dil (canlı), Hesap (yedek/taşı, geri yükle, gizlilik, destek, sıfırla),
## Hakkında. Her bölüm dikişli kart; satırlar kumaş anahtar / kaydırıcı / bölmeli seçim.

const PRIVACY_URL := "https://felabs.app/privacy"
const SUPPORT_URL := "https://felabs.app/"
const ROW := 116.0

var _scroll: DragScroll
var _y := 0.0
var _cw := 0.0
var _card: QuiltCard
var _cy := 0.0

func build() -> void:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name("forest")
	bg.wash_top = 0.85
	bg.wash_bottom = 0.95
	bg.motes = 8
	bg.size = size
	add_child(bg)
	var top := header("settings.title")
	_scroll = DragScroll.new()
	put(_scroll, Vector2(X0, top), Vector2(W, H - top))
	_cw = W - 80
	_y = 10.0

	_begin("settings.sound.title", "ic_sound")
	_toggle_row("settings.sound.music", Settings.music_enabled, func(on: bool) -> void: Settings.music_enabled = on)
	_slider_row("settings.sound.volume", Settings.music_volume, func(v: float) -> void: Settings.music_volume = v)
	_segment_row("settings.sound.track", ["auto", "calm", "zen"], "settings.sound.track.", Settings.music_track, func(v: String) -> void: Settings.music_track = v)
	_toggle_row("settings.sound.effects", Settings.sfx_enabled, func(on: bool) -> void: Settings.sfx_enabled = on)
	_slider_row("settings.sound.volume", Settings.sfx_volume, func(v: float) -> void:
		Settings.sfx_volume = v, func() -> void: Sfx.play("place", 1.2, 0.0))
	_preview_row()
	_toggle_row("settings.haptics.enable", Settings.haptics, func(on: bool) -> void:
		Settings.haptics = on
		Juice.haptic("medium"))
	_segment_row("haptic.strength", ["full", "light"], "haptic.", String(Settings.get_value("haptic_level")), func(v: String) -> void: Settings.set_value("haptic_level", v))
	_end()

	_begin("settings.gameplay.title", "ic_zen")
	_toggle_row("settings.gameplay.zen", Settings.zen_mode, func(on: bool) -> void: Settings.zen_mode = on, "settings.gameplay.zenFooter")
	_toggle_row("settings.gameplay.reduceMotion", Settings.reduce_motion, func(on: bool) -> void: Settings.reduce_motion = on)
	_toggle_row("settings.gameplay.colorblind", bool(Settings.get_value("colorblind")), func(on: bool) -> void: Settings.set_value("colorblind", on))
	_freeze_row()
	_end()

	_begin("settings.appearance.title", "ic_star")
	_fabrics()
	_boards()
	_end()

	if Notify.is_supported():
		_begin("settings.notifications.title", "ic_calendar")
		_toggle_row("settings.notifications.reminder", Settings.daily_reminder, func(on: bool) -> void:
			if on:
				Notify.request_permission(func(ok: bool) -> void:
					Settings.daily_reminder = ok
					if not ok:
						Main.toast(tr("notif.disabled.title"), "ic_sound", Palette.TERRACOTTA))
			else:
				Settings.daily_reminder = false)
		_toggle_row("settings.notifications.comeback", Settings.comeback_reminders, func(on: bool) -> void: Settings.comeback_reminders = on)
		_end()

	_begin("settings.language.title", "ic_hint")
	_segment_row("", ["", "en", "tr", "es"], "", Settings.language, func(v: String) -> void:
		Settings.language = v
		Main.replace("settings", {}, "none"), {"": tr("settings.language.system"), "en": "English", "tr": "Türkçe", "es": "Español"})
	_end()

	_begin("settings.account.title", "ic_key")
	_link_row("settings.account.transfer", func() -> void: Main.open("transfer"))
	_link_row("settings.account.restore", func() -> void: Purchases.restore())
	_link_row("settings.account.privacy", func() -> void: OS.shell_open(PRIVACY_URL))
	_link_row("settings.account.support", func() -> void: OS.shell_open(SUPPORT_URL))
	_link_row("settings.account.reset", func() -> void:
		Main.confirm(tr("settings.account.resetTitle"), tr("settings.account.resetMessage"), tr("settings.account.resetAction"), func() -> void:
			Save.reset_all()
			Energy.reset()
			Main.goto("splash"), true), true)
	_end()

	_about()
	_scroll.set_length(_y + BOTTOM + 60)
	var ds := Dev.env("SNUG_SCROLL")
	if ds != "":
		_scroll.scroll_to(float(ds), false)

# ------------------------------------------------------------------ Bölüm kartı

func _begin(key: String, icon: String) -> void:
	_y += 20
	var ic := Ui.icon(icon, Vector2(76, 76))
	ic.position = Vector2(48, _y)
	_scroll.content.add_child(ic)
	var t := Ui.title(tr(key), 48, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	Ui.place(t, Vector2(136, _y + 6), Vector2(_cw - 120, 64))
	_scroll.content.add_child(t)
	_y += 90
	_card = QuiltCard.new()
	_card.fill = Palette.CARD
	_card.radius = 44
	_card.position = Vector2(40, _y)
	_card.size = Vector2(_cw, 100)
	_scroll.content.add_child(_card)
	Ui.pop_in(_card, minf(_y / 5000.0, 0.3), 0.9)
	_cy = 22.0

func _end() -> void:
	_card.size.y = _cy + 22
	_y += _card.size.y + 10

func _sep() -> void:
	if _cy > 30:
		var d := Divider.new()
		Ui.place(d, Vector2(40, _cy - 2), Vector2(_cw - 80, 4))
		_card.add_child(d)

func _row_label(key: String, h := ROW) -> Label:
	var l := Ui.label(tr(key), 38, Palette.INK)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(l, Vector2(44, _cy), Vector2(_cw * 0.55, h))
	_card.add_child(l)
	return l

func _toggle_row(key: String, on: bool, cb: Callable, footer := "") -> void:
	_sep()
	_row_label(key)
	var tg := Widgets.Toggle.new()
	tg.on = on
	Ui.place(tg, Vector2(_cw - 180, _cy + (ROW - 64) / 2.0), Vector2(136, 64))
	_card.add_child(tg)
	tg.toggled.connect(cb)
	_cy += ROW
	if footer != "":
		# Çok satırlı açıklama: satır sayısı kadar yer aç (es/tr uzun).
		var fw := _cw - 100
		var lines := maxi(1, roundi(Ui.FONT.get_multiline_string_size(tr(footer), HORIZONTAL_ALIGNMENT_LEFT, fw, 28).y / Ui.FONT.get_height(28)))
		var lh := Ui.FONT.get_height(28)
		var f := Ui.wrap(Ui.label(tr(footer), 28, Palette.INK_SOFT), fw)
		f.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		Ui.place(f, Vector2(44, _cy - 22), Vector2(fw, lines * lh + 4))
		_card.add_child(f)
		_cy += 30 + (lines - 1) * lh + 6

func _slider_row(key: String, v: float, cb: Callable, on_release := Callable()) -> void:
	_sep()
	var l := _row_label(key)
	l.size.x = _cw * 0.3
	l.add_theme_color_override("font_color", Palette.INK_SOFT)
	var s := FabricSlider.new()
	s.value = v
	Ui.place(s, Vector2(_cw * 0.36, _cy + (ROW - 70) / 2.0), Vector2(_cw * 0.64 - 44, 70))
	_card.add_child(s)
	s.changed.connect(cb)
	if on_release.is_valid():
		s.released.connect(on_release)
	_cy += ROW

## Bölmeli seçim. labels: değer → metin (yoksa tr(prefix+değer)).
func _segment_row(key: String, values: Array, prefix: String, current: String, cb: Callable, labels := {}) -> void:
	_sep()
	var x0 := 44.0
	if key != "":
		_row_label(key, ROW)
		_cy += ROW - 10
	var n := values.size()
	var gap := 14.0
	var w := (_cw - x0 * 2 - gap * (n - 1)) / n
	var cells: Array[QuiltCard] = []
	for i in n:
		var v: String = values[i]
		var c := QuiltCard.new()
		c.pressable = true
		c.fill = Palette.MUSTARD if v == current else Palette.CREAM
		c.radius = 36
		c.depth = 6
		Ui.place(c, Vector2(x0 + i * (w + gap), _cy + 6), Vector2(w, 82))
		_card.add_child(c)
		var t := Ui.label(labels.get(v, tr(prefix + v)), 32, Palette.CREAM if v == current else Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		Ui.place(t, Vector2(8, 0), Vector2(w - 16, 82))
		c.add_child(t)
		cells.append(c)
		c.tapped.connect(func() -> void:
			for k in cells.size():
				var sel := k == i
				cells[k].fill = Palette.MUSTARD if sel else Palette.CREAM
				(cells[k].get_child(0) as Label).add_theme_color_override("font_color", Palette.CREAM if sel else Palette.INK)
				cells[k].queue_redraw()
			Ui.punch(c, 0.12)
			cb.call(v))
	_cy += 104

func _preview_row() -> void:
	_sep()
	var names := ["place", "snap", "solve", "reward", "error"]
	var gap := 12.0
	var w := (_cw - 88 - gap * (names.size() - 1)) / names.size()
	var l := Ui.label(tr("settings.sound.preview"), 30, Palette.INK_SOFT)
	Ui.place(l, Vector2(44, _cy + 6), Vector2(_cw - 88, 44))
	_card.add_child(l)
	for i in names.size():
		var n: String = names[i]
		var b := QuiltCard.new()
		b.pressable = true
		b.fabric = [0, 3, 2, 1, 4][i]
		b.radius = 30
		b.depth = 6
		Ui.place(b, Vector2(44 + i * (w + gap), _cy + 56), Vector2(w, 70))
		_card.add_child(b)
		var ic := Ui.icon("ic_sound", Vector2(52, 52))
		Ui.place(ic, Vector2((w - 52) / 2.0, 9), ic.size)
		b.add_child(ic)
		b.tapped.connect(func() -> void:
			Sfx.play(n)
			Ui.punch(ic, 0.3))
	_cy += 140

func _freeze_row() -> void:
	_sep()
	var l := _row_label("freeze.title", 70)
	l.size.y = 70
	var held := Ui.label(tr("freeze.held") % Progress.streak_freezes, 28, Palette.INK_SOFT)
	Ui.place(held, Vector2(44, _cy + 58), Vector2(_cw * 0.6, 44))
	_card.add_child(held)
	var b := Ui.button("%d" % Progress.FREEZE_COST_GEMS, "mustard", Vector2(190, 90), "ic_gem", 40)
	Ui.place(b, Vector2(_cw - 234, _cy + 14), b.size)
	_card.add_child(b)
	b.tapped.connect(func() -> void:
		if Progress.buy_streak_freeze():
			held.text = tr("freeze.held") % Progress.streak_freezes
			Ui.punch(held, 0.2)
			Sfx.play("reward", 1.2, -4.0)
			Main.toast(tr("freeze.title") + " +1", "ic_heart", Palette.SAGE)
		else:
			Ui.shake(b)
			Sfx.play("error")
			Main.toast(tr("toast.wallet.insufficient") % tr("currency.gem"), "ic_gem", Palette.TERRACOTTA))
	_cy += 120

## Kumaş seti seçici: yatay kaydırmalı dikişli numuneler.
func _fabrics() -> void:
	_sep()
	var l := _row_label("fabric.title", 70)
	l.size.y = 70
	_cy += 70
	var strip := DragScroll.new()
	strip.horizontal = true
	Ui.place(strip, Vector2(20, _cy), Vector2(_cw - 40, 230))
	_card.add_child(strip)
	var list := Cosmetics.fabrics()
	var sw := 180.0
	for i in list.size():
		var f: Dictionary = list[i]
		var c := QuiltCard.new()
		c.pressable = true
		c.fabric = (i * 3) % 12
		c.locked = not f.unlocked
		c.glow = f.selected
		c.radius = 34
		c.depth = 6
		Ui.place(c, Vector2(16 + i * (sw + 18), 10), Vector2(sw, 150))
		strip.content.add_child(c)
		if not f.unlocked:
			var lk := Ui.icon("ic_lock", Vector2(70, 70))
			Ui.place(lk, Vector2((sw - 70) / 2.0, 34), lk.size)
			c.add_child(lk)
		elif f.selected:
			var ck := Ui.title("✓", 64)
			Ui.place(ck, Vector2(0, 30), Vector2(sw, 90))
			c.add_child(ck)
		var cap := "%s" % tr(String(f.name))
		if not f.unlocked:
			cap = (tr("fabric.locked") % int(f.unlock_level)) if not f.premium else "%d %s" % [int(f.cost), tr("currency.gem")]
		var t := Ui.label(cap, 26, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		Ui.place(t, Vector2(16 + i * (sw + 18), 166), Vector2(sw, 44))
		strip.content.add_child(t)
		var id := String(f.id)
		c.tapped.connect(func() -> void:
			if Cosmetics.is_fabric_unlocked(id):
				Cosmetics.select_fabric(id)
				Main.replace("settings", {}, "none")
			else:
				var cost := Cosmetics.fabric_cost(Cosmetics._find(Cosmetics.FABRICS, id))
				Main.confirm(tr("fabric.title"), tr("fabric.buy") % cost, "%d" % cost, func() -> void:
					if Cosmetics.buy_fabric(id):
						Cosmetics.select_fabric(id)
						Sfx.play("reward")
						Main.replace("settings", {}, "none")
					else:
						Main.toast(tr("toast.wallet.insufficient") % tr("currency.gem"), "ic_gem", Palette.TERRACOTTA)))
	strip.set_length(16 + list.size() * (sw + 18))
	_cy += 236

func _boards() -> void:
	_sep()
	var l := _row_label("board.title", 70)
	l.size.y = 70
	_cy += 70
	var list := Cosmetics.boards()
	var cols := 3
	var gap := 14.0
	var w := (_cw - 88 - gap * (cols - 1)) / cols
	for i in list.size():
		var b: Dictionary = list[i]
		var c := QuiltCard.new()
		c.pressable = true
		c.fill = Palette.MUSTARD if b.selected else Palette.CREAM
		c.locked = not b.unlocked
		c.radius = 30
		c.depth = 5
		Ui.place(c, Vector2(44 + (i % cols) * (w + gap), _cy + (i / cols) * 92), Vector2(w, 78))
		_card.add_child(c)
		var cap := tr(String(b.name)) if b.unlocked else "%d" % int(b.cost)
		var t := Ui.label(cap, 28, Palette.CREAM if b.selected else Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		Ui.place(t, Vector2(10, 0), Vector2(w - 20, 78))
		c.add_child(t)
		if not b.unlocked:
			var g := Ui.icon("ic_gem", Vector2(54, 54))
			Ui.place(g, Vector2(w / 2.0 - 90, 12), g.size)
			c.add_child(g)
		var id := String(b.id)
		c.tapped.connect(func() -> void:
			if Cosmetics.is_board_unlocked(id):
				Cosmetics.select_board(id)
				Main.replace("settings", {}, "none")
			elif Cosmetics.buy_board(id):
				Cosmetics.select_board(id)
				Sfx.play("reward")
				Main.replace("settings", {}, "none")
			else:
				Ui.shake(c)
				Main.toast(tr("toast.wallet.insufficient") % tr("currency.gem"), "ic_gem", Palette.TERRACOTTA))
	_cy += ceili(list.size() / float(cols)) * 92 + 10

func _link_row(key: String, cb: Callable, danger := false) -> void:
	var hit := QuiltCard.new()
	hit.pressable = true
	hit.fill = Palette.CREAM
	hit.radius = 36
	hit.depth = 5
	hit.stitch = false
	Ui.place(hit, Vector2(28, _cy + 8), Vector2(_cw - 56, ROW - 16))
	_card.add_child(hit)
	var l := Ui.label(tr(key), 38, Palette.TERRACOTTA.darkened(0.1) if danger else Palette.INK)
	Ui.place(l, Vector2(24, 0), Vector2(_cw - 160, ROW - 8))
	hit.add_child(l)
	var ch := Ui.label("›", 60, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(ch, Vector2(_cw - 130, 0), Vector2(70, ROW - 8))
	hit.add_child(ch)
	hit.tapped.connect(cb)
	_cy += ROW

func _about() -> void:
	_y += 30
	var sloth := Ui.icon("sleep", Vector2(220, 205), "mascot")
	sloth.position = Vector2((W - 220) / 2.0, _y)
	_scroll.content.add_child(sloth)
	Ui.bob(sloth, 5.0, 3.0)
	_y += 210
	var v := str(ProjectSettings.get_setting("application/config/version", ""))
	if v == "" or v == "0":
		v = "dev"
	var f := Ui.label(tr("settings.about.footer") % v, 32, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(f, Vector2(0, _y), Vector2(W, 44))
	_scroll.content.add_child(f)
	_y += 46
	var c := Ui.label(tr("settings.about.credits"), 28, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(c, Vector2(0, _y), Vector2(W, 40))
	_scroll.content.add_child(c)
	_y += 60

class Divider extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_multiline(PieceShape.dashes(PackedVector2Array([Vector2(0, 2), Vector2(size.x, 2)]), 12, 8), Color(Palette.STITCH_DARK, 0.35), 2.5)

## Kumaş kaydırıcı: dikişli yuva + dolgu + yastık topuz. changed(v) sürekli, released() bırakınca.
class FabricSlider extends Control:
	signal changed(v: float)
	signal released
	var value := 0.5
	var _drag := false
	var _k := 1.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _gui_input(e: InputEvent) -> void:
		if e is InputEventScreenTouch:
			if e.pressed:
				_drag = true
				_set_from(e.position.x)
				create_tween().tween_property(self, "_k", 1.25, 0.12)
			elif _drag:
				_drag = false
				create_tween().tween_property(self, "_k", 1.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				released.emit()
			accept_event()
		elif e is InputEventScreenDrag and _drag:
			_set_from(e.position.x)
			accept_event()
	func _set_from(x: float) -> void:
		var h := size.y
		var v := clampf((x - h / 2.0) / maxf(1.0, size.x - h), 0.0, 1.0)
		v = snappedf(v, 0.05)
		if v != value:
			value = v
			Juice.haptic("tick")
			changed.emit(value)
		queue_redraw()
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var h := size.y
		var th := h * 0.36
		var tr_r := Rect2(Vector2(h / 2.0 - th / 2.0, (h - th) / 2.0), Vector2(size.x - h + th, th))
		draw_colored_polygon(Ui.rrect(tr_r, th / 2.0), Color(Palette.INK, 0.14))
		var x := h / 2.0 + (size.x - h) * value
		var fill := Rect2(tr_r.position, Vector2(maxf(th, x - tr_r.position.x), th))
		draw_colored_polygon(Ui.rrect(fill, th / 2.0), Palette.SAGE)
		draw_multiline(PieceShape.dashes(Ui.rrect(fill.grow(-5), th / 2.0 - 5), 8, 6), Color(Palette.STITCH, 0.6), 2.0)
		var r := h * 0.42 * _k
		draw_circle(Vector2(x, h / 2.0 + 5), r, Color(Palette.INK, 0.2))
		draw_circle(Vector2(x, h / 2.0), r, Palette.CREAM)
		draw_arc(Vector2(x, h / 2.0), r - 6, 0, TAU, 24, Color(Palette.STITCH_DARK, 0.5), 2.0, true)
		draw_circle(Vector2(x, h / 2.0), r * 0.35, Palette.MUSTARD)
