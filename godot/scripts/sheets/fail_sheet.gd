extends Sheet
## Süre doldu (kampanya/günlük): düşünceli maskot, "Süre doldu!", Tekrar dene (enerji) / Ana menü.
## args: level, screen.

func _init() -> void:
	dismissible = false
	panel_size = Vector2(-1, 820)

func build() -> void:
	var scr = args.get("screen")
	var id := String(args.get("level", ""))
	var w := pw()
	var m := Ui.icon("think", Vector2(300, 300), "mascot")
	add(m, Vector2((w - 300) / 2.0, -170))
	Ui.pop_in(m, 0.15, 0.3)
	Ui.bob(m, 6.0, 2.2)
	var clock := GameHud.Clock.new()
	add(clock, Vector2(w / 2.0 + 90, -40), Vector2(110, 110))
	Ui.pop_in(clock, 0.3, 0.2)
	var y := _ribbon(tr("fail.title"), 130)
	y = body(tr("fail.message"), y + 6, 38)
	y += 40
	var free := Energy.unlimited() or Settings.zen_mode or Energy.is_free_level(id)
	var retry := Ui.button(tr("common.retry"), "sage", Vector2(w - 140, 150), "ic_restart")
	if not free:
		retry.sub = "−%d %s" % [Energy.COST, tr("currency.energy")]
	add(retry, Vector2(70, y))
	retry.tapped.connect(func() -> void:
		close()
		if scr and is_instance_valid(scr):
			scr.restart(not free)
		else:
			Main.play(id))
	Ui.pop_in(retry, 0.3, 0.6)
	y += 170
	var home := Ui.button(tr("pause.home"), "terracotta", Vector2(w - 140, 130), "ic_home")
	add(home, Vector2(70, y))
	home.tapped.connect(func() -> void:
		close()
		Main.home())
	Ui.pop_in(home, 0.38, 0.6)
	panel.size.y = y + 170
	_place_panel()
	panel.position.y += 80


func _ribbon(text: String, y: float, w := 680.0) -> float:
	var b := Ui.banner(text, w)
	add(b, Vector2((pw() - b.size.x) / 2.0, y))
	Ui.pop_in(b, 0.15, 0.4)
	return y + b.size.y + 10.0
