extends Node
## Geliştirme kancaları (ortam değişkenleri):
##   SNUG_SCREEN=<menu|map|pack:<id>|shop|settings|stats|achievements|profile|nook|daily|spin|chest|
##               quests|daily_login|calendar|levelcomplete|levelup|streak|packcomplete|onboarding|
##               splash|tower|premium|energy|pause|fail|nook_reveal|version|game>
##   SNUG_DEMO=<n>     ilk n kampanya bölümünü çözülmüş say + örnek bakiye (bekleyen kutlamalar temizlenir)
##   SNUG_LEVEL=pack:n · SNUG_DAILY=1 · SNUG_AUTO=<n yerleşim> · SNUG_DRAG=1|drop · SNUG_PEEK=1 · SNUG_SCROLL=<px|-1> · SNUG_SHOT=<sn>:<png>
##   SNUG_LANG=en|tr|es · SNUG_MUTE=1 · SNUG_SAVE=<yol> · SNUG_NOTCH=0 (masaüstü çentik simülasyonunu kapat)

func _ready() -> void:
	var lang := OS.get_environment("SNUG_LANG")
	if lang != "":
		Settings.language = lang
	var demo := OS.get_environment("SNUG_DEMO")
	if demo != "":
		seed_demo(int(demo))
	var shot := OS.get_environment("SNUG_SHOT")
	if shot != "":
		var t := float(shot.get_slice(":", 0))
		var path := shot.get_slice(":", 1)
		# İlk karelerin dev delta'sı (sahne yükleme süresi) zamanlayıcıyı yemesin.
		for i in 3:
			await get_tree().process_frame
		var scr := int(OS.get_environment("SNUG_SCROLL"))
		if scr != 0:
			await get_tree().create_timer(maxf(t - 1.0, 0.1), true, false, true).timeout
			var sc := _last_scroll(get_tree().root)
			if sc:
				sc.scroll_to(float(scr) if scr > 0 else 1e9, false)
			await get_tree().create_timer(minf(t, 1.0), true, false, true).timeout
		else:
			await get_tree().create_timer(t, true, false, true).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path)
		get_tree().quit()

## SNUG_SCROLL=<px|-1>: en son eklenen görünür dikey DragScroll'u kaydır (-1 → en alt).
func _last_scroll(n: Node) -> DragScroll:
	var found: DragScroll = null
	for c in n.get_children():
		var r := _last_scroll(c)
		if r:
			found = r
	if found == null and n is DragScroll and not (n as DragScroll).horizontal and (n as DragScroll).is_visible_in_tree():
		found = n
	return found

## Örnek ilerleme: ilk n bölüm (paket sırasıyla) çözülür, bakiye doldurulur.
func seed_demo(n: int) -> void:
	var k := 0
	for p in Progress.PACKS:
		for i in range(1, int(p.levels) + 1):
			if k >= n:
				break
			Progress.record_level(Progress.level_id(p.id, i), [22.0, 41.0, 75.0, 130.0][k % 4], 0)
			k += 1
	Wallet.debug_set("coin", 1250)
	Wallet.debug_set("gem", 48)
	Wallet.debug_set("key", 2)
	Wallet.debug_set("ticket", 1)
	Wallet.debug_set("hint", 3)
	XP.consume_level_up()
	Progress.collect_streak_milestone()
	if Progress.pending_pack_reward() != "":
		Progress.collect_pack_reward()
	Settings.set_value("onboarded", true)
	Settings.set_value("coach_shown", true)
	Progress.win_chain = 0

