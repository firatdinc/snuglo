extends Node
## Noel: Noel Köyü (4 ASMR mini oyun), santa şapkaları, kar, 25 Aralık hediye kutusu.
## Açık penceresi: varsayılan 1 Ara – 6 Oca; LiveConfig gist'inde "seasons" → "xmas-village"
## {enabled, start, end} ile uzaktan değiştirilir (enabled=false → tamamen kapalı).
## Kayıt (Save "xmas"): {tree: {..., orn_extra: [...], lv: n}, cookie: {...}, gift_box: bool}
## Her mini oyun kendi alt sözlüğünü `data(<oyun>)` ile alır, değiştirince `Xmas.save()` çağırır.

signal changed

const ID := "xmas-village"
const DEFAULT_START := "12-01"
const DEFAULT_END := "01-06"
const GAMES := ["tree", "cookie", "wish"]
const GIFT_DAY := "12-25"
const GIFT_REWARD := {"gem": 50, "coin": 500, "key": 3}

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)
	LiveConfig.changed.connect(func() -> void: changed.emit())

func _load() -> void:
	_s = Save.get_section("xmas")
	for g in GAMES:
		if not (_s.get(g) is Dictionary):
			_s[g] = {}

func data(game: String) -> Dictionary:
	if not (_s.get(game) is Dictionary):
		_s[game] = {}
	return _s[game]

func save() -> void:
	Save.mark_dirty()
	changed.emit()

# ---------------------------------------------------------------- kiler (kurabiye malzemeleri)
## Hamur için un/şeker/yumurta/tereyağı gerekir; günlük Noel görevleri (bölüm, süs, pişir) ve
## kış/advent bulmaca bölümü (rastgele 1 malzeme) ile kazanılır ya da düğmeyle satın alınır (pahalı). 1 parti = her birinden 1
## → 3 kurabiye (en çok 3 parti). İlk ziyarette 1 partilik başlangıç hediyesi.
const INGR := ["flour", "sugar", "egg", "butter"]
const BATCH_COOKIES := 3
const MAX_BATCHES := 3
signal ingredients_added(got: Dictionary)

func pantry() -> Dictionary:
	var c := data("cookie")
	if not (c.get("pantry") is Dictionary):
		c.pantry = {"flour": 1, "sugar": 1, "egg": 1, "butter": 1}   # başlangıç hediyesi
	return c.pantry

func batches_available() -> int:
	var p := pantry()
	var n := MAX_BATCHES
	for k in INGR:
		n = mini(n, int(p.get(k, 0)))
	return n

func add_ingredients(got: Dictionary) -> void:
	var p := pantry()
	for k in got:
		p[k] = int(p.get(k, 0)) + int(got[k])
	save()
	ingredients_added.emit(got)
	var parts: PackedStringArray = []
	for k in got:
		parts.append("+%d %s" % [int(got[k]), TranslationServer.translate("xmas.ing." + String(k))])
	if Main.has_method("toast"):
		Main.toast(", ".join(parts), "ic_gift")

func use_batches(n: int) -> void:
	var p := pantry()
	for k in INGR:
		p[k] = maxi(0, int(p.get(k, 0)) - n)
	save()

# ---------------------------------------------------------------- fırın (gerçek zamanlı)
## Ayarlanan süre GERÇEK dakikadır (5–15). Fırın çalışırken oyuncu bulmaca oynarsa bölüm altını ve
## XP'si +%10 (doğru bölge) / +%5 artar. Süre bitince kurabiyeler hazır (bildirim gelir).
signal oven_changed

func oven() -> Dictionary:
	var c := data("cookie")
	return c.oven if c.get("oven") is Dictionary else {}

func oven_busy() -> bool:
	return not oven().is_empty()

func start_oven(minutes: int, pct: int, goal: float) -> void:
	var now := int(Time.get_unix_time_from_system())
	var dur := minutes * 60
	var dv := Dev.env("SNUG_BAKE_SEC")
	if dv != "":
		dur = int(dv)
	data("cookie").oven = {"start": now, "dur": dur, "pct": pct, "goal": goal}
	save()
	oven_changed.emit()
	task_event("bake")
	if Notify.has_method("schedule_cookie"):
		Notify.schedule_cookie(float(dur))

