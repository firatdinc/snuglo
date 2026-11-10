class_name HandFont
extends RefCounted
## El yazısı yazı tipi (Yeni Yıl Dileği). Latin: Caveat (tr/de/fr/es/it/pt aksanları dahil),
## Japonca: Yomogi (JIS X 0208 kana + kanji), Korece: Gaegu (KS X 1001 Hangul). Hepsi OFL.
## Birincil yazı tipi dile göre seçilir, diğerleri yedek zincirinde: karışık yazıda hiçbir glif eksik kalmaz.

const CAVEAT := preload("res://art/fonts/Caveat.ttf")
const YOMOGI := preload("res://art/fonts/Yomogi-subset.ttf")
const GAEGU := preload("res://art/fonts/Gaegu-subset.ttf")

static var _cache := {}

static func _lang() -> String:
	return TranslationServer.get_locale().substr(0, 2)

static func get_font() -> Font:
	var lang := _lang()
	if _cache.has(lang):
		return _cache[lang]
	var latin := FontVariation.new()
	latin.base_font = CAVEAT
	latin.variation_opentype = {2003265652: 560}   # wght: biraz dolgun kalem
	var chain: Array[Font] = []
	var primary: Font
	match lang:
		"ja":
			primary = YOMOGI
			chain = [latin, GAEGU]
		"ko":
			primary = GAEGU
			chain = [latin, YOMOGI]
		_:
			primary = latin
			chain = [YOMOGI, GAEGU]
	var f := FontVariation.new()
	f.base_font = primary
	f.fallbacks = chain
	_cache[lang] = f
	return f

## Dile göre punto düzeltmesi: Caveat küçük görünür, CJK el yazıları büyük.
static func scale_for_lang() -> float:
	match _lang():
		"ja", "ko": return 0.82
		_: return 1.0
