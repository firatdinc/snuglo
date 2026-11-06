class_name Fabrics
extends RefCounted
## Kumaş dokuları: art/fabric/<set>/f<NN>.png (ChatGPT). Yoksa düz renk çizilir.
## Parça rengi = palet; doku rengi zaten içerir → çizimde beyaz modülasyon.

static var _cache := {}
static var current_set := "classic"

## Seçili kumaş seti (Cosmetics._sync ayarlar). set_id verilirse o setin dokusu (ayar önizlemesi).
static func get_tex(i: int, set_id := "") -> Texture2D:
	var sid := set_id if set_id != "" else current_set
	var key := "%s/%d" % [sid, i % Palette.PIECES.size()]
	if not _cache.has(key):
		var p := "res://art/fabric/%s/f%02d.png" % [sid, i % Palette.PIECES.size()]
		if not ResourceLoader.exists(p):
			p = "res://art/fabric/classic/f%02d.png" % (i % Palette.PIECES.size())
		_cache[key] = load(p) if ResourceLoader.exists(p) else null
	return _cache[key]

## Parça rengi (gölge/hayalet/rakam): setin dokudan ölçülmüş medyan rengi.
static func color(i: int) -> Color:
	var cols: Array = FabricColors.SETS.get(current_set, Palette.PIECES)
	return cols[i % cols.size()]

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
