class_name UiArt
extends RefCounted
## ChatGPT UI dokuları için önbellekli yükleyici: art/ui/<ad>.png, art/mascot/<ad>.png.

static var _c := {}

static func tex(name: String, dir := "ui") -> Texture2D:
	var key := dir + "/" + name
	if not _c.has(key):
		var p := "res://art/%s/%s.png" % [dir, name]
		_c[key] = load(p) if ResourceLoader.exists(p) else null
	return _c[key]
