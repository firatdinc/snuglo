extends Sheet
## Onay penceresi. args: title, message, ok (buton metni), on_ok (Callable), danger (kırmızı),
## cancel (metin, varsayılan common.cancel), icon (art/ui ikon adı, isteğe bağlı).

func _init() -> void:
	panel_size = Vector2(-1, 600)

func build() -> void:
	var y := 50.0
	if args.has("icon"):
		var ic := Ui.icon(String(args.icon), Vector2(150, 150))
		add(ic, Vector2((pw() - 150) / 2.0, -60))
		Ui.pop_in(ic, 0.1, 0.3)
		y = 100.0
	y = heading(String(args.get("title", "")), y, 56)
	if String(args.get("message", "")) != "":
		y = body(String(args.message), y + 10, 36)
	y += 40
	var bw := (pw() - 180) / 2.0
	var cancel := Ui.button(String(args.get("cancel", tr("common.cancel"))), "sage", Vector2(bw, 130))
	add(cancel, Vector2(70, y))
	cancel.tapped.connect(close)
	var ok := Ui.button(String(args.get("ok", tr("common.ok"))), "terracotta" if args.get("danger", false) else "mustard", Vector2(bw, 130))
	add(ok, Vector2(110 + bw, y))
	ok.tapped.connect(func() -> void:
		close()
		var cb: Variant = args.get("on_ok")
		if cb is Callable and (cb as Callable).is_valid():
			(cb as Callable).call())
	panel.size.y = y + 180
	_place_panel()
