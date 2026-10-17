extends Node
## Yönlendirici: ekran yığını + modal sheet'ler + efekt katmanı + yorgan perdesi geçişi.
##
## Ekranlar (Screen) kendi CanvasLayer'ında yaşar; üstüne ekran açılınca alttaki gizlenir.
##   Main.goto(route, args)   yığını temizle → yeni kök (perde geçişi)
##   Main.push(route, args)   üstüne aç (fx "pop" | "curtain" | "none")
##   Main.replace(route, args) en üstü değiştir (sonraki bölüm vb.)
##   Main.pop() / Main.back()  geri (önce açık sheet kapanır)
##   Main.open(sheet, args) -> Sheet   modal (energy, pause, levelcomplete, spin, chest, ...)
##   Main.play(level_id)       enerji kapısı → oyun ekranı
##   Main.toast(text, icon)    üstten bilgi balonu
## Bölüm id'leri Progress ile aynı: "<paket>-<n>", "daily-<i>", "endless-<n>", "tower-<kat>".

signal route_changed(route: String)

const SCREENS := {
	"splash": "res://scripts/screens/splash.gd",
	"onboarding": "res://scripts/screens/onboarding.gd",
	"menu": "res://scripts/screens/menu.gd",
	"map": "res://scripts/screens/pack_map.gd",
	"pack": "res://scripts/screens/pack_detail.gd",
	"game": "res://scripts/screens/game_screen.gd",
	"shop": "res://scripts/screens/shop.gd",
	"settings": "res://scripts/screens/settings.gd",
	"stats": "res://scripts/screens/stats.gd",
	"achievements": "res://scripts/screens/achievements.gd",
	"profile": "res://scripts/screens/profile.gd",
	"nook": "res://scripts/screens/nook.gd",
	"daily": "res://scripts/screens/daily_calendar.gd",
}
const SHEETS := {
	"reward": "res://scripts/ui/reward_modal.gd",
	"confirm": "res://scripts/sheets/confirm_sheet.gd",
	"energy": "res://scripts/sheets/energy_gate.gd",
	"pause": "res://scripts/sheets/pause_sheet.gd",
	"fail": "res://scripts/sheets/fail_sheet.gd",
	"tower_over": "res://scripts/sheets/tower_over.gd",
	"levelcomplete": "res://scripts/sheets/level_complete.gd",
	"premium": "res://scripts/sheets/premium_sheet.gd",
	"spin": "res://scripts/sheets/spin_sheet.gd",
	"chest": "res://scripts/sheets/chest_sheet.gd",
	"quests": "res://scripts/sheets/quests_sheet.gd",
	"daily_login": "res://scripts/sheets/daily_login_sheet.gd",
	"calendar": "res://scripts/sheets/calendar_sheet.gd",
	"tower": "res://scripts/sheets/tower_sheet.gd",
	"nook_reveal": "res://scripts/sheets/nook_reveal.gd",
	"transfer": "res://scripts/sheets/transfer_sheet.gd",
	"version": "res://scripts/sheets/version_gate.gd",
}
const SCREEN_LAYER0 := 1
const SHEET_LAYER := 40
const GATE_LAYER := 70
const FX_LAYER := 80
const CURTAIN_LAYER := 100

var host: Node
var stack: Array = []          # [{route, layer: CanvasLayer, screen: Screen}]
var sheet_layer: CanvasLayer
var gate_layer: CanvasLayer
var fx_layer: CanvasLayer
var curtain: Curtain
var busy := false
var _toast_y := 0

# Eski API (Dev/test): bölüm seçimi
var pack := "cozy-beginnings"
var index := 1

func _ready() -> void:
	var env := OS.get_environment("SNUG_LEVEL")
	if env != "":
		pack = env.get_slice(":", 0)
		index = int(env.get_slice(":", 1))
	get_tree().root.set_meta("snug", true)
	Events.toast.connect(func(key: String, a: Array) -> void:
		toast(tr(key) % a if not a.is_empty() else tr(key)))
	Events.achievement_unlocked.connect(func(id: String) -> void:
		toast(tr("toast.achievement") % tr("achievement.%s.title" % id), "ic_trophy", Palette.MUSTARD))
	Events.quest_completed.connect(func(_i: int) -> void:
		toast(tr("toast.quest.done"), "ic_calendar", Palette.SAGE))
	VersionGate.state_changed.connect(_on_version)

