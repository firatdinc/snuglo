extends Node
## Oyuncu ilerlemesi (Swift ProgressStore + PackRewardStore + EndlessStore portu).
## Bölüm sonuçları, kilitler, günlük bulmaca (UTC) + seri, oynama serisi (yerel gün),
## seri dondurma, kazanma zinciri, paket tamamlama ödülü ve İstatistik ekranı verisi.
## `record_level()` tek giriş noktası: tüm ödülleri (cüzdan, XP, görev, başarım, sandık) uygular.

## 17 paket × 60 = 1020 bölüm (Swift MockData). Hepsi ücretsiz, İLERLEMEYLE açılır: paket N,
## N-1 tamamen bitince (premium hepsini açar). art/scene: PackArt teması (Nook sahnesi + maskot).
const PACKS := [
	{"id": "cozy-beginnings", "title": "pack.cozy_beginnings.title", "grid": 5, "levels": 60, "art": "mascot-sloth", "scene": "scene-island"},
	{"id": "spice-route", "title": "pack.spice_route.title", "grid": 6, "levels": 60, "art": "fox", "scene": "scene-forest"},
	{"id": "mambo-nights", "title": "pack.mambo_nights.title", "grid": 7, "levels": 60, "art": "owl", "scene": "scene-mushroom"},
	{"id": "woodland-retreat", "title": "pack.woodland_retreat.title", "grid": 8, "levels": 60, "art": "hedgehog", "scene": "scene-autumn"},
	{"id": "morning-meadow", "title": "pack.morning_meadow.title", "grid": 5, "levels": 60, "art": "cow", "scene": "scene-flower"},
	{"id": "amber-harbor", "title": "pack.amber_harbor.title", "grid": 6, "levels": 60, "art": "lion", "scene": "scene-desert"},
	{"id": "velvet-dusk", "title": "pack.velvet_dusk.title", "grid": 7, "levels": 60, "art": "bee", "scene": "scene-waterfall"},
	{"id": "hearth-tales", "title": "pack.hearth_tales.title", "grid": 8, "levels": 60, "art": "mascot-hippo", "scene": "scene-lake"},
	{"id": "misty-grove", "title": "pack.misty_grove.title", "grid": 5, "levels": 60, "art": "cactus", "scene": "scene-desert"},
	{"id": "honey-fields", "title": "pack.honey_fields.title", "grid": 6, "levels": 60, "art": "tomato", "scene": "scene-flower"},
	{"id": "lantern-lane", "title": "pack.lantern_lane.title", "grid": 7, "levels": 60, "art": "mascot-rabbit", "scene": "scene-beach"},
	{"id": "frost-haven", "title": "pack.frost_haven.title", "grid": 8, "levels": 60, "art": "sand", "scene": "scene-beach"},
	{"id": "garden-party", "title": "pack.garden_party.title", "grid": 5, "levels": 60, "art": "mascot-tiger", "scene": "scene-volcano"},
	{"id": "ocean-breeze", "title": "pack.ocean_breeze.title", "grid": 6, "levels": 60, "art": "Rabbit", "scene": "scene-snow"},
	{"id": "starlit-peak", "title": "pack.starlit_peak.title", "grid": 7, "levels": 60, "art": "Carrot", "scene": "scene-lake"},
	{"id": "cocoa-cabin", "title": "pack.cocoa_cabin.title", "grid": 8, "levels": 60, "art": "mascot-sloth", "scene": "scene-island"},
	{"id": "aurora-vale", "title": "pack.aurora_vale.title", "grid": 8, "levels": 60, "art": "fox", "scene": "scene-forest"},
]
const LEVELS_PER_PACK := 60
const TOTAL_LEVELS := 1020
## Günde 5 günlük bölüm (Swift ProgressStore.dailyLevelCount), sırayla açılır, index 0..4.
const DAILY_LEVELS := 5
const STREAK_MILESTONES := [3, 7, 14, 30, 60, 100]
const FREEZE_COST_GEMS := 5
## Paket tamamlama ödülü (PackRewardStore 200+25, MainMenu +2 anahtar).
const PACK_REWARD := {"coin": 200, "gem": 25, "key": 2}
## Rahat mod (zen/endless) günlük tavanı (Swift RelaxedRewardStore): çözüm başına 10 XP + 5 coin,
## günde en çok 50 XP + 25 coin, gem yok.
const RELAXED_XP := 10
const RELAXED_COIN := 5
const RELAXED_MAX_XP := 50
const RELAXED_MAX_COIN := 25
## Bölüm içi kombo: art arda hızlı yerleşim penceresi (sn) ve kilometre taşları.
const COMBO_WINDOW := 2.5
const COMBO_MILESTONES := [3, 5, 8]

