class_name SeededRandom
extends RefCounted
## Swift `SeededRandom` (SplitMix64) + stdlib `shuffle`/`next(upperBound:)` birebir portu.
## GDScript int = int64, çarpma/toplama taşmada sarar; uint64 davranışı için
## mantıksal sağa kaydırma ve işaretsiz mod/karşılaştırma elle yapılır.
## Swift sürümüyle aynı level'ları üretmesi tests/parity_test.gd ile kilitli.

const GOLDEN := -7046029254386353131   # 0x9E3779B97F4A7C15
const MIX1 := -4658895280553007687     # 0xBF58476D1CE4E5B9
const MIX2 := -7723592293110705685     # 0x94D049BB133111EB
const LO32 := 0xFFFFFFFF

var _state: int

func _init(seed: int) -> void:
	_state = 1 if seed == 0 else seed

static func shr(x: int, k: int) -> int:
	return (x >> k) & ((1 << (64 - k)) - 1)

## İşaretsiz 64-bit x % n (n > 0, küçük).
static func urem(x: int, n: int) -> int:
	if x >= 0:
		return x % n
	return ((shr(x, 1) % n) * 2 + (x & 1)) % n

## İşaretsiz a < b.
static func ult(a: int, b: int) -> bool:
	return (a ^ (1 << 63)) < (b ^ (1 << 63))

func next() -> int:
	_state += GOLDEN
	var z := _state
	z = (z ^ shr(z, 30)) * MIX1
	z = (z ^ shr(z, 27)) * MIX2
	return z ^ shr(z, 31)

## Swift RandomNumberGenerator.next(upperBound:) — Lemire, ub < 2^31.
func next_below(ub: int) -> int:
	var m := _mul_full(next(), ub)
	if ult(m[1], ub):
		var t := urem(-ub, ub)
		while ult(m[1], t):
			m = _mul_full(next(), ub)
	return m[0]

## [high, low] = r * ub (128-bit, r işaretsiz 64, ub < 2^31).
static func _mul_full(r: int, ub: int) -> Array:
	var a := (r & LO32) * ub
	var b := shr(r, 32) * ub
	var mid := (b & LO32) + shr(a, 32)
	var high := shr(b, 32) + shr(mid, 32)
	var low := ((mid & LO32) << 32) | (a & LO32)
	return [high, low]

## Swift MutableCollection.shuffle(using:) ile aynı sıra.
func shuffle(arr: Array) -> void:
	var amount := arr.size()
	var cur := 0
	while amount > 1:
		var r := next_below(amount)
		amount -= 1
		var j := cur + r
		var tmp = arr[cur]
		arr[cur] = arr[j]
		arr[j] = tmp
		cur += 1

static func fnv1a(s: String) -> int:
	var h := -3750763034362895579  # 0xcbf29ce484222325
	for b in s.to_utf8_buffer():
		h ^= b
		h *= 1099511628211
	return h
