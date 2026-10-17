extends Sheet
## Kule girişi: üst üste dikilmiş kat yamaları (5×5 → 8×8, her 4 katta büyür), rekor ve aktif
## tırmanış, bilet bakiyesi. Başla/Devam → Tower.start_run → Main.play("tower-N"). Bilet yoksa
## açıklama + 50 gem → 1 bilet takası ya da mağaza.

var _btn: JuicyButton
var _tickets: Label

func _init() -> void:
	panel_size = Vector2(-1, 1300)

func build() -> void:
	var w := pw()
	var y := banner_title(tr("tower.title")) + 30
	var sub := Ui.label(tr("tower.subtitle"), 34, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(sub, Vector2(40, y - 8), Vector2(w - 80, 50))
	y += 60
	# Kat yığını
	var hero := Ui.icon("ic_tower", Vector2(200, 380))
	add(hero, Vector2(60, y + 60))
	Ui.bob(hero, 6.0, 2.2)
	Ui.pop_in(hero, 0.2, 0.3)
	var stack := FloorStack.new()
	stack.current = Tower.current_floor
	stack.best = Tower.best_floor
	add(stack, Vector2(280, y), Vector2(w - 340, 470))
	y += 490
	# Rekor + bilet satırı
	var best := Ui.label(tr("tower.best") % Tower.best_floor, 40, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	add(best, Vector2(40, y), Vector2(w / 2.0 - 40, 70))
	var tic := Ui.icon(Ui.currency_icon("ticket"), Vector2(70, 70))
	add(tic, Vector2(w / 2.0 + 40, y))
	_tickets = Ui.label("× %d" % Wallet.tickets, 42, Palette.INK)
	add(_tickets, Vector2(w / 2.0 + 120, y), Vector2(200, 70))
	y += 100
	if Tower.has_active_run():
		_btn = Ui.button(tr("tower.resume") % Tower.current_floor, "terracotta", Vector2(w - 160, 150), "", 50)
	else:
		_btn = Ui.button(tr("tower.start"), "terracotta", Vector2(w - 160, 150), "", 56)
		_btn.sub = "1 × " + tr("currency.ticket")
	add(_btn, Vector2(80, y))
	_btn.tapped.connect(_start)
	y += 170
	if not Tower.can_enter():
		y = body(tr("tower.needTicket"), y, 32) + 16
		var bw := (w - 180) / 2.0
		var ex := Ui.button(tr("tower.buyTicket") % Wallet.GEM_PER_TICKET, "mustard", Vector2(bw, 130), "ic_gem", 34)
		add(ex, Vector2(70, y))
		ex.disabled = not Wallet.can_afford("gem", Wallet.GEM_PER_TICKET)
		ex.tapped.connect(func() -> void:
			if Wallet.exchange("gem", "ticket", 1):
				Sfx.play("reward")
				Main.toast(tr("shop.exchange.success.title"), Ui.currency_icon("ticket"))
				close()
				Main.open("tower"))
		ex.denied.connect(func() -> void: Main.toast(tr("shop.claim.insufficient"), "ic_gem", Palette.TERRACOTTA))
		var shop := Ui.button(tr("tower.getTickets"), "sage", Vector2(bw, 130), "ic_shop", 34)
		add(shop, Vector2(110 + bw, y))
		shop.tapped.connect(func() -> void:
			close()
			Main.open_shop())
		y += 150
	panel.size.y = y + 40
	_place_panel()
	close_x()

func _start() -> void:
	if not Tower.start_run():
		Ui.shake(_btn, 14.0)
		Sfx.play("error", 1.0, -6.0)
		return
	close()
	Main.play("tower-%d" % maxi(1, Tower.current_floor))

## Üst üste katlar: alt katlar geniş, yukarı daraldıkça grid büyür (zorluk). Aktif kat parlar.
class FloorStack extends Control:
	var current := 0
	var best := 0
	var _t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()
	func _draw() -> void:
		var n := 6
		var base := maxi(1, current if current > 0 else best + 1)
		var first := maxi(1, base - 2)
		var fh := size.y / n
		for i in n:
			var f := first + i
			var y := size.y - (i + 1) * fh
			var wk := 1.0 - i * 0.08
			var w := size.x * wk
			var r := Rect2((size.x - w) / 2.0, y + 6, w, fh - 10)
			var poly := Ui.rrect(r, 20, 4)
			draw_colored_polygon(Ui.rrect(Rect2(r.position + Vector2(0, 6), r.size), 20, 4), Palette.SHADOW)
			var tex := Fabrics.get_tex(f * 5)
			var mod := Color.WHITE if f <= maxi(best, current) or f == base else Color(0.7, 0.68, 0.66)
			if tex:
				var uv := PackedVector2Array()
				for p in poly:
					uv.append(p / (tex.get_size() * 0.75))
				draw_colored_polygon(poly, mod, uv, tex)
			else:
				draw_colored_polygon(poly, Palette.piece(f) * mod)
			draw_multiline(PieceShape.dashes(Ui.rrect(r.grow(-8), 14, 4), 10, 7), Color(Palette.STITCH, 0.8), 2.5)
			if f == base:
				var a := 0.5 + 0.4 * sin(_t * 4.0)
				var g := Ui.rrect(r.grow(5), 24, 4)
				g.append(g[0])
				draw_polyline(g, Color(Palette.GOLD, a), 7.0, true)
			var g2 := Tower.grid_size(f)
			var t := "%d   ·   %d×%d" % [f, g2, g2]
			var fs := 34
			var ts := Ui.FONT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var p := r.get_center() + Vector2(-ts.x / 2.0, fs * 0.36)
			draw_string_outline(Ui.FONT, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(Palette.INK, 0.8))
			draw_string(Ui.FONT, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)
			if f == best and best > 0:
				var tr_ic := UiArt.tex("ic_trophy")
				if tr_ic:
					draw_texture_rect(tr_ic, Rect2(r.end.x - 70, r.position.y - 6, 56, 74), false)