## Test/debug: "yyyy-MM-dd" verilirse hem yerel hem UTC "bugün" bu olur.
var today_override := ""

## Oturumluk kazanma zinciri (başarısızlık/çıkış kırar; kaydedilmez).
var win_chain := 0

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(func() -> void:
		_load()
		Events.streak_changed.emit())

## Ön plana dönünce gün değişmiş olabilir → serileri tazele.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and _s.has("played_days"):
		refresh_streaks()

func _load() -> void:
	_s = Save.get_section("progress")
	var defaults := {
		"levels": {}, "daily": {"date": "", "count": 0}, "daily_results": {},
		"daily_longest": 0, "played_days": [], "longest_play_streak": 0,
		"last_rewarded_streak": 0, "pending_streak_milestone": 0, "streak_freezes": 0,
		"endless_best": 0, "pack_rewarded": [], "pack_pending": "", "best_win_chain": 0,
		"relaxed": {"day": "", "xp": 0, "coin": 0}, "sessions": {},
	}
	for k in defaults:
		if not _s.has(k):
			_s[k] = defaults[k]
	win_chain = 0
	refresh_streaks()
	# Eski serilere açılışta ödül patlatma: sessizce yakala (Swift load ile aynı).
	_s.last_rewarded_streak = maxi(int(_s.last_rewarded_streak), _highest_milestone(play_streak))

# ============================================================ Gün yardımcıları

## Bugünün yerel tarih anahtarı "yyyy-MM-dd" (oynama serisi, görevler, çark, giriş ödülü).
func local_key() -> String:
	return today_override if today_override != "" else Time.get_date_string_from_system(false)

## Bugünün UTC tarih anahtarı (günlük bulmaca; engine/daily_puzzle.gd ile aynı).
func utc_key() -> String:
	return today_override if today_override != "" else Time.get_date_string_from_system(true)

## {year, month, day} (yerel ya da UTC bugün).
func local_date(utc := false) -> Dictionary:
	var k := utc_key() if utc else local_key()
	return {"year": int(k.substr(0, 4)), "month": int(k.substr(5, 2)), "day": int(k.substr(8, 2))}

## Tarih anahtarı → epoch'tan gün sayısı.
static func day_number(key: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(key + "T00:00:00") / 86400)

static func key_from_number(n: int) -> String:
	return Time.get_date_string_from_unix_time(n * 86400)

static func key_add(key: String, days: int) -> String:
	return key_from_number(day_number(key) + days)

## Bugünün yerel gün numarası (rotasyonlar için).
func local_day() -> int:
	return day_number(local_key())

## Cihaz saati geri alındı mı: bugün, görülmüş en ileri yerel günden önceyse true. Günlük
## ödüller (giriş, takvim, çark, görev ve reklam sınırı sıfırlaması) bu durumda açılmaz.
func clock_rewound() -> bool:
	var d := local_day()
	if d > int(_s.get("max_day", 0)):
		_s.max_day = d
		Save.mark_dirty()
	return d < int(_s.max_day)

# ============================================================ Paketler / kilitler

func pack(pack_id: String) -> Dictionary:
	for p in PACKS:
		if p.id == pack_id:
			return p
	return {}

func pack_index(pack_id: String) -> int:
	for i in PACKS.size():
		if PACKS[i].id == pack_id:
			return i
	return -1

