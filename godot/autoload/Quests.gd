extends Node
## 3 günlük görev (Swift DailyQuestStore) + haftalık meydan okuma (WeeklyChallengeStore).
## Görevler yerel gün numarasından deterministik; gün/hafta dönünce kendiliğinden sıfırlanır.
## Görev metni: tr(q.text) % q.arg.

const KINDS := ["solve_levels", "solve_under", "no_hint", "perfect"]
const TEXT := {
	"solve_levels": "quest.solveLevels", "solve_under": "quest.solveUnder",
	"no_hint": "quest.noHints", "perfect": "quest.perfect",
}
const WEEKLY_REWARD := {"coin": 300, "gem": 3}

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("quests")
	_rollover()

## Bir günün görevleri: [{id, kind, goal, param, reward:{coin,gem}, text, arg}].
static func generate(day: int) -> Array:
	var i := posmod(day, 4)
	var skill: String = ["no_hint", "perfect", "no_hint", "perfect"][i]
	var qs := [
		{"id": 0, "kind": "solve_levels", "goal": [3, 4, 5, 4][i], "param": 0, "reward": {"coin": 60, "gem": 0}},
		{"id": 1, "kind": "solve_under", "goal": 1, "param": [45, 60, 75, 50][i], "reward": {"coin": 80, "gem": 0}},
		{"id": 2, "kind": skill, "goal": [2, 2, 3, 3][i], "param": 0, "reward": {"coin": 0, "gem": 1}},
	]
	for q in qs:
		q["text"] = TEXT[q.kind]
		q["arg"] = q.param if q.kind == "solve_under" else q.goal
	return qs

## Bugünün görevleri + ilerleme: her öğeye progress, complete, claimed eklenir.
func today() -> Array:
	_rollover()
	var qs := generate(int(_s.day))
	for q in qs:
		q["progress"] = int(_s.progress[q.id])
		q["claimed"] = bool(_s.claimed[q.id])
		q["complete"] = q.progress >= q.goal
	return qs

## Bugün tamamlanan görev sayısı (menü "N/3" rozeti).
func completed_count() -> int:
	var n := 0
	for q in today():
		if q.complete:
			n += 1
	return n

## Ödülü alınabilecek görev var mı.
func has_claimable() -> bool:
	for q in today():
		if q.complete and not q.claimed:
			return true
	return can_claim_weekly()

## Her çözümde çağrılır (Progress.record_level). Yeni tamamlanan görev id'lerini döndürür.
func record_solve(seconds: int, hints: int, star_count: int) -> Array:
	_rollover()
	var done := []
	for q in generate(int(_s.day)):
		var i: int = q.id
		var p := int(_s.progress[i])
		if bool(_s.claimed[i]) or p >= q.goal:
			continue
		var hit := false
		match q.kind:
			"solve_levels": hit = true
			"solve_under": hit = seconds <= int(q.param)
			"no_hint": hit = hints == 0
			"perfect": hit = star_count >= 3
		if not hit:
			continue
		p = mini(p + 1, q.goal)
		_s.progress[i] = p
		if p >= q.goal:
			done.append(i)
			Events.quest_completed.emit(i)
	# Haftalık
	if not bool(_s.weekly_claimed) and int(_s.weekly_progress) < weekly_goal():
		_s.weekly_progress = int(_s.weekly_progress) + 1
	Save.mark_dirty()
	return done

## Görev ödülünü bir kez ver. Dönüş ödül sözlüğü ya da {}.
func claim(i: int) -> Dictionary:
	_rollover()
	if i < 0 or i > 2 or bool(_s.claimed[i]):
		return {}
	var q: Dictionary = generate(int(_s.day))[i]
	if int(_s.progress[i]) < q.goal:
		return {}
	_s.claimed[i] = true
	Wallet.grant(q.reward, "quest")
	Save.mark_dirty()
	return q.reward

# --- Haftalık ---

## Bu haftanın hedefi (15/20/25 rotasyon).
func weekly_goal() -> int:
	return [15, 20, 25][posmod(int(_s.week), 3)]

func weekly() -> Dictionary:
	_rollover()
	return {"goal": weekly_goal(), "progress": int(_s.weekly_progress), "claimed": bool(_s.weekly_claimed),
		"complete": int(_s.weekly_progress) >= weekly_goal(), "reward": WEEKLY_REWARD,
		"text": "weekly.goal", "arg": weekly_goal()}

func can_claim_weekly() -> bool:
	return int(_s.weekly_progress) >= weekly_goal() and not bool(_s.weekly_claimed)

func claim_weekly() -> Dictionary:
	_rollover()
	if not can_claim_weekly():
		return {}
	_s.weekly_claimed = true
	Wallet.grant(WEEKLY_REWARD, "weekly")
	Save.mark_dirty()
	return WEEKLY_REWARD

func _rollover() -> void:
	var day := Progress.local_day()
	# Yalnız ileri gün/hafta sıfırlar (saat geri alınınca görevler yeniden açılmaz).
	if day > int(_s.get("day", -1)) or (_s.get("progress", []) as Array).size() != 3:
		_s.day = day
		_s.progress = [0, 0, 0]
		_s.claimed = [false, false, false]
		Save.mark_dirty()
	var week := floori(day / 7.0)
	if week > int(_s.get("week", -1)):
		_s.week = week
		_s.weekly_progress = 0
		_s.weekly_claimed = false
		Save.mark_dirty()
