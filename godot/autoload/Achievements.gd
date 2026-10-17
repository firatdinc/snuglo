extends Node
## 35 başarım (Swift Achievement + AchievementRules, main). evaluate() idempotent: yeni
## açılanları ödüllendirir (cup dahil), Events.achievement_unlocked yayar ve Game Center'a
## "snuglo.achievement.<id>" olarak bildirir. Başlık/açıklama: achievement.<id>.title/.description.

const GC_PREFIX := "snuglo.achievement."
## id, kategori, stat anahtarı, hedef, ödül. "fastest_under": en hızlı çözüm < hedef sn (ikili).
const LIST := [
	{"id": "firstSteps", "cat": "levels", "stat": "completed_levels", "target": 1, "reward": {"coin": 50}},
	{"id": "levelHunter10", "cat": "levels", "stat": "completed_levels", "target": 10, "reward": {"coin": 100}},
	{"id": "levelHunter25", "cat": "levels", "stat": "completed_levels", "target": 25, "reward": {"coin": 200}},
	{"id": "levelMaster50", "cat": "levels", "stat": "completed_levels", "target": 50, "reward": {"coin": 500, "cup": 1}},
	{"id": "levelLegend100", "cat": "levels", "stat": "completed_levels", "target": 100, "reward": {"coin": 1000, "gem": 5, "cup": 1}},
	{"id": "levelVoyager250", "cat": "levels", "stat": "completed_levels", "target": 250, "reward": {"coin": 1500, "gem": 5}},
	{"id": "levelSage500", "cat": "levels", "stat": "completed_levels", "target": 500, "reward": {"coin": 2500, "gem": 10, "cup": 1}},
	{"id": "completionist1000", "cat": "levels", "stat": "completed_levels", "target": 1000, "reward": {"coin": 5000, "gem": 25, "cup": 1}},
	{"id": "packFinisher", "cat": "levels", "stat": "packs_completed", "target": 1, "reward": {"coin": 300, "gem": 2}},
	{"id": "packCollector3", "cat": "levels", "stat": "packs_completed", "target": 3, "reward": {"coin": 600, "gem": 3}},
	{"id": "packMaster10", "cat": "levels", "stat": "packs_completed", "target": 10, "reward": {"coin": 1500, "gem": 8, "cup": 1}},
	{"id": "perfectionist1", "cat": "skill", "stat": "perfect_solves", "target": 1, "reward": {"coin": 50}},
	{"id": "perfectionistPro10", "cat": "skill", "stat": "perfect_solves", "target": 10, "reward": {"coin": 200, "gem": 1}},
	{"id": "perfectionistMaster25", "cat": "skill", "stat": "perfect_solves", "target": 25, "reward": {"coin": 600, "gem": 3}},
	{"id": "perfectionistGrand50", "cat": "skill", "stat": "perfect_solves", "target": 50, "reward": {"coin": 1200, "gem": 6}},
	{"id": "perfectionistLegend100", "cat": "skill", "stat": "perfect_solves", "target": 100, "reward": {"coin": 2500, "gem": 12, "cup": 1}},
	{"id": "comboChampion", "cat": "skill", "stat": "best_win_chain", "target": 5, "reward": {"coin": 200, "gem": 1}},
	{"id": "chainMaster10", "cat": "skill", "stat": "best_win_chain", "target": 10, "reward": {"coin": 500, "gem": 3}},
	{"id": "chainLegend20", "cat": "skill", "stat": "best_win_chain", "target": 20, "reward": {"coin": 1000, "gem": 6}},
	{"id": "noHints10", "cat": "skill", "stat": "hint_free_solves", "target": 10, "reward": {"gem": 1}},
	{"id": "noHints25", "cat": "skill", "stat": "hint_free_solves", "target": 25, "reward": {"coin": 300, "gem": 2}},
	{"id": "noHints50", "cat": "skill", "stat": "hint_free_solves", "target": 50, "reward": {"coin": 700, "gem": 5}},
	{"id": "speedSolver", "cat": "skill", "stat": "fastest_under", "target": 30, "reward": {"coin": 100}},
	{"id": "speedDemon", "cat": "skill", "stat": "fastest_under", "target": 15, "reward": {"coin": 250, "gem": 2}},
	{"id": "speedLightning", "cat": "skill", "stat": "fastest_under", "target": 10, "reward": {"coin": 500, "gem": 3}},
	{"id": "speedBlitz", "cat": "skill", "stat": "fastest_under", "target": 5, "reward": {"coin": 1000, "gem": 6}},
	{"id": "streak3", "cat": "streak", "stat": "daily_streak_best", "target": 3, "reward": {"coin": 100}},
	{"id": "streak7", "cat": "streak", "stat": "daily_streak_best", "target": 7, "reward": {"coin": 200, "gem": 2}},
	{"id": "streak14", "cat": "streak", "stat": "daily_streak_best", "target": 14, "reward": {"coin": 350, "gem": 3}},
	{"id": "streak30", "cat": "streak", "stat": "daily_streak_best", "target": 30, "reward": {"coin": 500, "gem": 5, "cup": 1}},
	{"id": "streak60", "cat": "streak", "stat": "daily_streak_best", "target": 60, "reward": {"coin": 1000, "gem": 8}},
	{"id": "streak100", "cat": "streak", "stat": "daily_streak_best", "target": 100, "reward": {"coin": 2000, "gem": 15, "cup": 1}},
	{"id": "dedicated7", "cat": "streak", "stat": "longest_play_streak", "target": 7, "reward": {"coin": 250, "gem": 2}},
	{"id": "dedicated14", "cat": "streak", "stat": "longest_play_streak", "target": 14, "reward": {"coin": 500, "gem": 4}},
	{"id": "dedicated30", "cat": "streak", "stat": "longest_play_streak", "target": 30, "reward": {"coin": 1000, "gem": 8, "cup": 1}},
]

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("achievements")
	if not _s.has("unlocked"):
		_s["unlocked"] = []

