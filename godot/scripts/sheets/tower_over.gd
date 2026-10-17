extends Sheet
## Kule bitti: temizlenen kat, kazanılan coin (uçar), rekor; Tekrar (1 bilet) / Ana menü.
## args: floors, coins, best.

func _init() -> void:
	dismissible = false
	panel_size = Vector2(-1, 900)

func build() -> void:
	var w := pw()
	var floors := int(args.get("floors", 0))
	var coins := int(args.get("coins", 0))
	var scr = args.get("screen")
	if scr and is_instance_valid(scr) and scr.hud:
		scr.hud.create_tween().tween_property(scr.hud, "modulate:a", 0.0, 0.25)
	var bar := TopBar.new()
	bar.currencies = ["coin"]
	bar.tap_to_shop = false
	bar.position = Vector2((size.x - 270) / 2.0, Ui.safe_top() + 30)
	bar.size = Vector2(270, 110)
	add_child(bar)
	Fly.hold({"coin": coins})
	var rays := Rays.new()
	rays.size = Vector2(620, 620)
	rays.position = Vector2(w / 2.0 - 310, -340)
	panel.add_child(rays)
	panel.move_child(rays, 0)
	var ic := Ui.icon("ic_tower" if UiArt.tex("ic_tower") else "ic_trophy", Vector2(240, 240))
	add(ic, Vector2((w - 240) / 2.0, -150))
	Ui.pop_in(ic, 0.15, 0.2, 0.55)
	var y := _ribbon(tr("tower.over.title"), 100)
	var fl := Ui.label(tr("tower.over.floors") % floors, 44, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	add(fl, Vector2(0, y), Vector2(w, 60))
	y += 70
	var chip := QuiltCard.new()
	chip.fill = Palette.CREAM
	chip.radius = 40
	chip.depth = 8
	add(chip, Vector2((w - 280) / 2.0, y), Vector2(280, 110))
	var ci := Ui.icon("coin", Vector2(80, 80))
	Ui.place(ci, Vector2(20, 15), Vector2(80, 80))
	chip.add_child(ci)
	var cl := Ui.label("+0", 50, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.place(cl, Vector2(100, 0), Vector2(160, 110))
	chip.add_child(cl)
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		Ui.tick(cl, 0, coins, 0.7, "+%d")
		Fly.currency(chip.global_position + chip.size / 2.0, "coin", coins, 0.8))
	y += 130
	var best := Ui.label(tr("tower.over.best") % int(args.get("best", 0)), 36, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	add(best, Vector2(0, y), Vector2(w, 50))
	y += 80
	var can := Tower.can_enter()
	var retry := Ui.button(tr("tower.over.retry") % Tower.TICKET_COST if can else tr("tower.getTickets"), "sage" if can else "mustard", Vector2(w - 140, 150), "ic_ticket")
	add(retry, Vector2(70, y))
	retry.tapped.connect(func() -> void:
		close()
		if Tower.start_run():
			Main.replace("game", {"level": "tower-1"})
		else:
			Main.open_shop())
	y += 170
	var home := Ui.button(tr("tower.over.home"), "terracotta", Vector2(w - 140, 130), "ic_home")
	add(home, Vector2(70, y))
	home.tapped.connect(func() -> void:
		close()
		Main.home())
	panel.size.y = y + 170
	_place_panel()
	panel.position.y += 90


func _ribbon(text: String, y: float, w := 680.0) -> float:
	var b := Ui.banner(text, w)
	add(b, Vector2((pw() - w) / 2.0, y))
	Ui.pop_in(b, 0.15, 0.4)
	return y + b.size.y + 10.0