## SNUG_SCREEN yönlendirmesi (Main.boot çağırır).
func open_screen(spec: String) -> void:
	var name := spec.get_slice(":", 0)
	var arg := spec.get_slice(":", 1) if spec.contains(":") else ""
	if name in Main.SCREENS and name not in ["pack", "game"]:
		Main.goto(name, {}, "none")
		return
	match name:
		"pack":
			Main._show("menu", {}, false)
			Main._show("map", {})
			Main.push("pack", {"pack": arg if arg != "" else "cozy-beginnings"}, "none")
		"game":
			Main._show("menu", {}, false)
			Main.push("game", {"level": arg if arg != "" else Progress.level_id(Main.pack, Main.index)}, "none")
		"levelcomplete":
			Main._show("menu", {}, false)
			Main.push("game", {"level": arg if arg != "" else Progress.level_id(Main.pack, Main.index), "dev_solve": true}, "none")
		"pause", "fail":
			Main._show("menu", {}, false)
			Main.push("game", {"level": Progress.level_id(Main.pack, Main.index), "dev_sheet": name}, "none")
		_:
			Main.goto("menu", {"dev_quiet": true}, "none")
			await get_tree().create_timer(0.5).timeout
			match name:
				"chest":
					for i in Chest.SOLVES_PER_CHEST:
						Chest.record_solve()
					if Wallet.keys == 0:
						Wallet.debug_set("key", 1)
					Main.open("chest")
				"levelup":
					Main.open("reward", {"title": tr("level.reached") % (XP.level + 1), "rewards": {"coin": XP.level_up_coins(XP.level + 1)}, "pose": "cheer"})
				"streak":
					Main.reward(tr("streak.milestone") % 7, Progress.streak_reward(7), {"subtitle": tr("streak.keepGoing"), "icon": "ic_heart"})
				"packcomplete":
					Main.reward(tr("pack.complete.title"), {"coin": 200, "gem": 25, "key": 2}, {"subtitle": tr("pack.cozy_beginnings.title"), "pose": "cheer", "double": false})
				"version":
					Main.open("version", {"forced": true})
				"energy":
					Main.open("energy", {"level": Progress.continue_target()})
				"nook_reveal":
					Main.open("nook_reveal", {"pack": "cozy-beginnings", "piece": 0})
				_:
					Main.open(name)

func attach(g: Game) -> void:
	var auto := OS.get_environment("SNUG_AUTO")
	if auto != "":
		_autoplay(g, int(auto))
	if OS.get_environment("SNUG_PEEK") != "":
		get_tree().create_timer(2.6).timeout.connect(func() -> void: g.peek())
	var dr := OS.get_environment("SNUG_DRAG")
	if dr != "":
		drag_test(g, dr == "drop")

func _autoplay(g: Game, n: int) -> void:
	await get_tree().create_timer(1.0).timeout
	var k := 0
	for p in g.lvl.pieces:
		if k >= n or not is_instance_valid(g):
			break
		g._place(g.pieces[p.id], g.lvl.solution[p.id], true)
		k += 1
		await get_tree().create_timer(0.35).timeout

## SNUG_DRAG=1: ilk parçayı gerçek dokunma olaylarıyla çözüm yerine sürükler (bırakmadan durur).
func drag_test(g: Game, release: bool) -> void:
	await get_tree().create_timer(1.2).timeout
	var p: PieceData = g.lvl.pieces[0]
	var v: PieceView = g.pieces[p.id]
	var xf := g.get_global_transform_with_canvas()
	var start := v.position + (Vector2(p.cells[0]) - Vector2(p.size) / 2.0 + Vector2(0.5, 0.5)) * v.cs * v.tray_scale
	var o: Vector2i = g.lvl.solution[p.id]
	var dest := g.board.position + (Vector2(o) + Vector2(p.size) / 2.0) * g.cs + Vector2(0, Game.LIFT * g.cs) + Vector2(14, 10)
	start = xf * start
	dest = xf * dest
	_touch(start, true)
	for i in 30:
		await get_tree().process_frame
		var d := InputEventScreenDrag.new()
		d.position = get_viewport().get_final_transform() * start.lerp(dest, ease(i / 29.0, 0.5))
		Input.parse_input_event(d)
	if release:
		await get_tree().create_timer(0.3).timeout
		_touch(dest, false)

func _touch(at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = get_viewport().get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)