## İlk paket hep açık; paket N, N-1 TAMAMEN bitince açılır. Premium hepsini açar.
func is_pack_unlocked(pack_id: String) -> bool:
	var i := pack_index(pack_id)
	if i < 0:
		return false
	if i == 0 or Purchases.is_premium():
		return true
	return is_pack_complete(PACKS[i - 1].id)

## Bölüm 1 hep açık; N, N-1 tamamlanınca açılır (paket kilidinden bağımsız).
func is_level_unlocked(pack_id: String, index: int) -> bool:
	return index == 1 or is_completed(level_id(pack_id, index - 1))

## Oynanabilir mi: paket açık + bölüm açık.
func can_play(pack_id: String, index: int) -> bool:
	return is_pack_unlocked(pack_id) and is_level_unlocked(pack_id, index)

static func level_id(pack_id: String, index: int) -> String:
	return "%s-%d" % [pack_id, index]

## "spice-route-12" → ["spice-route", 12]; uyumsuzsa ["", 0].
static func split_id(id: String) -> Array:
	var cut := id.rfind("-")
	if cut <= 0 or not id.substr(cut + 1).is_valid_int():
		return ["", 0]
	return [id.left(cut), int(id.substr(cut + 1))]

func level(id: String) -> Dictionary:
	return (_s.levels as Dictionary).get(id, {})

func is_completed(id: String) -> bool:
	return bool(level(id).get("completed", false))

func stars(id: String) -> int:
	return int(level(id).get("stars", 0))

## En iyi süre (sn); hiç çözülmediyse -1.
func best_time(id: String) -> float:
	return float(level(id).get("best_time", -1.0))

func pack_completed_count(pack_id: String) -> int:
	var n := 0
	for id in _s.levels:
		if String(id).begins_with(pack_id + "-") and _s.levels[id].get("completed", false):
			n += 1
	return n

func pack_stars(pack_id: String) -> int:
	var n := 0
	for id in _s.levels:
		if String(id).begins_with(pack_id + "-"):
			n += int(_s.levels[id].get("stars", 0))
	return n

func is_pack_complete(pack_id: String) -> bool:
	var p := pack(pack_id)
	return not p.is_empty() and pack_completed_count(pack_id) >= int(p.levels)

## Paket içindeki ilk tamamlanmamış bölüm (hepsi bittiyse 0).
func next_unplayed(pack_id: String) -> int:
	var p := pack(pack_id)
	for i in range(1, int(p.get("levels", 0)) + 1):
		if not is_completed(level_id(pack_id, i)):
			return i
	return 0

## "Devam" hedefi: ilerleme olan açık paket, yoksa ilk açık paket; sonraki oynanmamış bölüm.
## Hepsi bittiyse "".
func continue_target() -> String:
	var fallback := ""
	for p in PACKS:
		if not is_pack_unlocked(p.id):
			continue
		var nxt := next_unplayed(p.id)
		if nxt == 0:
			continue
		if pack_completed_count(p.id) > 0:
			return level_id(p.id, nxt)
		if fallback == "":
			fallback = level_id(p.id, nxt)
	return fallback

## Aynı paketteki sonraki bölüm id'si (son bölümse "").
func next_level_id(id: String) -> String:
	var parts := split_id(id)
	var p := pack(parts[0])
	if p.is_empty() or int(parts[1]) + 1 > int(p.levels):
		return ""
	return level_id(parts[0], int(parts[1]) + 1)

# ============================================================ Kurallar

## Süreye göre yıldız (Swift computeStars): taban = max(grid-4,1)*30 sn.
static func compute_stars(seconds: float, grid: int) -> int:
	var base := float(maxi(grid - 4, 1)) * 30.0
	if seconds <= base:
		return 3
	if seconds <= base * 2.0:
		return 2
	return 1

## Zamanlı modda süre sınırı: hücre başına 5 sn, en az 90 sn (zen/endless'ta yok).
static func time_limit(w: int, h: int) -> int:
	return maxi(90, w * h * 5)

