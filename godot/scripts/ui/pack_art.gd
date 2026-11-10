class_name PackArt
extends RefCounted
## Paket görselleri: sahne (art/scene/<ad>.jpg) ve paket hayvanı. Eksik sahne → yedek zincir.
## Hayvanlar henüz yok: animal() maskot pozlarından döner — gelince tek satır değişir.

const FALLBACK := ["island", "forest", "flower", "beach", "mushroom", "lake"]
static var _c := {}

## "scene-forest" ya da "forest" → doku. Yoksa ada göre deterministik yedek.
## Kış teması (Xmas.winter_active): yaz sahneleri kışlık karşılığıyla değişir —
## art/scene_winter/<ad>.jpg (ChatGPT, aynı konsept) varsa o, yoksa karlı "snow" sahnesi.
const WINTER_NATIVE := ["snow", "christmas", "winter_cocoa"]

static func scene_by_name(name: String) -> Texture2D:
	name = name.trim_prefix("scene-")
	if Xmas.winter_active() and name not in WINTER_NATIVE:
		var wk := "winter/" + name
		if not _c.has(wk):
			var wp := "res://art/scene_winter/%s.jpg" % name
			_c[wk] = load(wp) if ResourceLoader.exists(wp) else scene_by_name("snow")
		return _c[wk]
	if _c.has(name):
		return _c[name]
	var t: Texture2D = null
	var p := "res://art/scene/%s.jpg" % name
	if ResourceLoader.exists(p):
		t = load(p)
	else:
		var alt: String = FALLBACK[absi(name.hash()) % FALLBACK.size()]
		for k in [alt] + FALLBACK:
			var q := "res://art/scene/%s.jpg" % k
			if ResourceLoader.exists(q):
				t = load(q)
				break
	_c[name] = t
	return t

static func has_scene(name: String) -> bool:
	return ResourceLoader.exists("res://art/scene/%s.jpg" % name.trim_prefix("scene-"))

static func scene(pack_id: String) -> Texture2D:
	return scene_by_name(String(Progress.pack(pack_id).get("scene", "scene-island")))

static func scene_name(pack_id: String) -> String:
	return String(Progress.pack(pack_id).get("scene", "scene-island")).trim_prefix("scene-")

## Paket dostu (art/friends/<id>.png, peluş). Nook'ta "kurtarılan dost". Sıra = Progress.PACKS.
const FRIENDS := {
	"cozy-beginnings": "sloth", "spice-route": "fox", "mambo-nights": "owl", "woodland-retreat": "hedgehog",
	"morning-meadow": "cow", "amber-harbor": "lion", "velvet-dusk": "bee", "hearth-tales": "hippo",
	"misty-grove": "cactus", "honey-fields": "turtle", "lantern-lane": "bunny", "frost-haven": "penguin",
	"garden-party": "frog", "ocean-breeze": "redpanda", "starlit-peak": "tiger", "cocoa-cabin": "bear",
	"aurora-vale": "koala", "winter-quilt": "reindeer", "advent-quilt": "santa",
}

static func friend_id(pack_id: String) -> String:
	return String(FRIENDS.get(pack_id, "sloth"))

## Paketin hayvanı; dosya yoksa maskot pozu (pose ya da idle).
static func animal(pack_id: String, pose := "") -> Texture2D:
	var t := friend(friend_id(pack_id))
	if t:
		return t
	return UiArt.tex(pose if pose != "" else "idle", "mascot")

static func friend(id: String) -> Texture2D:
	# Noel: şapkalı peluş (art/friends_xmas/, ChatGPT) varsa onu kullan.
	var xp := "res://art/friends_xmas/%s.png" % id
	var xm := Xmas.hats_on() and ResourceLoader.exists(xp)
	var key := ("friend_xmas/" if xm else "friend/") + id
	if not _c.has(key):
		var p := xp if xm else "res://art/friends/%s.png" % id
		_c[key] = load(p) if ResourceLoader.exists(p) else null
	return _c[key]

## Nook dekor görseli (art/nook/<id>.png); yoksa null (çağıran yedek çizer).
static func decor(id: String) -> Texture2D:
	var key := "decor/" + id
	if not _c.has(key):
		var p := "res://art/nook/%s.png" % id
		_c[key] = load(p) if ResourceLoader.exists(p) else null
	return _c[key]

## Grid boyutundan zorluk anahtarı.
static func difficulty_key(grid: int) -> String:
	return "pack.difficulty." + ("beginner" if grid <= 5 else ("easy" if grid == 6 else ("medium" if grid == 7 else "hard")))

## Paketin imza kumaşı (kart dokusu).
static func fabric(pack_id: String) -> int:
	if Progress.is_season(pack_id):
		return int(Progress.pack(pack_id).get("fabric", 7))
	return maxi(0, Progress.pack_index(pack_id)) % 12
