class_name PatchShapes
extends RefCounted
## Yorgan yaması desenleri (oyuncunun seçtiği). Birim kare (0..1) koordinatlarında çokgenler:
## who 0 = ana kumaş, 1 = vurgu kumaşı. "board" = bölümün çözülmüş tahtası (parçalar kendi renginde,
## seçilen kumaş çerçeve olur). Hepsi saf ve deterministik: aynı kayıt hep aynı yamayı çizer.

const PATTERNS := ["board", "plain", "tri", "four", "strips", "star", "heart"]
## Çerçeve değil, kumaşın kendisi çizilen desenler.
const SHAPED := ["plain", "tri", "four", "strips", "star", "heart"]

static func is_shaped(pt: String) -> bool:
	return pt in SHAPED

static func _sq(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])

static func shapes(pt: String) -> Array:
	var full := _sq(0, 0, 1, 1)
	match pt:
		"tri":
			return [{"poly": full, "who": 0},
				{"poly": PackedVector2Array([Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), "who": 1}]
		"four":
			return [{"poly": _sq(0, 0, 0.5, 0.5), "who": 0}, {"poly": _sq(0.5, 0, 0.5, 0.5), "who": 1},
				{"poly": _sq(0, 0.5, 0.5, 0.5), "who": 1}, {"poly": _sq(0.5, 0.5, 0.5, 0.5), "who": 0}]
		"strips":
			var out := []
			for i in 4:
				out.append({"poly": _sq(i * 0.25, 0, 0.25, 1), "who": i % 2})
			return out
		"star":
			var pts := PackedVector2Array()
			for i in 16:
				var r := 0.41 if i % 2 == 0 else 0.19
				pts.append(Vector2(0.5, 0.5) + Vector2.from_angle(-PI / 2.0 + i * PI / 8.0) * r)
			return [{"poly": full, "who": 0}, {"poly": pts, "who": 1, "appl": true}]
		"heart":
			var pts := PackedVector2Array()
			for i in 48:
				var t := i * TAU / 48.0
				var x := 16.0 * pow(sin(t), 3.0)
				var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
				pts.append(Vector2(0.5 + x * 0.0245, 0.5 - (y + 2.5) * 0.0245))
			return [{"poly": full, "who": 0}, {"poly": pts, "who": 1, "appl": true}]
	return [{"poly": full, "who": 0}]