## Bölüm sonu coin (MONETIZATION 2026-06-13 sıkılaştırması, CurrencyReward):
## yıldız*5 + (<60 sn ? 3). NOT: canlı GameViewModel.persistProgress hâlâ satır içi
## yıldız*10 + 5 kullanıyor (sıkılaştırma orada unutulmuş) — karar dokümandaki 5/3.
const COIN_PER_STAR := 5
const SPEED_BONUS := 3
static func level_coins(star_count: int, seconds: float) -> int:
	return maxi(0, star_count) * COIN_PER_STAR + (SPEED_BONUS if seconds < 60.0 else 0)

## Zincir bonusu: (zincir-1)*5, en çok +40. Her 5'li zincir +1 anahtar.
static func chain_bonus(chain: int) -> int:
	return 0 if chain < 2 else mini(40, (chain - 1) * 5)

## Seri kilometre taşı ödülü: coin = gün*10, 30+ günde gem = gün/30.
static func streak_reward(milestone: int) -> Dictionary:
	return {"coin": milestone * 10, "gem": maxi(1, milestone / 30) if milestone >= 30 else 0}

# ============================================================ Bölüm kaydı

## Çözülen bölümü kaydeder ve tüm ödülleri uygular (Swift persistProgress + GameView solve).
## level_id: "<paket>-<n>", "daily-<i>", "endless-<n>", "tower-<kat>". grid verilmezse
## id'den çıkarılır. Rahat mod = endless VEYA Settings.zen_mode: günlük tavanlı küçük
## XP/coin, gem/görev/sandık/zincir/skor yok. Dönen sözlük kazanma paneli içindir.
## relaxed_at_start: oyun ekranının bölüm başında dondurduğu rahat mod (1/0); -1 → şimdi hesapla.
## (Zen'i bölüm ortasında kapatıp tam ödül almak engellenir.)
func record_level(id: String, seconds: float, hints: int = 0, grid: int = 0, relaxed_at_start: int = -1) -> Dictionary:
	var mode := "campaign"
	for m in ["daily", "endless", "tower"]:
		if id.begins_with(m):
			mode = m
	if grid <= 0:
		grid = _grid_for(id, mode)
	var relaxed: bool = mode == "endless" or (Settings.zen_mode and mode != "tower")
	if relaxed_at_start >= 0:
		relaxed = relaxed_at_start == 1
	var star_count := compute_stars(seconds, grid)
	var res := {
		"level_id": id, "mode": mode, "relaxed": relaxed, "stars": star_count, "seconds": seconds,
		"hints": hints, "first_clear": false, "new_best": false, "prev_best": -1.0,
		"coins": 0, "gems": 0, "keys": 0, "chain": 0, "chain_bonus": 0, "xp": 0, "levels_gained": 0,
		"level_up": 0, "achievements": [], "quests_completed": [], "chest_ready": false,
		"pack_completed": "", "streak_milestone": 0, "endless_record": false,
		"daily_index": -1, "daily_all_done": false, "nook_piece": -1, "tower_record": false,
	}
	Energy.end_paid_session(id)
	clear_session(id)
	var was_three := false
	match mode:
		"campaign":
			var prev := level(id)
			res.first_clear = not bool(prev.get("completed", false))
			res.prev_best = float(prev.get("best_time", -1.0))
			res.new_best = res.prev_best >= 0.0 and seconds < res.prev_best
			was_three = int(prev.get("stars", 0)) >= 3
			_mark_completed(id, star_count, seconds, hints)
			var parts := split_id(id)
			var pid: String = parts[0]
			# Nook: her 10. bölümün İLK çözümü bir sahne parçası kazandırır.
			if res.first_clear and int(parts[1]) % Nook.LEVELS_PER_PIECE == 0:
				res.nook_piece = int(parts[1]) / Nook.LEVELS_PER_PIECE - 1
			if is_pack_complete(pid) and not pid in _s.pack_rewarded and _s.pack_pending == "":
				_s.pack_pending = pid
			res.pack_completed = pid if _s.pack_pending == pid else ""
		"daily":
			var idx := clampi(int(split_id(id)[1]), 0, DAILY_LEVELS - 1)
			res.daily_index = idx
			res.first_clear = not is_daily_solved(idx)
			_mark_daily(idx, seconds)
			res.daily_all_done = is_daily_all_complete()
		"endless":
			var n := int(split_id(id)[1])
			res.endless_record = n > int(_s.endless_best)
			if res.endless_record:
				_s.endless_best = n
			GameCenter.submit(GameCenter.ENDLESS_BEST, endless_best)
		"tower":
			res.tower_record = Tower.clear_floor(int(split_id(id)[1]))
	res.streak_milestone = int(_s.pending_streak_milestone)
	if relaxed:
		var g := _relaxed_grant(RELAXED_XP, RELAXED_COIN)
		res.coins = g.coin
		res.xp = g.xp
		Wallet.add("coin", g.coin, "relaxed")
		var before_r: int = XP.level
		res.levels_gained = XP.award(g.xp)
		res.level_up = XP.level if XP.level > before_r else 0
	else:
		# Coin gerçek yıldızla; gem YALNIZ kampanya bölümünün ilk 3★'ında (ömür boyu bir kez).
		res.coins = level_coins(star_count, seconds)
		res.gems = 1 if mode == "campaign" and not was_three and star_count >= 3 else 0
		if star_count >= 3:
			res.keys += 1
		# Kazanma zinciri (Kule hariç: kat geçişi GameView'da erken döner).
		if mode != "tower":
			win_chain += 1
			_s.best_win_chain = maxi(int(_s.best_win_chain), win_chain)
			res.chain = win_chain
			res.chain_bonus = chain_bonus(win_chain)
			res.coins += res.chain_bonus
			if win_chain % 5 == 0:
				res.keys += 1
		Wallet.grant({"coin": res.coins, "gem": res.gems, "key": res.keys}, "level")
		res.xp = 20 + star_count * 10
		var before: int = XP.level
		res.levels_gained = XP.award(res.xp)
		res.level_up = XP.level if XP.level > before else 0
		res.quests_completed = Quests.record_solve(int(seconds), hints, star_count)
		res.chest_ready = Chest.record_solve()
	Save.mark_dirty()
	res.achievements = Achievements.evaluate()
	if not relaxed:
		GameCenter.submit_progress()
	Events.level_completed.emit(id, star_count, seconds)
	if mode == "daily":
		Events.daily_solved.emit(res.daily_index)
	return res