func def(id: String) -> Dictionary:
	for a in LIST:
		if a.id == id:
			return a
	return {}

func is_unlocked(id: String) -> bool:
	return id in _s.unlocked

## (current, target) ilerleme. Süre başarımları ikili (0/1).
func progress(id: String, stats: Dictionary = {}) -> Vector2i:
	var a := def(id)
	if a.is_empty():
		return Vector2i.ZERO
	if stats.is_empty():
		stats = Progress.achievement_stats()
	if a.stat == "fastest_under":
		var f := int(stats.fastest_seconds)
		return Vector2i(1 if f >= 0 and f < int(a.target) else 0, 1)
	return Vector2i(clampi(int(stats[a.stat]), 0, int(a.target)), int(a.target))

## Ekran listesi: [{id, cat, title, description, reward, unlocked, current, target}].
func all() -> Array:
	var stats := Progress.achievement_stats()
	var out := []
	for a in LIST:
		var p := progress(a.id, stats)
		out.append({"id": a.id, "cat": a.cat, "title": "achievement.%s.title" % a.id,
			"description": "achievement.%s.description" % a.id, "reward": a.reward,
			"unlocked": is_unlocked(a.id), "current": p.x, "target": p.y})
	return out

func unlocked_count() -> int:
	return (_s.unlocked as Array).size()

## Yeni koşulu sağlananları aç + ödüllendir. Yeni açılan id listesi.
func evaluate() -> Array:
	var stats := Progress.achievement_stats()
	var fresh := []
	for a in LIST:
		if is_unlocked(a.id):
			continue
		var p := progress(a.id, stats)
		if p.x < p.y:
			continue
		(_s.unlocked as Array).append(a.id)
		Wallet.grant(a.reward, "achievement")
		fresh.append(a.id)
	if not fresh.is_empty():
		Save.mark_dirty()
		for id in fresh:
			GameCenter.report_achievement(GC_PREFIX + id)
			Events.achievement_unlocked.emit(id)
	return fresh
