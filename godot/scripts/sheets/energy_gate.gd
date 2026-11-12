extends Sheet
## Enerji bitti: uyuyan Snuglo + çay fincanı, canlı sayaç ("⚡ n/50 · oynamaya m:ss"), ödüllü reklam
## (+10, sonra otomatik başlar), Premium (sınırsız), Kapat. Enerji yetince bölüm kendiliğinden açılır.
## args: level (başlatılacak bölüm id'si; boşsa yalnız bilgi).

var _live: Label
var _bar: Widgets.StitchBar
var _launched := false
var _acc := 0.0
## Yalnız açılışta enerji yetmiyorsa (gerçek kapı) dolunca otomatik başlat.
var _was_short := true

func _init() -> void:
	panel_size = Vector2(-1, 980)

func build() -> void:
	_was_short = not Energy.can_start_game()
	var w := pw()
	if Fly.target_bar("energy") == null:
		var topbar := TopBar.new()
		topbar.currencies = ["energy"]
		topbar.tap_to_shop = false
		topbar.position = Vector2((size.x - 250) / 2.0, Ui.safe_top() + 30)
		topbar.size = Vector2(250, 120)
		add_child(topbar)
	var m := Ui.icon("sleep", Vector2(300, 280), "mascot")
	add(m, Vector2(w / 2.0 - 260, -150))
	Ui.pop_in(m, 0.1, 0.3)
	var cup := Ui.icon("ic_energy", Vector2(220, 220))
	add(cup, Vector2(w / 2.0 + 10, -110))
	Ui.pop_in(cup, 0.2, 0.2)
	Ui.bob(cup, 8.0, 2.0)
	var y := _ribbon(tr("energy.out.title"), 130)
	y = body(tr("energy.out.message"), y, 34)
	y += 20
	_bar = Widgets.StitchBar.new()
	_bar.col = Palette.TEA
	_bar.value = float(Energy.current) / Energy.MAX
	add(_bar, Vector2(90, y), Vector2(w - 180, 36))
	y += 50
	_live = Ui.label("", 36, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	add(_live, Vector2(0, y), Vector2(w, 50))
	y += 80
	_tick()
	if Ads.rewarded_ready():
		var ad := Ui.button(tr("energy.watchAd") % Energy.AD_REFILL, "sage", Vector2(w - 140, 150), "ic_energy")
		add(ad, Vector2(70, y))
		ad.tapped.connect(func() -> void:
			ad.disabled = true
			Ads.show_rewarded(func() -> void:
				Energy.add(Energy.AD_REFILL)
				Fly.currency(ad.global_position + ad.size / 2.0, "energy", Energy.AD_REFILL)
				Sfx.play("reward")
				_bar.value = float(Energy.current) / Energy.MAX
				_tick()))
		Ui.pop_in(ad, 0.3, 0.6)
		y += 170
	if not Purchases.is_premium():
		var prem := Ui.button(tr("energy.goPremium"), "mustard", Vector2(w - 140, 130), "ic_crown")
		add(prem, Vector2(70, y))
		prem.tapped.connect(func() -> void:
			close()
			Main.open("premium"))
		Ui.pop_in(prem, 0.36, 0.6)
		y += 150
	var cl := Ui.button(tr("button.close"), "terracotta", Vector2(w - 140, 120))
	add(cl, Vector2(70, y))
	cl.tapped.connect(close)
	panel.size.y = y + 160
	_place_panel()
	panel.position.y += 80

func _process(dt: float) -> void:
	_acc += dt
	if _acc >= 0.5:
		_acc = 0.0
		_tick()

func _tick() -> void:
	if _launched:
		return
	var cur := Energy.current
	if Energy.can_start_game():
		_live.text = "%d/%d" % [cur, Energy.MAX]
		var id := String(args.get("level", ""))
		if id != "" and not _closing and _was_short:
			_launched = true
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				close()
				Main.play(id))
		return
	_live.text = "%d/%d  ·  %s" % [cur, Energy.MAX, tr("energy.playable") % Ui.fmt_time(Energy.seconds_until_playable())]


func _ribbon(text: String, y: float, w := 680.0) -> float:
	var b := Ui.banner(text, w)
	add(b, Vector2((pw() - b.size.x) / 2.0, y))
	Ui.pop_in(b, 0.15, 0.4)
	return y + b.size.y + 10.0