## Rahat mod günlük tavanı: istenen XP/coin'i kalan paya kırpar.
func _relaxed_grant(xp: int, coin: int) -> Dictionary:
	var r: Dictionary = _s.relaxed
	if String(r.day) != local_key():
		r.day = local_key()
		r.xp = 0
		r.coin = 0
	var gx := clampi(xp, 0, RELAXED_MAX_XP - int(r.xp))
	var gc := clampi(coin, 0, RELAXED_MAX_COIN - int(r.coin))
	r.xp = int(r.xp) + gx
	r.coin = int(r.coin) + gc
	return {"xp": gx, "coin": gc}

func _grid_for(id: String, mode: String) -> int:
	if mode == "daily":
		var d := local_date(true)
		var unix := Time.get_unix_time_from_datetime_dict({"year": d.year, "month": d.month, "day": d.day, "hour": 12})
		return DailyPuzzle.grid_size(Time.get_datetime_dict_from_unix_time(unix).weekday)
	if mode == "endless":
		return endless_grid(int(split_id(id)[1]))
	if mode == "tower":
		return Tower.grid_size(int(split_id(id)[1]))
	return int(pack(split_id(id)[0]).get("grid", 5))

func _mark_completed(id: String, star_count: int, seconds: float, hints: int) -> void:
	var p: Dictionary = (_s.levels as Dictionary).get(id, {})
	p["completed"] = true
	p["stars"] = maxi(int(p.get("stars", 0)), star_count)
	var bt := float(p.get("best_time", -1.0))
	if bt < 0.0 or seconds < bt:
		p["best_time"] = seconds
	p["hints_used"] = mini(int(p.get("hints_used", hints)), hints)
	p["completed_at"] = local_key()
	_s.levels[id] = p
	_record_play_day()