## 0..1 pişme ilerlemesi (fırın boşsa 0).
func oven_progress() -> float:
	var o := oven()
	if o.is_empty():
		return 0.0
	return clampf((Time.get_unix_time_from_system() - float(o.start)) / maxf(1.0, float(o.dur)), 0.0, 1.0)

func oven_seconds_left() -> int:
	var o := oven()
	if o.is_empty():
		return 0
	return maxi(0, int(float(o.start) + float(o.dur) - Time.get_unix_time_from_system()))

func oven_ready() -> bool:
	return oven_busy() and oven_progress() >= 1.0

func clear_oven() -> void:
	data("cookie").erase("oven")
	save()
	oven_changed.emit()

## Pişerken bölüm ödülü bonusu (yüzde). Fırın boş ya da bitmişse 0.
func cookie_boost_pct() -> int:
	if not oven_busy() or oven_ready():
		return 0
	return int(oven().get("pct", 5))

# ---------------------------------------------------------------- kurabiye kavanozu + takas
const TRADE_COOKIES := 6
const TRADES := [
	{"id": "energy", "cost": 6, "give": {"energy": 10}},
	{"id": "coin", "cost": 6, "give": {"coin": 150}},
	{"id": "big", "cost": 12, "give": {"energy": 20, "coin": 300}},
]

func jar() -> int:
	return int(data("cookie").get("jar", 0))

func add_to_jar(n: int) -> void:
	data("cookie").jar = jar() + n
	save()

func can_trade(i: int) -> bool:
	return i >= 0 and i < TRADES.size() and jar() >= int(TRADES[i].cost)

func trade(i: int) -> Dictionary:
	if not can_trade(i):
		return {}
	var t: Dictionary = TRADES[i]
	data("cookie").jar = jar() - int(t.cost)
	var give: Dictionary = t.give
	if give.has("energy"):
		Energy.add(int(give.energy))
	var w := {}
	for k in give:
		if k != "energy":
			w[k] = give[k]
	if not w.is_empty():
		Wallet.grant(w, "xmas_trade")
	save()
	return give

# ---------------------------------------------------------------- malzeme satın alma
## Pişirmek bölüm altını/XP'yi +%5..10 artırır; bölüm başına ~20-40 düğme kazanılır (Progress.level_coins),
## bu yüzden malzeme satın almak oynayarak kazanmaktan hep daha kötü: 1 malzeme = 150, 1 parti = 600.
const ING_PRICE := 150
const SET_PRICE := 600          ## 1 parti malzeme (4 × ING_PRICE, indirimsiz)
const SET_GEMS := 6             ## Mağaza paketi: 1 parti, yüksükle

func buy_ingredient(k: String, currency := "coin") -> bool:
	if not k in INGR or currency != "coin" or Wallet.balance("coin") < ING_PRICE:
		return false
	Wallet.spend("coin", ING_PRICE, "xmas_ingredient")
	add_ingredients({k: 1})
	return true

## Tam parti (1 un + 1 şeker + 1 yumurta + 1 tereyağı). cookie.gd bunu çağırır; ad/imza değişmedi.
func buy_set(currency := "coin") -> bool:
	var price := SET_GEMS if currency == "gem" else SET_PRICE
	if currency != "coin" and currency != "gem":
		return false
	if Wallet.balance(currency) < price:
		return false
	Wallet.spend(currency, price, "xmas_ingredients")
	add_ingredients({"flour": 1, "sugar": 1, "egg": 1, "butter": 1})
	return true

# ---------------------------------------------------------------- süsler (ağaç tepsisi)
## İlk 4 süs açık; sonrakiler advent günü başına bir tane. Ek yollar: Noel döneminde her 4. bölüm
## sıradaki kilitli süsü ücretsiz açar, ya da kilitli süs ORN_PRICE düğmeyle alınır (kayıt: tree.orn_extra).
const ORN_ORDER: Array[String] = ["ball_red", "ball_gold", "ball_green", "star_top", "candy_cane", "bell",
	"ball_blue", "gingerbread_orn", "snowflake_orn", "bow_orn", "heart_orn", "ball_pink"]
const ORN_START_OPEN := 4
const ORN_PRICE := 250
const ORN_LEVEL_EVERY := 4

func orn_unlock_day(kind: String) -> int:
	var i := ORN_ORDER.find(kind)
	return 0 if i < ORN_START_OPEN else i - ORN_START_OPEN + 1

