extends Screen
## Paket haritası: 17 paket, kıvrılan bir "yorgan yolu" üzerinde sağlı sollu kumaş kartlar.
## Kartlar arası kesikli iplik; her kartta dikişli pencerede sahne, kenardan bakan paket dostu,
## başlık, grid/zorluk, ilerleme çubuğu, yıldız. Kilitli paket gri + kilit. Açık paket → "pack".

const CARD_H := 330.0
const STEP := 390.0

var _scroll: DragScroll
var _cards: Array[Control] = []

func build() -> void:
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene(_current_pack())
	bg.wash_top = 0.55
	bg.wash_bottom = 0.85
	bg.size = size
	add_child(bg)
	var y0 := header("levels.title", true)
	_scroll = DragScroll.new()
	_scroll.position = Vector2(0, y0)
	_scroll.size = Vector2(size.x, H - y0)
	add_child(_scroll)
	var thread := ThreadPath.new()
	_scroll.content.add_child(thread)
	var pts := PackedVector2Array()
	var cw := W - 190.0
	for i in Progress.PACKS.size():
		var p: Dictionary = Progress.PACKS[i]
		var left := i % 2 == 0
		var x := X0 + (40.0 if left else 150.0)
		var y := 40.0 + i * STEP
		var card := _card(p, i, Vector2(cw, CARD_H))
		card.position = Vector2(x, y)
		_scroll.content.add_child(card)
		_cards.append(card)
		pts.append(Vector2(x + (cw - 70.0 if left else 70.0), y + CARD_H * 0.5))
	thread.points = pts
	var total := 40.0 + Progress.PACKS.size() * STEP + BOTTOM + 40.0
	thread.size = Vector2(size.x, total)
	_scroll.set_length(total)
	# Sıradaki pakete kaydır
	var cur := Progress.pack_index(_current_pack())
	_scroll.scroll_to(maxf(0.0, 40.0 + cur * STEP - _scroll.size.y * 0.3), false)
	for i in _cards.size():
		if absi(i - cur) <= 3:
			Ui.pop_in(_cards[i], 0.05 + absi(i - cur) * 0.06, 0.7)

func _current_pack() -> String:
	var t := Progress.continue_target()
	return String(Progress.split_id(t)[0]) if t != "" else String(Progress.PACKS[Progress.PACKS.size() - 1].id)

func _card(p: Dictionary, i: int, sz: Vector2) -> QuiltCard:
	var id := String(p.id)
	var unlocked := Progress.is_pack_unlocked(id)
	var done := Progress.pack_completed_count(id)
	var complete := Progress.is_pack_complete(id)
	var c := QuiltCard.new()
	c.pressable = true
	c.fabric = PackArt.fabric(id)
	c.inner = 16
	c.radius = 52
	c.locked = not unlocked
	c.glow = unlocked and not complete and id == _current_pack()
	c.size = sz
	# Sahne penceresi
	var win := SceneWindow.new()
	win.tex = PackArt.scene(id)
	win.grey = not unlocked
	Ui.place(win, Vector2(34, 34), Vector2(250, sz.y - 68))
	c.add_child(win)
	# Bilgiler
	var tx := 310.0
	var tw := sz.x - tx - 40.0
	var t := Ui.label(tr(String(p.title)), Ui.fit_font(tr(String(p.title)), 50, tw - 70, 36), Palette.INK if unlocked else Palette.INK_SOFT)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(t, Vector2(tx, 40), Vector2(tw - 70, 66))
	c.add_child(t)
	var g := int(p.grid)
	var sub := Ui.label("%s · %s" % [tr("pack.grid_label.%d" % g), tr(PackArt.difficulty_key(g))], 30, Palette.INK_SOFT)
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ui.place(sub, Vector2(tx, 104), Vector2(tw, 44))
	c.add_child(sub)
	var bar := Widgets.StitchBar.new()
	bar.value = float(done) / float(p.levels)
	bar.col = Palette.SAGE if not complete else Palette.MUSTARD
	Ui.place(bar, Vector2(tx, 168), Vector2(tw, 34))
	c.add_child(bar)
	var pl := Ui.label("%d/%d" % [done, int(p.levels)], 30, Palette.INK)
	Ui.place(pl, Vector2(tx, 210), Vector2(tw * 0.5, 50))
	c.add_child(pl)
	var st := Ui.icon("ic_star", Vector2(50, 50))
	Ui.place(st, Vector2(tx + tw - 190, 210), Vector2(50, 50))
	c.add_child(st)
	var sl := Ui.label("%d/%d" % [Progress.pack_stars(id), int(p.levels) * 3], 30, Palette.INK)
	Ui.place(sl, Vector2(tx + tw - 136, 210), Vector2(140, 50))
	c.add_child(sl)
	# Paket dostu kenardan bakar
	var fr := Ui.tex_rect(PackArt.animal(id), Vector2(150, 150))
	Ui.place(fr, Vector2(sz.x - 150, -62), Vector2(150, 150))
	if not unlocked:
		fr.modulate = Color(0.25, 0.2, 0.2, 0.75)
	c.add_child(fr)
	if unlocked:
		Ui.bob(fr, 5.0, 2.2 + (i % 3) * 0.3, i)
	if not unlocked:
		var lk := Ui.icon("ic_lock", Vector2(120, 120))
		Ui.place(lk, Vector2(34 + 65, sz.y / 2.0 - 60), Vector2(120, 120))
		c.add_child(lk)
	elif complete:
		var seal := Seal.new()
		Ui.place(seal, Vector2(10, sz.y - 120), Vector2(120, 120))
		seal.rotation = -0.2
		c.add_child(seal)
	c.tapped.connect(func() -> void:
		if unlocked:
			Main.push("pack", {"pack": id})
		else:
			Ui.shake(c, 12.0)
			Main.confirm(tr("pack.locked"), tr("alert.unlockPack.prevPack"), tr("menu.premium"),
				func() -> void: Main.open("premium"), false))
	return c

