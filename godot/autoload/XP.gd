extends Node
## Oyuncu XP/seviyesi (Swift XPStore). L→L+1 için 100 + (L-1)*60 XP. Her yeni seviye
## 20 + seviye*5 coin verir (2026-06-13 sıkılaştırması) (anında) ve kutlama için bekleyen olarak işaretlenir.

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("xp")
	_s["total"] = maxi(0, int(_s.get("total", 0)))
	_s["pending_level"] = int(_s.get("pending_level", 0))
	_s["pending_coins"] = int(_s.get("pending_coins", 0))

static func need(lv: int) -> int:
	return 100 + (lv - 1) * 60

## {level, into, need} toplam XP'den.
static func info(total_xp: int) -> Dictionary:
	var lv := 1
	var rem := maxi(0, total_xp)
	while rem >= need(lv):
		rem -= need(lv)
		lv += 1
	return {"level": lv, "into": rem, "need": need(lv)}

static func level_up_coins(lv: int) -> int:
	return 20 + lv * 5

var total: int:
	get: return int(_s.total)
var level: int:
	get: return int(info(total).level)
var into_level: int:
	get: return int(info(total).into)
var for_next: int:
	get: return int(info(total).need)
## 0..1 ilerleme çubuğu.
var fraction: float:
	get: return float(into_level) / float(for_next)

## XP ver; kazanılan seviye sayısını döndürür.
func award(xp: int) -> int:
	if xp <= 0:
		return 0
	var before := level
	_s.total = total + xp
	var after := level
	if after > before:
		var coins := 0
		for lv in range(before + 1, after + 1):
			coins += level_up_coins(lv)
		Wallet.add("coin", coins, "level_up")
		_s.pending_level = after
		_s.pending_coins = int(_s.pending_coins) + coins
		Events.xp_level_up.emit(after)
	Save.mark_dirty()
	return after - before

## Bekleyen seviye atlama kutlaması {level, coins} (yoksa {}). Ödül zaten verildi.
func pending_level_up() -> Dictionary:
	if int(_s.pending_level) <= 0:
		return {}
	return {"level": int(_s.pending_level), "coins": int(_s.pending_coins)}

func consume_level_up() -> void:
	_s.pending_level = 0
	_s.pending_coins = 0
	Save.mark_dirty()