## Seri kırılır (süre doldu / bölümden çıkış / yeniden başlat).
func break_chain() -> void:
	win_chain = 0

## Bölüm içi kombo ödülü (Swift GameView.registerCombo): kombo ≥2 → min(n,8)*2 coin,
## ×5 → +10, ×8 → +20 coin; gem yok; rahat modda coin yok. Dönüş {coins, milestone}.
func award_combo(count: int, relaxed := false) -> Dictionary:
	var r := {"coins": 0, "milestone": count in COMBO_MILESTONES}
	if count < 2 or relaxed:
		return r
	r.coins = mini(count, 8) * 2
	if count == 5:
		r.coins += 10
	elif count == 8:
		r.coins += 20
	Wallet.add("coin", r.coins, "combo")
	return r

# ============================================================ Yarım kalan bölüm (devam)

## Yalnız deterministik bölümler (kampanya + günlük) kaydedilir. session: UI'nın verdiği
## sözlük (Swift GameSession: fingerprint, placements [{piece, x, y}], elapsed, moves,
## hints, history [piece id]). Bölüm çözülünce record_level siler.
static func is_resumable(id: String) -> bool:
	return not (id.begins_with("endless") or id.begins_with("tower"))

func save_session(id: String, session: Dictionary) -> void:
	if not is_resumable(id):
		return
	_s.sessions[id] = session
	Save.mark_dirty()

func get_session(id: String) -> Dictionary:
	return (_s.sessions as Dictionary).get(id, {})

func clear_session(id: String) -> void:
	if (_s.sessions as Dictionary).erase(id):
		Save.mark_dirty()

# ============================================================ Paket ödülü

## Tamamlanıp henüz toplanmamış paket ("" = yok). Kutlama ekranını sürer.
func pending_pack_reward() -> String:
	return String(_s.pack_pending)

## Bekleyen paket ödülünü (200 coin + 25 gem) cüzdana yatır; paket başına bir kez.
func collect_pack_reward() -> Dictionary:
	var pid := String(_s.pack_pending)
	if pid == "":
		return {}
	Wallet.grant(PACK_REWARD, "pack")
	(_s.pack_rewarded as Array).append(pid)
	_s.pack_pending = ""
	Save.mark_dirty()
	# Önceden tamamlanmış ama kuyrukta bekleyen başka paket varsa sıradaki.
	for p in PACKS:
		if is_pack_complete(p.id) and not p.id in _s.pack_rewarded:
			_s.pack_pending = p.id
			break
	return {"pack": pid, "coin": PACK_REWARD.coin, "gem": PACK_REWARD.gem, "key": PACK_REWARD.key}

func packs_completed() -> int:
	var n := 0
	for p in PACKS:
		if is_pack_complete(p.id):
			n += 1
	return n

# ============================================================ Günlük bulmaca (UTC)

func daily_solved_count() -> int:
	var d: Dictionary = _s.daily
	return int(d.count) if d.date == utc_key() else 0

func is_daily_solved(index: int) -> bool:
	return index < daily_solved_count()

## Sıradaki oynanacak günlük index'i (hepsi bittiyse DAILY_LEVELS).
func daily_next_index() -> int:
	return daily_solved_count()

func is_daily_all_complete() -> bool:
	return daily_solved_count() >= DAILY_LEVELS

func _mark_daily(index: int, seconds: float) -> void:
	var key := utc_key()
	if _s.daily.date != key:
		_s.daily = {"date": key, "count": 0}
	if index + 1 > int(_s.daily.count):
		_s.daily.count = mini(index + 1, DAILY_LEVELS)
	var r: Dictionary = (_s.daily_results as Dictionary).get(key, {"count": 0, "time": -1.0})
	r["count"] = int(_s.daily.count)
	if float(r.time) < 0.0 or seconds < float(r.time):
		r["time"] = seconds
	_s.daily_results[key] = r
	_record_play_day()
	refresh_streaks()

## Günlük geçmiş: tarih → {count (0..3), time (en iyi sn)}.
func daily_history() -> Dictionary:
	return _s.daily_results

