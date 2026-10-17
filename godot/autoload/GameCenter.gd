extends Node
## Game Center (GodotApplePlugins "GameCenterManager", yalnız iOS). Masaüstünde no-op.
## Skorlar (Swift GameCenterScoreMapper, main): toplam bölüm, en hızlı çözüm (SANTİSANİYE —
## ASC ELAPSED_TIME_CENTISECOND), en iyi günlük seri, endless rekoru. Başarımlar
## "snuglo.achievement.<id>" olarak %100 bildirilir.

signal auth_changed

const TOTAL_LEVELS := "snuglo.total.levels"
const FASTEST_SOLVE := "snuglo.fastest.solve"
const BEST_STREAK := "snuglo.best.streak"
const ENDLESS_BEST := "snuglo.endless.best"
const ALL := [TOTAL_LEVELS, FASTEST_SOLVE, BEST_STREAK, ENDLESS_BEST]

var gc: Object = null
var authed := false
var _boards := {}       # id → GKLeaderboard
var _last := {}         # id → son gönderilen skor (gereksiz gönderimi önler)

func _ready() -> void:
	if OS.get_name() != "iOS" or not ClassDB.class_exists("GameCenterManager"):
		return
	gc = ClassDB.instantiate("GameCenterManager")
	gc.authentication_result.connect(_on_auth)
	gc.authentication_error.connect(func(_e): _on_auth(false))
	gc.authenticate()

func is_supported() -> bool:
	return gc != null

func _on_auth(ok: bool) -> void:
	authed = ok and gc.local_player != null and gc.local_player.is_authenticated
	if authed:
		submit_progress()
	auth_changed.emit()

## Skor eşlemesi (test edilebilir, saf): {id: skor}. Geçersiz skorlar atlanır.
static func scores(stats: Dictionary) -> Dictionary:
	var out := {TOTAL_LEVELS: maxi(0, int(stats.get("total_levels", 0))),
		BEST_STREAK: maxi(0, int(stats.get("daily_longest", 0)))}
	var best := float(stats.get("best_time", -1.0))
	if best > 0.0:
		out[FASTEST_SOLVE] = int(best * 100.0)
	return out

## Her çözümden sonra Progress çağırır.
func submit_progress() -> void:
	if not authed:
		return
	var sc := scores(Progress.stats())
	for id in sc:
		if _last.get(id, -1) != sc[id]:
			_last[id] = sc[id]
			submit(id, sc[id])

func submit(id: String, score: int) -> void:
	if not authed or score <= 0:
		return
	_with_board(id, func(lb): lb.submit_score(score, 0, gc.local_player, func(_err): pass))

## Apple'ın skor tablosu ekranı (id boşsa toplam bölüm panosu). Giriş yoksa tekrar dener.
func show_leaderboards(id := "") -> void:
	if gc == null:
		return
	if not authed:
		gc.authenticate()
		return
	if gc.access_point:
		gc.access_point.trigger_with_leaderboard(id if id != "" else TOTAL_LEVELS, 0, 2, func(): pass)

func _with_board(id: String, then: Callable) -> void:
	if _boards.has(id):
		then.call(_boards[id])
		return
	ClassDB.class_call_static("GKLeaderboard", "load_leaderboards", PackedStringArray([id]), func(list: Array, err):
		if err == null and list.size() > 0:
			_boards[id] = list[0]
			then.call(list[0]))

## Başarımı %100 bildir (fire-and-forget; giriş yoksa sessizce atlanır).
## Kimlik belirsizliği: canlı Swift "snuglo.achievement.<id>" bildiriyordu, ama
## ~/snuglo-main/scripts/setup_achievements.py ASC'de vendorIdentifier'ı ÇIPLAK <id> olarak
## oluşturuyor. Hangisinin ASC'de olduğunu buradan bilemiyoruz → ikisi de AYRI çağrılarla
## bildirilir (bilinmeyen kimlik yalnız kendi çağrısını hata ile bitirir, diğerini etkilemez).
func report_achievement(gc_id: String) -> void:
	if not authed:
		return
	var ids := [gc_id]
	if gc_id.begins_with("snuglo.achievement."):
		ids.append(gc_id.trim_prefix("snuglo.achievement."))
	for id in ids:
		var a = ClassDB.class_call_static("GKAchievement", "make", id)
		if a:
			a.percent_complete = 100.0
			a.shows_completion_banner = true
			ClassDB.class_call_static("GKAchievement", "report_achievement", [a], func(_err): pass)