## scenes/main.gd çağırır: katmanları kur, ilk ekranı aç.
func boot(root: Node) -> void:
	host = root
	sheet_layer = _layer(SHEET_LAYER)
	gate_layer = _layer(GATE_LAYER)
	fx_layer = _layer(FX_LAYER)
	var cl := _layer(CURTAIN_LAYER)
	curtain = Curtain.new()
	cl.add_child(curtain)
	Sfx.set_track(Settings.desired_track())
	var dev := OS.get_environment("SNUG_SCREEN")
	if dev != "":
		Dev.open_screen(dev)
	elif OS.get_environment("SNUG_LEVEL") != "" or OS.get_environment("SNUG_DAILY") != "":
		var id := "daily-0" if OS.get_environment("SNUG_DAILY") != "" else Progress.level_id(pack, index)
		_show("menu", {}, false)
		push("game", {"level": id}, "none")
	else:
		goto("splash", {}, "none")
	if VersionGate.state in ["forced", "soft"]:
		_on_version(VersionGate.state)

func _layer(n: int) -> CanvasLayer:
	var l := CanvasLayer.new()
	l.layer = n
	host.add_child(l)
	return l

# ------------------------------------------------------------------ Ekran yığını

func top() -> Screen:
	return stack.back().screen if not stack.is_empty() else null

func top_route() -> String:
	return String(stack.back().route) if not stack.is_empty() else ""

func _make(route: String, args: Dictionary) -> Screen:
	var path: String = SCREENS.get(route, "")
	if path == "" or not ResourceLoader.exists(path):
		push_warning("Main: ekran yok: " + route)
		return null
	var s: Screen = load(path).new()
	s.args = args
	s.route = route
	return s

func _show(route: String, args: Dictionary, cover_prev := true) -> Screen:
	var s := _make(route, args)
	if s == null:
		return null
	var l := CanvasLayer.new()
	l.layer = SCREEN_LAYER0 + stack.size()
	host.add_child(l)
	l.add_child(s)
	if cover_prev and not stack.is_empty():
		var prev: Dictionary = stack.back()
		prev.layer.visible = false
		prev.screen.on_cover(true)
	stack.append({"route": route, "layer": l, "screen": s})
	route_changed.emit(route)
	return s

func _clear_sheets() -> void:
	for c in sheet_layer.get_children():
		c.queue_free()

## Yığını temizleyip yeni kök ekran.
func goto(route: String, args := {}, fx := "curtain") -> void:
	if busy:
		return
	busy = true
	if fx == "curtain":
		await curtain.cover()
	_clear_sheets()
	for e in stack:
		e.layer.queue_free()
	stack.clear()
	var s := _show(route, args)
	if fx == "curtain":
		await curtain.uncover()
	busy = false
	if s:
		s.on_enter()

func push(route: String, args := {}, fx := "pop") -> void:
	if busy:
		return
	busy = true
	if fx == "curtain":
		await curtain.cover()
		_clear_sheets()
	var s := _show(route, args)
	if s == null:
		busy = false
		return
	if fx == "curtain":
		await curtain.uncover()
	elif fx == "pop" and not Ui.reduce_motion():
		s.pivot_offset = s.size / 2.0
		s.scale = Vector2(1.06, 1.06)
		s.modulate.a = 0.0
		var tw := s.create_tween().set_parallel()
		tw.tween_property(s, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "modulate:a", 1.0, 0.18)
		await tw.finished
	busy = false
	s.on_enter()

## En üstteki ekranı değiştir (yığın derinliği aynı).
func replace(route: String, args := {}, fx := "curtain") -> void:
	if busy:
		return
	busy = true
	if fx == "curtain":
		await curtain.cover()
	_clear_sheets()
	if not stack.is_empty():
		var e: Dictionary = stack.pop_back()
		e.layer.queue_free()
	var s := _show(route, args, false)
	if fx == "curtain":
		await curtain.uncover()
	busy = false
	if s:
		s.on_enter()

func pop(fx := "pop") -> void:
	if busy or stack.size() <= 1:
		return
	busy = true
	var e: Dictionary = stack.back()
	if fx == "curtain":
		await curtain.cover()
	elif fx == "pop" and not Ui.reduce_motion():
		var s: Screen = e.screen
		s.pivot_offset = s.size / 2.0
		var tw := s.create_tween().set_parallel()
		tw.tween_property(s, "scale", Vector2(0.94, 0.94), 0.16).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(s, "modulate:a", 0.0, 0.16)
		await tw.finished
	stack.pop_back()
	e.layer.queue_free()
	_clear_sheets()
	var prev: Dictionary = stack.back()
	prev.layer.visible = true
	prev.screen.on_cover(false)
	route_changed.emit(String(prev.route))
	if fx == "curtain":
		await curtain.uncover()
	busy = false
	prev.screen.on_resume()

