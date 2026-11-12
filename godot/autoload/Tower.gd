extends Node
## Kule modu (Swift TowerStore): 1 bilet ile tırmanış başlar; her kat rastgele tohumlu,
## giderek zorlaşan bulmaca. Süre biterse tırmanış biter (yanlış yerleşim bitirmez).
## Bitişte temizlenen kat başına 20 coin. Yarım tırmanış kaldığı kattan, kalan süresiyle sürer.
## Bölüm id'si "tower-<kat>".

const TICKET_COST := 1
const COIN_PER_FLOOR := 20

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("tower")
	_s["best"] = int(_s.get("best", 0))
	_s["current"] = int(_s.get("current", 0))

var best_floor: int:
	get: return int(_s.best)
var current_floor: int:
	get: return int(_s.current)

func has_active_run() -> bool:
	return current_floor > 0

## Kat grid'i: 5×5 → 8×8, her 4 katta bir büyür.
static func grid_size(floor_n: int) -> int:
	return mini(8, 5 + (maxi(1, floor_n) - 1) / 4)

## Kat süresi: hücre başına ~3 sn, her katta 3 sn azalır, en az 25 sn.
static func time_limit(floor_n: int) -> int:
	var g := grid_size(floor_n)
	return maxi(25, g * g * 3 - (floor_n - 1) * 3)

static func reward(floors_cleared: int) -> int:
	return maxi(0, floors_cleared) * COIN_PER_FLOOR

func can_enter() -> bool:
	return has_active_run() or Wallet.can_afford("ticket", TICKET_COST)

## Yeni tırmanış: bilet öde, 1. kattan başla. Aktif tırmanış varsa ücretsiz devam.
func start_run() -> bool:
	if has_active_run():
		return true
	if not Wallet.spend("ticket", TICKET_COST, "tower"):
		return false
	_set_current(1)
	return true

## Kat temizlendi → rekor + sonraki kata geç. Yeni rekorsa true.
func clear_floor(floor_n: int) -> bool:
	_set_current(floor_n + 1)
	if floor_n > best_floor:
		_s.best = floor_n
		Save.mark_dirty()
		return true
	return false

## Süre bitti / tırmanış bitti: temizlenen kat başına coin ver. Dönüş {floors, coins}.
func end_run() -> Dictionary:
	var cleared := maxi(0, current_floor - 1)
	var coins := reward(cleared)
	Wallet.add("coin", coins, "tower")
	_set_current(0)
	return {"floors": cleared, "coins": coins}

func _set_current(f: int) -> void:
	_s.current = maxi(0, f)
	_s.erase("elapsed")
	Save.mark_dirty()

## Yarım kalan katın geçen süresi: çıkıp geri girmek taze tam süre vermesin (kat yeniden
## üretilir ama saat kaldığı yerden sürer).
func save_elapsed(floor_n: int, seconds: float) -> void:
	if floor_n != current_floor:
		return
	_s.elapsed = {"floor": floor_n, "t": seconds}
	Save.mark_dirty()

func saved_elapsed(floor_n: int) -> float:
	var e: Dictionary = _s.get("elapsed", {})
	return float(e.get("t", 0.0)) if int(e.get("floor", -1)) == floor_n else 0.0
