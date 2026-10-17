class_name QuiltCard
extends Control
## Dikişli kumaş kart: gölge + kumaş dokulu yastık + (isteğe bağlı) iç patiska panel + kesikli dikiş.
## pressable ise basınca çöker, bırakınca yaylanır, `tapped` yayar (DragScroll sürüklemesinde iptal).

signal tapped

var fabric := -1             ## art/fabric/classic/fNN; -1 → düz `fill`
var fill := Palette.CARD
var inner := 0.0             ## >0: kenardan bu kadar içeride krem panel
var inner_fill := Palette.CARD
var radius := 44.0
var depth := 10.0            ## gölge kalınlığı
var stitch := true
var stitch_col := Color(Palette.STITCH, 0.85)
var pressable := false
var locked := false          ## gri, basılabilir ama "kilitli" hissi
var glow := false            ## nefes alan altın çerçeve (hazır ödül / sıradaki bölüm)
var tex_scale := 0.75
## art/ui/<ad>.png 9-dilim panel dokusu ("panel_cream" | "panel_sage"). Verilirse kumaş/dolgu yerine
## çizilir; küçük kartlarda köşeler orantılı küçülür. Dokunun kendi dikişi var → stitch/inner atlanır.
var skin_name := ""
const SKIN_MARGIN := 90.0
static var _skins := {}

var _press := 0.0
var _spring := 1.0
var _vs := 0.0
var _down := false
var _t := 0.0

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	mouse_filter = Control.MOUSE_FILTER_STOP if pressable else Control.MOUSE_FILTER_IGNORE
	pivot_offset = size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	set_process(pressable or glow)

func _gui_input(e: InputEvent) -> void:
	if not pressable:
		return
	if e is InputEventScreenTouch or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		if e.pressed:
			_down = true
			set_process(true)
			Juice.haptic("tick")
			Sfx.play("click", 1.2, -12.0)
		elif _down:
			_down = false
			_vs += 4.0
			if Rect2(Vector2.ZERO, size).has_point(e.position) and not DragScroll.recently_dragged():
				Sfx.play("click", 0.9, -5.0)
				tapped.emit()
		accept_event()

func _process(dt: float) -> void:
	_t += dt
	if _down and DragScroll.recently_dragged():
		_down = false
	_press = move_toward(_press, 1.0 if _down else 0.0, dt * 14.0)
	var target := 0.96 if _down else 1.0
	_vs += (target - _spring) * 380.0 * dt - _vs * 18.0 * dt
	_spring += _vs * dt
	scale = Vector2(_spring, _spring)
	queue_redraw()

func _draw() -> void:
	var dy := depth * 0.6 * _press
	var r := Rect2(Vector2(0, dy), size)
	# Gölge
	draw_colored_polygon(Ui.rrect(Rect2(Vector2(0, depth), size), radius), Color(Palette.SHADOW, Palette.SHADOW.a * (1.0 - _press * 0.6)))
	if skin_name != "" and _skin(skin_name):
		_draw_skin(r)
		return
	var outer := Ui.rrect(r, radius)
	var tex: Texture2D = Fabrics.get_tex(fabric) if fabric >= 0 else null
	var mod := Color(0.62, 0.6, 0.6) if locked else Color.WHITE
	if tex:
		var uv := PackedVector2Array()
		var ts := tex.get_size() * tex_scale
		for p in outer:
			uv.append(p / ts)
		draw_colored_polygon(outer, mod, uv, tex)
	else:
		draw_colored_polygon(outer, fill * mod)
	# Alt kenar gölgesi (yastık kalınlığı)
	var lip := Ui.rrect(Rect2(r.position + Vector2(0, r.size.y - radius), Vector2(r.size.x, radius)), radius)
	draw_colored_polygon(lip, Color(Palette.INK, 0.07))
	if inner > 0.0:
		var q := r.grow(-inner)
		var ir := maxf(8.0, radius - inner * 0.8)
		draw_colored_polygon(Ui.rrect(Rect2(q.position + Vector2(0, 4), q.size), ir), Color(Palette.INK, 0.12))
		draw_colored_polygon(Ui.rrect(q, ir), inner_fill * mod)
		if stitch:
			draw_multiline(PieceShape.dashes(Ui.rrect(q.grow(-10), maxf(6.0, ir - 8.0)), 14.0, 9.0), Color(Palette.STITCH_DARK, 0.45), 3.0)
	if stitch:
		var sc := stitch_col if tex or fill.get_luminance() < 0.7 else Color(Palette.STITCH_DARK, 0.55)
		draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-13), maxf(6.0, radius - 12.0)), 16.0, 10.0), sc, 3.5)
	if glow:
		var a := 0.45 + 0.4 * sin(_t * 4.0)
		draw_polyline(Ui.rrect(r.grow(5), radius + 5) + PackedVector2Array([Ui.rrect(r.grow(5), radius + 5)[0]]), Color(Palette.GOLD, a), 8.0, true)
	if _press > 0.0:
		draw_colored_polygon(outer, Color(Palette.INK, 0.06 * _press))

static func _skin(name: String) -> StyleBoxTexture:
	if not _skins.has(name):
		var t := UiArt.tex(name)
		var sb: StyleBoxTexture = null
		if t:
			sb = StyleBoxTexture.new()
			sb.texture = t
			sb.set_texture_margin_all(SKIN_MARGIN)
			sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
			sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		_skins[name] = sb
	return _skins[name]

func _draw_skin(r: Rect2) -> void:
	var sb := _skin(skin_name)
	# Köşe payı en çok kısa kenarın ~%35'i: küçük kartta doku ölçeklenir.
	var k := minf(1.0, minf(r.size.x, r.size.y) * 0.36 / SKIN_MARGIN)
	var mod := Color(0.62, 0.6, 0.6) if locked else Color.WHITE
	draw_set_transform(r.position + Vector2(0, depth * 0.5 * (1.0 - _press)), 0.0, Vector2(k, k))
	var shadow := Rect2(Vector2(0, depth / k * 0.6), r.size / k)
	draw_colored_polygon(Ui.rrect(shadow.grow(-12.0), radius / k), Color(Palette.SHADOW, Palette.SHADOW.a * 0.8))
	draw_set_transform(r.position, 0.0, Vector2(k, k))
	sb.modulate_color = mod.darkened(0.06 * _press)
	draw_style_box(sb, Rect2(Vector2.ZERO, r.size / k))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if glow:
		var a := 0.45 + 0.4 * sin(_t * 4.0)
		var g := Ui.rrect(r.grow(5), radius + 5)
		g.append(g[0])
		draw_polyline(g, Color(Palette.GOLD, a), 8.0, true)