func on_resume() -> void:
	Main.replace("map", args, "none")

## Kartlar arasındaki kesikli iplik (yumuşak S eğrileri).
class ThreadPath extends Control:
	var points := PackedVector2Array()
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if points.size() < 2:
			return
		var curve := PackedVector2Array()
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			for k in 21:
				var t := k / 20.0
				var m := a.lerp(b, t)
				m.x += sin(t * PI) * (b.x - a.x) * 0.0
				var cx := lerpf(a.x, b.x, t * t * (3.0 - 2.0 * t))
				curve.append(Vector2(cx, m.y))
		var segs := PieceShape.dashes(curve, 18.0, 12.0)
		# dashes kapalı çevre ekler → son segmenti at
		if segs.size() >= 2:
			segs.resize(segs.size() - 2)
		var sh := PackedVector2Array()
		for p in segs:
			sh.append(p + Vector2(0, 4))
		draw_multiline(sh, Color(Palette.INK, 0.25), 7.0)
		draw_multiline(segs, Palette.TERRACOTTA, 7.0)

## Dikişli yuvarlak pencere içinde sahne (kapla-kırp). grey → kilitli görünüm.
class SceneWindow extends Control:
	var tex: Texture2D
	var grey := false
	var radius := 36.0
	var focus := Vector2(0.5, 0.45)
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var poly := Ui.rrect(r, radius)
		draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, 5), size), radius), Color(Palette.INK, 0.25))
		if tex:
			draw_colored_polygon(poly, Color(0.5, 0.48, 0.47) if grey else Color.WHITE, cover_uv(poly, size, tex.get_size(), focus), tex)
		draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-10), radius - 8), 12, 8), Color(Palette.STITCH, 0.85), 3.0)
		draw_polyline(poly + PackedVector2Array([poly[0]]), Color(Palette.INK, 0.35), 3.0, true)
	## Poligon noktaları (0..size) → kapla-kırp normalize UV.
	static func cover_uv(poly: PackedVector2Array, sz: Vector2, ts: Vector2, f := Vector2(0.5, 0.5)) -> PackedVector2Array:
		var k := maxf(sz.x / ts.x, sz.y / ts.y)
		var vis := sz / (ts * k)        # görünen UV oranı
		var off := (Vector2.ONE - vis) * f
		var uv := PackedVector2Array()
		for p in poly:
			uv.append(off + p / sz * vis)
		return uv

## "Tamamlandı" mührü: dikişli altın rozet + yıldız.
class Seal extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		var pts := PackedVector2Array()
		for i in 24:
			var a := i * TAU / 24.0
			pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.88))
		var sh := PackedVector2Array()
		for p in pts:
			sh.append(p + Vector2(0, 5))
		draw_colored_polygon(sh, Color(Palette.INK, 0.3))
		draw_colored_polygon(pts, Palette.MUSTARD)
		draw_arc(c, r * 0.7, 0, TAU, 36, Color(Palette.STITCH, 0.85), 3.0, true)
		var st := UiArt.tex("ic_star")
		if st:
			draw_texture_rect(st, Rect2(c - Vector2(r, r) * 0.55, Vector2(r, r) * 1.1), false)