func orn_open(kind: String) -> bool:
	if advent_day() >= orn_unlock_day(kind):
		return true
	return kind in (data("tree").get("orn_extra", []) as Array)

func orn_next_locked() -> String:
	for k in ORN_ORDER:
		if not orn_open(k):
			return k
	return ""

func _orn_unlock(kind: String) -> void:
	var t := data("tree")
	if not (t.get("orn_extra") is Array):
		t.orn_extra = []
	if not kind in t.orn_extra:
		t.orn_extra.append(kind)
	save()

func orn_buy(kind: String) -> bool:
	if orn_open(kind) or Wallet.balance("coin") < ORN_PRICE:
		return false
	Wallet.spend("coin", ORN_PRICE, "xmas_ornament")
	_orn_unlock(kind)
	return true

# ---------------------------------------------------------------- Noel görevleri (günlük)
## Her gün 3 görev (hepsi); her biri bir malzeme ödülü verir. Sayaçlar: level, tree, bake.
const TASKS := [
	{"id": "level", "n": 3, "give": {"flour": 1, "sugar": 1}},
	{"id": "tree", "n": 4, "give": {"egg": 1, "butter": 1}},
	{"id": "bake", "n": 1, "give": {"flour": 1, "egg": 1}},
]
const TASKS_VER := 2

func tasks_today() -> Array:
	var c := data("cookie")
	var day := _today()
	if c.get("task_day", "") != day or int(c.get("task_ver", 0)) != TASKS_VER:
		c.task_day = day
		c.task_ver = TASKS_VER
		c.tasks = []
		for i in TASKS.size():
			c.tasks.append({"i": i, "p": 0, "done": false})
		save()
	return c.tasks

func task_event(kind: String, amount := 1) -> void:
	if not is_active():
		return
	for t: Dictionary in tasks_today():
		var d: Dictionary = TASKS[int(t.i)]
		if d.id == kind and not t.done:
			t.p = mini(int(d.n), int(t.p) + amount)
			if int(t.p) >= int(d.n):
				t.done = true
				add_ingredients(d.give)
	save()

## Kış/advent bulmaca bölümü kazanılınca (Progress.record_level).
func on_season_level(id: String) -> void:
	task_event("level")
	if is_active():
		var t := data("tree")
		t.lv = int(t.get("lv", 0)) + 1
		if int(t.lv) % ORN_LEVEL_EVERY == 0:
			var k := orn_next_locked()
			if k != "":
				_orn_unlock(k)
				if Main.has_method("toast"):
					Main.toast(TranslationServer.translate("xmas.orn.gift"), "ic_star")
		else:
			save()
	if winter_active() and (id.begins_with("winter-quilt") or id.begins_with("advent-quilt")):
		add_ingredients({INGR[randi() % INGR.size()]: 1})

func _today() -> String:
	return Progress.local_key()

## "YYYY-MM-DD" bugün pencere içinde mi (yıl dönümü aşan pencere desteklenir).
static func in_window(today: String, start_md: String, end_md: String) -> bool:
	var md := today.substr(5)
	if start_md <= end_md:
		return md >= start_md and md <= end_md
	return md >= start_md or md <= end_md

func is_active() -> bool:
	if Dev.env("SNUG_XMAS") != "":
		return true
	var cfg := LiveConfig.season(ID)
	if cfg.has("enabled") and not bool(cfg.enabled):
		return false
	var st := String(cfg.get("start", "")).substr(5) if String(cfg.get("start", "")).length() >= 10 else DEFAULT_START
	var en := String(cfg.get("end", "")).substr(5) if String(cfg.get("end", "")).length() >= 10 else DEFAULT_END
	return in_window(_today(), st, en)

## Kış havası (menüde kar + kahve sahnesi): varsayılan 18 Kas – 28 Şub; LiveConfig "winter-menu".
func winter_active() -> bool:
	if Dev.env("SNUG_XMAS") != "" or Dev.env("SNUG_WINTER") != "":
		return true
	var cfg := LiveConfig.season("winter-menu")
	if cfg.has("enabled") and not bool(cfg.enabled):
		return false
	var st := String(cfg.get("start", "")).substr(5) if String(cfg.get("start", "")).length() >= 10 else "11-18"
	var en := String(cfg.get("end", "")).substr(5) if String(cfg.get("end", "")).length() >= 10 else "02-28"
	return in_window(_today(), st, en)