## Takvim ızgarası için bir ayın günleri: [{day, key, count, solved, full}] (UTC tarihleri).
func daily_month(year: int, month: int) -> Array:
	var out := []
	var key := "%04d-%02d-01" % [year, month]
	while int(key.substr(5, 2)) == month:
		var r: Dictionary = (_s.daily_results as Dictionary).get(key, {})
		var c := int(r.get("count", 0))
		out.append({"day": int(key.substr(8, 2)), "key": key, "count": c, "solved": c > 0, "full": c >= DAILY_LEVELS})
		key = key_add(key, 1)
	return out

## Günlük seri: bugün (ya da henüz çözülmediyse dün) geriye ardışık çözülen UTC günler.
var daily_streak: int:
	get: return _run_length(_daily_set(), utc_key())
var daily_longest: int:
	get: return int(_s.daily_longest)

func _daily_set() -> Dictionary:
	var days := {}
	for k in _s.daily_results:
		if int(_s.daily_results[k].get("count", 0)) > 0:
			days[k] = true
	return days

# ============================================================ Oynama serisi (yerel gün)

var play_streak: int:
	get: return _run_length(_played_set(), local_key())
var longest_play_streak: int:
	get: return int(_s.longest_play_streak)
var streak_freezes: int:
	get: return int(_s.streak_freezes)

func _played_set() -> Dictionary:
	var days := {}
	for k in _s.played_days:
		days[k] = true
	return days

func _run_length(days: Dictionary, today: String) -> int:
	var k := today if days.has(today) else key_add(today, -1)
	var n := 0
	while days.has(k):
		n += 1
		k = key_add(k, -1)
	return n

func _record_play_day() -> void:
	var k := local_key()
	if not k in _s.played_days:
		(_s.played_days as Array).append(k)
	refresh_streaks()
	# Kilometre taşı: ilk kez ulaşıldığında bekleyen olarak işaretle.
	var m := _highest_milestone(play_streak)
	if m > int(_s.last_rewarded_streak):
		_s.last_rewarded_streak = m
		_s.pending_streak_milestone = m

func _highest_milestone(n: int) -> int:
	var best := 0
	for m in STREAK_MILESTONES:
		if m <= n:
			best = m
	return best

## Serileri yeniden hesapla (ön plana dönünce de çağır). Tek kaçırılan günü (dün)
## elde dondurma varsa köprüler.
func refresh_streaks() -> void:
	var today := local_key()
	var y := key_add(today, -1)
	var played := _played_set()
	if int(_s.streak_freezes) > 0 and not played.has(y) and played.has(key_add(today, -2)):
		(_s.played_days as Array).append(y)
		_s.streak_freezes = int(_s.streak_freezes) - 1
		Save.mark_dirty()
	var ps := play_streak
	var ds := daily_streak
	if ps > int(_s.longest_play_streak) or ds > int(_s.daily_longest):
		_s.longest_play_streak = maxi(int(_s.longest_play_streak), ps)
		_s.daily_longest = maxi(int(_s.daily_longest), ds)
		Save.mark_dirty()
	Events.streak_changed.emit()

## 5 gem'e seri dondurma al.
func buy_streak_freeze() -> bool:
	if not Wallet.spend("gem", FREEZE_COST_GEMS, "freeze"):
		return false
	_s.streak_freezes = int(_s.streak_freezes) + 1
	Save.mark_dirty()
	return true

## Bekleyen seri kilometre taşı (0 = yok) ve ödülü.
func pending_streak_milestone() -> int:
	return int(_s.pending_streak_milestone)

## Bekleyen kilometre taşı ödülünü ver ve temizle. Dönüş {days, coin, gem} ya da {}.
func collect_streak_milestone() -> Dictionary:
	var m := int(_s.pending_streak_milestone)
	if m <= 0:
		return {}
	var r := streak_reward(m)
	Wallet.grant(r, "streak")
	_s.pending_streak_milestone = 0
	Save.mark_dirty()
	return {"days": m, "coin": r.coin, "gem": r.gem}

