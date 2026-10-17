extends Node
## Günlük çark (Swift SpinStore): yerel günde bir kez. Önce choose_index() (UI çarkı o dilime
## döndürür), sonra commit(index) ödülü verir. Bilet çarktan çıkmaz (yalnız gem ile alınır).

## Saat yönünde, tepeden başlayarak dilimler.
const SEGMENTS := [
	{"currency": "coin", "amount": 50}, {"currency": "coin", "amount": 150},
	{"currency": "gem", "amount": 1}, {"currency": "coin", "amount": 100},
	{"currency": "coin", "amount": 500}, {"currency": "coin", "amount": 80},
	{"currency": "gem", "amount": 2}, {"currency": "coin", "amount": 120},
]
## Ağırlıklar (toplam 100): ikramiye/gem küçük coin'den nadir.
const WEIGHTS := [22, 14, 8, 18, 3, 20, 5, 10]

var _s: Dictionary
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("spin")
	_s["last_day"] = int(_s.get("last_day", -1))

func can_spin() -> bool:
	return Progress.local_day() > int(_s.last_day) and not Progress.clock_rewound()

## Ağırlıklı kazanan dilim (henüz vermez).
func choose_index() -> int:
	var r := rng.randi_range(0, 99)
	for i in WEIGHTS.size():
		if r < WEIGHTS[i]:
			return i
		r -= WEIGHTS[i]
	return WEIGHTS.size() - 1

## Dilimin ödülünü ver ve yarına kadar kilitle. Verilen dilim ya da {}.
func commit(index: int) -> Dictionary:
	if not can_spin() or index < 0 or index >= SEGMENTS.size():
		return {}
	var seg: Dictionary = SEGMENTS[index]
	Wallet.add(seg.currency, seg.amount, "spin")
	_s.last_day = Progress.local_day()
	Save.mark_dirty()
	return seg
