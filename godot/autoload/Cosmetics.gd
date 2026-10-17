extends Node
## Kozmetikler (Swift CosmeticsStore + AppColors.blockSkins + BoardBackground, main):
## - Kumaş setleri (Swift "block skins"): XP seviyesiyle ücretsiz açılır ya da erken gem ile
##   alınır (fiyat = max(5, seviye*2)). Premium setler (midnight 300, blossom 400) YALNIZ gem.
## - Tahtalar: 7 ücretsiz + 2 premium (twilight/ember 250 gem).
## - Premium abonelik tüm kozmetikleri açar.
## Ad anahtarı: fabric.<id> / board.<id>. Swift id eşlemesi: nordic→classic, candy→meadow,
## ocean→berry, mono→denim; sunset/aurora/midnight/blossom aynı.

## gem_cost > 0 → yalnız satın alma (seviye ile açılmaz).
const FABRICS := [
	{"id": "classic", "unlock_level": 1, "gem_cost": 0},
	{"id": "meadow", "unlock_level": 3, "gem_cost": 0},
	{"id": "berry", "unlock_level": 6, "gem_cost": 0},
	{"id": "denim", "unlock_level": 9, "gem_cost": 0},
	{"id": "sunset", "unlock_level": 12, "gem_cost": 0},
	{"id": "aurora", "unlock_level": 15, "gem_cost": 0},
	{"id": "midnight", "unlock_level": 0, "gem_cost": 300},
	{"id": "blossom", "unlock_level": 0, "gem_cost": 400},
]
const SWIFT_SKIN := {"nordic": "classic", "candy": "meadow", "ocean": "berry", "mono": "denim",
	"sunset": "sunset", "aurora": "aurora", "midnight": "midnight", "blossom": "blossom"}
const BOARDS := [
	{"id": "parchment", "gem_cost": 0}, {"id": "dawn", "gem_cost": 0}, {"id": "forest", "gem_cost": 0},
	{"id": "night", "gem_cost": 0}, {"id": "dusk", "gem_cost": 0}, {"id": "rose", "gem_cost": 0},
	{"id": "meadow", "gem_cost": 0}, {"id": "twilight", "gem_cost": 250}, {"id": "ember", "gem_cost": 250},
]

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(func() -> void:
		_load()
		Events.cosmetics_changed.emit())

func _load() -> void:
	_s = Save.get_section("cosmetics")
	var d := {"bought": [], "boards_bought": [], "fabric": "classic", "board": "parchment"}
	for k in d:
		if not _s.has(k):
			_s[k] = d[k]

static func _find(list: Array, id: String) -> Dictionary:
	for f in list:
		if f.id == id:
			return f
	return {}

## Seviye-kilitli set için erken alım fiyatı; premium set için sabit fiyat.
static func fabric_cost(f: Dictionary) -> int:
	return int(f.gem_cost) if int(f.gem_cost) > 0 else maxi(5, int(f.unlock_level) * 2)

func is_fabric_unlocked(id: String) -> bool:
	var f := _find(FABRICS, id)
	if f.is_empty():
		return false
	if Purchases.is_premium() or id in _s.bought:
		return true
	return int(f.gem_cost) == 0 and XP.level >= int(f.unlock_level)

func is_board_unlocked(id: String) -> bool:
	var b := _find(BOARDS, id)
	if b.is_empty():
		return false
	return int(b.gem_cost) == 0 or Purchases.is_premium() or id in _s.boards_bought

## Liste: [{id, name, unlock_level, cost, premium, unlocked, selected}].
func fabrics() -> Array:
	var out := []
	for f in FABRICS:
		out.append({"id": f.id, "name": "fabric." + f.id, "unlock_level": f.unlock_level,
			"cost": fabric_cost(f), "premium": int(f.gem_cost) > 0,
			"unlocked": is_fabric_unlocked(f.id), "selected": selected_fabric == f.id})
	return out

func boards() -> Array:
	var out := []
	for b in BOARDS:
		out.append({"id": b.id, "name": "board." + b.id, "cost": b.gem_cost, "premium": int(b.gem_cost) > 0,
			"unlocked": is_board_unlocked(b.id), "selected": selected_board == b.id})
	return out

## Kilitli seti gem ile al (zaten açıksa true).
func buy_fabric(id: String) -> bool:
	var f := _find(FABRICS, id)
	if f.is_empty():
		return false
	if is_fabric_unlocked(id):
		return true
	if not Wallet.spend("gem", fabric_cost(f), "fabric:" + id):
		return false
	(_s.bought as Array).append(id)
	Save.mark_dirty()
	Events.cosmetics_changed.emit()
	return true

func buy_board(id: String) -> bool:
	var b := _find(BOARDS, id)
	if b.is_empty():
		return false
	if is_board_unlocked(id):
		return true
	if not Wallet.spend("gem", int(b.gem_cost), "board:" + id):
		return false
	(_s.boards_bought as Array).append(id)
	Save.mark_dirty()
	Events.cosmetics_changed.emit()
	return true

var selected_fabric: String:
	get: return String(_s.fabric) if is_fabric_unlocked(String(_s.fabric)) else "classic"
var selected_board: String:
	get: return String(_s.board) if is_board_unlocked(String(_s.board)) else "parchment"

## Seç (kilitliyse false).
func select_fabric(id: String) -> bool:
	if not is_fabric_unlocked(id):
		return false
	_s.fabric = id
	Save.mark_dirty()
	Events.cosmetics_changed.emit()
	return true

func select_board(id: String) -> bool:
	if not is_board_unlocked(id):
		return false
	_s.board = id
	Save.mark_dirty()
	Events.cosmetics_changed.emit()
	return true