## Belirli bir rotaya kadar geri sar (yoksa menüye git).
func pop_to(route: String) -> void:
	for i in range(stack.size() - 1, -1, -1):
		if stack[i].route == route:
			if i == stack.size() - 1:
				return
			busy = true
			await curtain.cover()
			_clear_sheets()
			while stack.size() > i + 1:
				stack.pop_back().layer.queue_free()
			stack.back().layer.visible = true
			stack.back().screen.on_cover(false)
			route_changed.emit(route)
			await curtain.uncover()
			busy = false
			stack.back().screen.on_resume()
			return
	goto(route)

func home() -> void:
	pop_to("menu")

## Geri hareketi (Esc / Android geri / ekrandaki geri butonu).
func back() -> void:
	if busy:
		return
	if gate_layer.get_child_count() > 0:
		return
	var sheets := sheet_layer.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())
	if not sheets.is_empty():
		var sh = sheets.back()
		if sh.has_method("on_back"):
			sh.on_back()
		return
	var t := top()
	if t and t.on_back():
		return
	if stack.size() > 1:
		pop()

func is_layer_on_top(l: CanvasLayer) -> bool:
	if l == null:
		return true
	var open := sheet_layer.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())
	if l == sheet_layer:
		return true
	if not open.is_empty() or gate_layer.get_child_count() > 0:
		return false
	return stack.is_empty() or stack.back().layer == l

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()

# ------------------------------------------------------------------ Sheet'ler

## Modal aç. Yoksa null döner (uyarı basar).
func open(name: String, args := {}) -> Sheet:
	var path: String = SHEETS.get(name, "")
	if path == "" or not ResourceLoader.exists(path):
		push_warning("Main: sheet yok: " + name)
		return null
	var sh: Sheet = load(path).new()
	sh.args = args
	sh.set_meta("route", name)
	(gate_layer if name == "version" else sheet_layer).add_child(sh)
	return sh

## Ödül kutlaması (Sheet "reward").
func reward(title: String, rewards: Dictionary, extra := {}) -> Sheet:
	var a := extra.duplicate()
	a["title"] = title
	a["rewards"] = rewards
	return open("reward", a)

func confirm(title: String, message: String, ok_text: String, on_ok: Callable, danger := false) -> Sheet:
	return open("confirm", {"title": title, "message": message, "ok": ok_text, "on_ok": on_ok, "danger": danger})

func open_shop() -> void:
	if top_route() == "shop":
		return
	push("shop")

func sheet_open(name: String) -> bool:
	for c in sheet_layer.get_children():
		if not c.is_queued_for_deletion() and c.get_meta("route", "") == name:
			return true
	return false

# ------------------------------------------------------------------ Oyun akışı

## Bölümü başlat: enerji kapısı (yetmezse EnergyGate), sonra oyun ekranı.
## replace_game: oyun ekranındaysa üstüne değil yerine koy (sonraki bölüm).
func play(id: String, replace_game := true) -> void:
	if not Energy.start_game(id):
		open("energy", {"level": id})
		return
	if top_route() == "game" and replace_game:
		replace("game", {"level": id})
	else:
		push("game", {"level": id}, "curtain")

## Bölüm id'sinden LevelData üret.
func level_data(id: String) -> LevelData:
	var parts := Progress.split_id(id)
	var p: String = parts[0]
	var n: int = parts[1]
	match p:
		"daily":
			return DailyPuzzle.today(clampi(n, 0, Progress.DAILY_LEVELS - 1))
		"endless":
			return LevelGenerator.generate("endless", n, Progress.endless_grid(n), randi())
		"tower":
			return LevelGenerator.generate("tower", n, Tower.grid_size(n), randi())
	return LevelGenerator.generate(p, n, int(Progress.pack(p).get("grid", 5)))

## Eski API (Dev/test).
func current_level() -> LevelData:
	if OS.get_environment("SNUG_DAILY") != "":
		return DailyPuzzle.today(0)
	return level_data(Progress.level_id(pack, index))

# ------------------------------------------------------------------ Bilgi balonu

func toast(text: String, icon := "", col := Palette.SAGE) -> void:
	if fx_layer == null:
		return
	var t := Toast.new()
	t.text = text
	t.icon_name = icon
	t.col = col
	fx_layer.add_child(t)
	var y := Ui.safe_top() + 24.0 + _toast_y * 124.0
	_toast_y += 1
	t.play(y)
	t.tree_exited.connect(func() -> void: _toast_y = maxi(0, _toast_y - 1))

func _on_version(state: String) -> void:
	if host == null:
		return
	if state in ["forced", "soft"] and gate_layer.get_child_count() == 0:
		open("version", {"forced": state == "forced"})
