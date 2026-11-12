extends Sheet
## Sürüm kapısı (Swift UpdateRequiredView). args.forced: kapatılamaz güncelleme duvarı; değilse
## "yeni sürüm" kartı (kapat → VersionGate.dismiss_soft()).

var _forced := false

func _init() -> void:
	panel_size = Vector2(-1, 1000)
	panel_fabric = 6
	dim_alpha = 0.85

func build() -> void:
	_forced = bool(args.get("forced", false))
	dismissible = not _forced
	panel.inner = 26
	var w := pw()
	var sloth := Ui.icon("sleep" if _forced else "wave", Vector2(380, 360), "mascot")
	add(sloth, Vector2((w - 380) / 2.0, -170))
	Ui.pop_in(sloth, 0.1, 0.3, 0.6)
	Ui.bob(sloth, 6.0, 3.0)
	var pre := "update.required." if _forced else "update.soft."
	var y := heading(tr(pre + "title"), 220, 62)
	y = body(tr(pre + "message"), y + 10, 38)
	if VersionGate.latest_version != "":
		var v := Ui.label("%s → %s" % [VersionGate.current_version(), VersionGate.latest_version], 32, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		add(v, Vector2(0, y + 10), Vector2(w, 50))
		y += 60
	y += 40
	var cta := Ui.button(tr(pre + "cta"), "terracotta", Vector2(w - 160, 160), "", 50)
	add(cta, Vector2(80, y))
	cta.tapped.connect(func() -> void: VersionGate.open_store())
	Ui.pop_in(cta, 0.35, 0.6)
	y += 180
	if not _forced:
		var later := Ui.button(tr("announcement.dismiss"), "sage", Vector2(w - 300, 110), "", 38)
		add(later, Vector2(150, y))
		later.tapped.connect(close)
		y += 130
	panel.size.y = y + 30
	_place_panel()
	panel.position.y += 80

func on_back() -> bool:
	if not _forced:
		close()
	return true

func close() -> void:
	if _forced:
		return
	VersionGate.dismiss_soft()
	super()
