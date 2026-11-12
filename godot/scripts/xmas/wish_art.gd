class_name WishArt
extends RefCounted
## Dilek kartı çizimleri: balmumu mühür, sarılı parşömen (kurdele + mühür). Kodla çizilir.

const PAPER := Color("fbf3df")
const PAPER_SHADE := Color("ead8b4")
const WAX := Color("b8392f")
const WAX_LIGHT := Color("d9594a")
const RIBBON := Color("c8453a")

static func draw_seal(ci: CanvasItem, c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a), sin(a)) * r * (1.0 + 0.07 * sin(a * 5.0 + 0.6)))
	ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.18))
	var off := Vector2(0, -r * 0.05)
	var p2 := PackedVector2Array()
	for p in pts:
		p2.append(p + off)
	ci.draw_colored_polygon(p2, WAX)
	ci.draw_circle(c + off, r * 0.72, WAX_LIGHT)
	ci.draw_circle(c + off, r * 0.66, WAX)
	# yıldız
	var st := PackedVector2Array()
	for i in 10:
		var rr := r * (0.46 if i % 2 == 0 else 0.2)
		var a := -PI / 2.0 + TAU * i / 10.0
		st.append(c + off + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(st, WAX_LIGHT.lightened(0.12))
	ci.draw_circle(c + off + Vector2(-r * 0.4, -r * 0.4), r * 0.1, Color(1, 1, 1, 0.35))

## Yatay sarılı parşömen: r içinde, kurdele + mühür. t=0..1 kurdele/mühür görünürlüğü.
static func draw_scroll(ci: CanvasItem, r: Rect2, t := 1.0) -> void:
	var h := r.size.y
	var body := Rect2(r.position + Vector2(h * 0.18, h * 0.12), Vector2(r.size.x - h * 0.36, h * 0.76))
	ci.draw_colored_polygon(Ui.rrect(Rect2(body.position + Vector2(0, 5), body.size), h * 0.2), Color(0, 0, 0, 0.16))
	ci.draw_colored_polygon(Ui.rrect(body, h * 0.2), PAPER)
	ci.draw_rect(Rect2(body.position + Vector2(0, body.size.y * 0.55), Vector2(body.size.x, body.size.y * 0.45)), Color(PAPER_SHADE, 0.35))
	# uç rulolar
	for side in 2:
		var cx := r.position.x + h * 0.2 if side == 0 else r.end.x - h * 0.2
		var cc := Vector2(cx, r.position.y + h * 0.5)
		ci.draw_circle(cc + Vector2(0, 4), h * 0.4, Color(0, 0, 0, 0.14))
		ci.draw_circle(cc, h * 0.4, PAPER_SHADE)
		ci.draw_circle(cc, h * 0.3, PAPER)
		ci.draw_arc(cc, h * 0.2, 0.4, 5.0, 24, Color(PAPER_SHADE, 0.9), 4.0, true)
		ci.draw_arc(cc, h * 0.09, 0.4, 5.0, 14, Color(PAPER_SHADE, 0.9), 3.0, true)
	if t > 0.0:
		var bx := r.position.x + r.size.x * 0.5
		var bw := h * 0.26 * t
		ci.draw_rect(Rect2(bx - bw / 2.0, body.position.y - 2, bw, body.size.y + 4), RIBBON)
		ci.draw_rect(Rect2(bx - bw / 2.0, body.position.y - 2, bw * 0.3, body.size.y + 4), Color(1, 1, 1, 0.15))
		draw_seal(ci, Vector2(bx, r.position.y + h * 0.5), h * 0.27 * t)

## Texture'ı köşeleri korunarak (9-dilim) çizer; k = görsel ölçek (kenar kalınlığı = margin * k).
static func nine(ci: CanvasItem, tex: Texture2D, r: Rect2, margin: float, k: float, mod := Color.WHITE) -> void:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_texture_margin_all(margin)
	sb.modulate_color = mod
	ci.draw_set_transform(r.position, 0.0, Vector2(k, k))
	ci.draw_style_box(sb, Rect2(Vector2.ZERO, r.size / k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
