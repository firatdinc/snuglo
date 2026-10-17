extends Node
## Ödül sandığı metresi (Swift ChestStore): her 5 çözümde bir sandık birikir; açmak 1 anahtar
## ister (Wallet "key": 3★ çözüm, 5'li zincir, paket tamamlama, IAP). Açınca ağırlıklı
## rastgele ödül (çoğunlukla coin; kademeye göre ipucu, gem, nadiren anahtar).

const SOLVES_PER_CHEST := 5

var _s: Dictionary
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("chest")
	_s["progress"] = clampi(int(_s.get("progress", 0)), 0, SOLVES_PER_CHEST)
	_s["pending"] = maxi(0, int(_s.get("pending", 0)))

var progress: int:
	get: return int(_s.progress)
var pending: int:
	get: return int(_s.pending)
var goal: int:
	get: return SOLVES_PER_CHEST

func has_chest() -> bool:
	return pending > 0

## Sandık var VE anahtar var.
func can_open() -> bool:
	return pending > 0 and Wallet.keys > 0

## Her çözümde. Bu çözüm yeni sandık doldurduysa true.
func record_solve() -> bool:
	_s.progress = progress + 1
	var filled := false
	if progress >= SOLVES_PER_CHEST:
		_s.progress = 0
		_s.pending = pending + 1
		filled = true
	Save.mark_dirty()
	return filled

## Kademe sırası (açılış animasyonu bu sırayla tırmanır).
const TIERS := ["common", "rare", "epic", "legendary"]

## Ağırlıklı tablo — çoğunlukla düğme (coin), kademe yükseldikçe ipucu/yüksük/anahtar eklenir:
## %52 sıradan 60-120 coin · %30 nadir 150-250 coin + 1 ipucu · %14 destansı 300-400 coin +
## 2 ipucu + 2-3 yüksük · %4 efsanevi 800 coin + 3 ipucu + 5 yüksük + 1 anahtar.
func roll() -> Dictionary:
	var r := rng.randi_range(0, 99)
	if r < 52:
		return {"tier": "common", "rewards": {"coin": rng.randi_range(6, 12) * 10}}
	if r < 82:
		return {"tier": "rare", "rewards": {"coin": rng.randi_range(15, 25) * 10, "hint": 1}}
	if r < 96:
		return {"tier": "epic", "rewards": {"coin": rng.randi_range(30, 40) * 10, "hint": 2, "gem": rng.randi_range(2, 3)}}
	return {"tier": "legendary", "rewards": {"coin": 800, "hint": 3, "gem": 5, "key": 1}}

## Bir anahtar harcayıp sandık aç ve ödülü belirle. grant=false → ödülü çağıran verir
## (açılış animasyonu sürerken üst bar sonucu ele vermesin; bkz. grant()). Sandık/anahtar yoksa {}.
func open(give := true) -> Dictionary:
	if pending <= 0 or not Wallet.spend("key", 1, "chest"):
		return {}
	_s.pending = pending - 1
	var r := roll()
	if give:
		grant(r)
	Save.mark_dirty()
	return r

func grant(r: Dictionary) -> void:
	Wallet.grant(r.get("rewards", {}), "chest")