## Santa şapkası: Noel açıkken peluş dostlar + maskot şapkalı (ayar ile kapatılabilir).
func hats_on() -> bool:
	return is_active() and Settings.get_value("xmas_hats") != false

## Advent'te bugüne kadar açılan gün (1..24); Aralık değilse 0 ya da 24.
func advent_day() -> int:
	var d := Dev.env("SNUG_ADVENT_DAY")
	if d != "":
		return clampi(int(d), 0, 24)
	var t := _today()
	var m := int(t.substr(5, 2))
	if m == 12:
		return mini(24, int(t.substr(8, 2)))
	if m == 1:
		return 24
	return 0

func days_to_christmas() -> int:
	var t := _today()
	var y := int(t.substr(0, 4))
	var now := Time.get_unix_time_from_datetime_string(t + "T00:00:00")
	var xmas := Time.get_unix_time_from_datetime_string("%d-12-25T00:00:00" % y)
	if now > xmas:
		return 0
	return int((xmas - now) / 86400)

func gift_box_ready() -> bool:
	if bool(_s.get("gift_box", false)):
		return false
	if Dev.env("SNUG_XMAS_GIFT") != "":
		return true
	var md := _today().substr(5)
	return is_active() and (md >= GIFT_DAY or md <= DEFAULT_END)

func claim_gift_box() -> Dictionary:
	if not gift_box_ready():
		return {}
	_s.gift_box = true
	Wallet.grant(GIFT_REWARD, "xmas_gift")
	save()
	return GIFT_REWARD

## Mini oyun ilerleme özeti (köy kartları için): 0..1.
func progress_of(game: String) -> float:
	var d := data(game)
	return clampf(float(d.get("progress", 0.0)), 0.0, 1.0)

# ---------------------------------------------------------------- Yeni Yıl Dileği
## Kayıt (xmas.wish): {text, date: "YYYY-MM-DD", sealed: bool, draft: String, progress}
## 31 Aralık'a kadar düzenlenir; Ocak'ta salt okunur + "Mutlu yıllar" başlığı. 1 Ocak 09:00'da bildirim.
const WISH_MAX := 120

func wish() -> Dictionary:
	return data("wish")

func wish_sealed() -> bool:
	return bool(wish().get("sealed", false)) and String(wish().get("text", "")) != ""

## Yeni yıl kutlama kipi: Ocak (geliştirmede SNUG_NEWYEAR).
func wish_new_year() -> bool:
	return Dev.env("SNUG_NEWYEAR") != "" or int(_today().substr(5, 2)) == 1

## Dilek yazılabilir/düzenlenebilir mi (Ocak'ta hayır).
func wish_editable() -> bool:
	return not wish_new_year()

## Kartın üstündeki yıl: Aralık'ta gelecek yıl, Ocak'ta içinde bulunulan yıl.
func wish_year() -> int:
	var y := int(_today().substr(0, 4))
	return y if int(_today().substr(5, 2)) == 1 else y + 1

func seal_wish(text: String) -> void:
	var w := wish()
	w.text = text.strip_edges().substr(0, WISH_MAX)
	w.date = _today()
	w.sealed = true
	w.erase("draft")
	w.progress = 1.0
	save()
	if wish_editable() and Notify.has_method("schedule_wish"):
		Notify.schedule_wish(seconds_to_new_year(), String(w.text))

func unseal_wish() -> void:
	var w := wish()
	if not wish_editable():
		return
	w.sealed = false
	w.draft = w.get("text", "")
	w.progress = 0.0
	save()
	if Notify.has_method("cancel_wish"):
		Notify.cancel_wish()

## Yerel saatle 1 Ocak 09:00'a kalan saniye (geçmişse 60).
func seconds_to_new_year() -> float:
	var now := Time.get_datetime_dict_from_system(false)
	var target := {"year": wish_year(), "month": 1, "day": 1, "hour": 9, "minute": 0, "second": 0}
	return maxf(60.0, float(Time.get_unix_time_from_datetime_dict(target) - Time.get_unix_time_from_datetime_dict(now)))

func reset() -> void:
	for g in GAMES:
		_s[g] = {}
	_s.gift_box = false
	save()
