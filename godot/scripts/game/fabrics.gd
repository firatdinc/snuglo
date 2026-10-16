class_name Fabrics
extends RefCounted
## Kumaş dokuları: art/fabric/<set>/f<NN>.png (ChatGPT). Yoksa düz renk çizilir.
## Parça rengi = palet; doku rengi zaten içerir → çizimde beyaz modülasyon.

static var _cache := {}
static var current_set := "classic"

static func get_tex(i: int) -> Texture2D:
	var key := "%s/%d" % [current_set, i % Palette.PIECES.size()]
	if not _cache.has(key):
		var p := "res://art/fabric/%s/f%02d.png" % [current_set, i % Palette.PIECES.size()]
		_cache[key] = load(p) if ResourceLoader.exists(p) else null
	return _cache[key]

## Kumaş ölçeği: dokunun 1 pikseli kaç ekran pikseli (hücre boyundan bağımsız sabit desen).
const TEXEL := 0.75

static func uvs(poly: PackedVector2Array, tex: Texture2D, seed_i: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	var sz := tex.get_size() * TEXEL
	var off := Vector2(fposmod(seed_i * 0.37, 1.0), fposmod(seed_i * 0.61, 1.0))
	for k in poly.size():
		out[k] = poly[k] / sz + off
	return out
