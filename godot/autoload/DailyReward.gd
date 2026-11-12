extends Node
## Günlük giriş ödülleri (yerel gün):
## - 7 günlük döngü (Swift ProgressStore.claimDailyReward + DailyRewardCalculator); bir gün
##   kaçarsa 1. güne döner. Reklamsız/premium sahiplerine ek bonus.
## - 30 günlük takvim (Swift DailyCalendarStore): artan ödül, kaçan gün döngüyü sıfırlar.

## Gün → [ücretsiz, premium bonus].
const WEEK := {
	1: [{"coin": 50}, {"coin": 25}],
	2: [{"coin": 100}, {"coin": 50}],
	3: [{"gem": 1}, {"gem": 1}],
	4: [{"coin": 100}, {"coin": 50}],
	5: [{"gem": 2}, {"gem": 1}],
	6: [{"coin": 200}, {"coin": 100}],
	7: [{"gem": 5, "cup": 1}, {"gem": 2}],
}
const CALENDAR_LENGTH := 30

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("daily_reward")
	var d := {"week_last": "", "week_day": 0, "cal_last": -1, "cal_day": 0}
	for k in d:
		if not _s.has(k):
			_s[k] = d[k]

# --- 7 günlük ---

## Bir günün ödülü (premium = reklam kaldır sahibi).
static func week_reward(day: int, premium: bool) -> Dictionary:
	var row: Array = WEEK.get(day, [{"coin": 50}, {}])
	var r: Dictionary = (row[0] as Dictionary).duplicate()
	if premium:
		for c in row[1]:
			r[c] = int(r.get(c, 0)) + int(row[1][c])
	return r

## Yalnız ileri gün açar (saat geri alınınca yeniden açılmaz).
func can_claim_week() -> bool:
	return Progress.local_key() > String(_s.week_last) and not Progress.clock_rewound()

## Sıradaki (ya da bugün alınmışsa bugünkü) döngü günü 1..7.
func week_day() -> int:
	if not can_claim_week():
		return maxi(1, int(_s.week_day))
	if String(_s.week_last) != Progress.key_add(Progress.local_key(), -1):
		return 1
	return (int(_s.week_day) % 7) + 1

## Bugünün ödülünü al. Dönüş {day, reward} ya da {} (bugün alındı).
func claim_week() -> Dictionary:
	if not can_claim_week():
		return {}
	var day := week_day()
	var r := week_reward(day, Purchases.ads_removed())
	Wallet.grant(r, "daily_reward")
	_s.week_last = Progress.local_key()
	_s.week_day = day
	Save.mark_dirty()
	return {"day": day, "reward": r}

# --- 30 günlük takvim ---

## Takvim günü ödülü: coin = 40 + gün*15, her 7. günde gem = gün/7.
static func calendar_reward(day: int) -> Dictionary:
	return {"coin": 40 + day * 15, "gem": maxi(1, day / 7) if day % 7 == 0 else 0}

func can_claim_calendar() -> bool:
	return Progress.local_day() > int(_s.cal_last) and not Progress.clock_rewound()

func calendar_day() -> int:
	if not can_claim_calendar():
		return maxi(1, int(_s.cal_day))
	if int(_s.cal_last) == Progress.local_day() - 1:
		return (int(_s.cal_day) % CALENDAR_LENGTH) + 1
	return 1

## Bu döngüde alınmış en yüksek gün (ızgarada işaretlemek için).
func calendar_claimed_through() -> int:
	return int(_s.cal_day) if int(_s.cal_last) >= Progress.local_day() - 1 else 0

func claim_calendar() -> Dictionary:
	if not can_claim_calendar():
		return {}
	var day := calendar_day()
	var r := calendar_reward(day)
	Wallet.grant(r, "calendar")
	_s.cal_day = day
	_s.cal_last = Progress.local_day()
	Save.mark_dirty()
	return {"day": day, "reward": r}