# ============================================================ Endless

var endless_best: int:
	get: return int(_s.endless_best)

## Endless grid'i (Swift: min(7, 4 + (n-1)/4)); tohum her yüklemede rastgele olmalı.
static func endless_grid(n: int) -> int:
	return mini(7, 4 + (n - 1) / 4)

# ============================================================ İstatistikler

var best_win_chain: int:
	get: return int(_s.best_win_chain)

func _campaign() -> Array:
	var out := []
	for id in _s.levels:
		var p: Dictionary = _s.levels[id]
		if p.get("completed", false) and not String(id).begins_with("daily"):
			out.append(p)
	return out

func total_completed() -> int:
	return _campaign().size()

## Başarım kuralları için türetilmiş sayılar (Swift AchievementStats).
func achievement_stats() -> Dictionary:
	var perfect := 0
	var no_hint := 0
	var fastest := -1
	for p in _campaign():
		if int(p.stars) >= 3:
			perfect += 1
		if int(p.get("hints_used", 1)) == 0:
			no_hint += 1
		var t := int(float(p.get("best_time", -1.0)))
		if float(p.get("best_time", -1.0)) >= 0.0 and (fastest < 0 or t < fastest):
			fastest = t
	return {
		"completed_levels": total_completed(), "daily_streak_best": daily_longest,
		"perfect_solves": perfect, "hint_free_solves": no_hint, "fastest_seconds": fastest,
		"packs_completed": packs_completed(), "longest_play_streak": longest_play_streak,
		"best_win_chain": best_win_chain,
	}

## İstatistik ekranının tüm verisi.
func stats() -> Dictionary:
	var camp := _campaign()
	var star_total := 0
	var dist := [0, 0, 0, 0]
	var best := -1.0
	var sum := 0.0
	var timed := 0
	for p in camp:
		var st := clampi(int(p.stars), 0, 3)
		star_total += st
		dist[st] += 1
		var t := float(p.get("best_time", -1.0))
		if t >= 0.0:
			sum += t
			timed += 1
			if best < 0.0 or t < best:
				best = t
	var daily_total := 0
	for k in _s.daily_results:
		if int(_s.daily_results[k].get("count", 0)) > 0:
			daily_total += 1
	# Son 7 gün günlük çubukları (UTC gün) ve 30 günlük oynama ısı haritası (yerel gün).
	var last7 := []
	var ut := utc_key()
	for ago in range(6, -1, -1):
		var k := key_add(ut, -ago)
		var r: Dictionary = (_s.daily_results as Dictionary).get(k, {})
		var wd: int = Time.get_datetime_dict_from_unix_time(day_number(k) * 86400 + 43200).weekday
		last7.append({"key": k, "weekday": wd, "count": int(r.get("count", 0)),
			"solved": int(r.get("count", 0)) > 0, "today": ago == 0})
	var heat := []
	var played := _played_set()
	for ago in range(29, -1, -1):
		heat.append(played.has(key_add(local_key(), -ago)))
	var packs := []
	for p in PACKS:
		packs.append({"id": p.id, "title": p.title, "completed": pack_completed_count(p.id),
			"total": p.levels, "stars": pack_stars(p.id), "stars_max": int(p.levels) * 3,
			"unlocked": is_pack_unlocked(p.id)})
	return {
		"total_levels": camp.size(), "total_levels_max": TOTAL_LEVELS,
		"stars": star_total, "stars_max": TOTAL_LEVELS * 3, "perfect": dist[3],
		"star_distribution": dist, "best_time": best,
		"avg_time": sum / timed if timed > 0 else 0.0,
		"days_played": (_s.played_days as Array).size(),
		"daily_solved_total": daily_total, "daily_streak": daily_streak, "daily_longest": daily_longest,
		"play_streak": play_streak, "longest_play_streak": longest_play_streak,
		"best_win_chain": best_win_chain, "endless_best": endless_best,
		"last7": last7, "heatmap30": heat, "active_days_30": heat.count(true), "packs": packs,
	}

## "2:34" biçimi (negatif → "—").
static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "—"
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
