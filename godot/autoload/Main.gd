extends Node
## Oturum yönlendirici (şimdilik yalnız oyun). Menü/harita sonraki fazda.
## Geliştirme: SNUG_LEVEL=cozy-beginnings:3  SNUG_SHOT=<sn>:<yol>  SNUG_AUTO=<n yerleşim>  SNUG_DAILY=1

var pack := "cozy-beginnings"
var index := 1
const PACKS := {"cozy-beginnings": 5, "spice-route": 6, "mambo-nights": 7, "woodland-retreat": 8}

func _ready() -> void:
	var env := OS.get_environment("SNUG_LEVEL")
	if env != "":
		pack = env.get_slice(":", 0)
		index = int(env.get_slice(":", 1))

func current_level() -> LevelData:
	if OS.get_environment("SNUG_DAILY") != "":
		return DailyPuzzle.today(0)
	return LevelGenerator.generate(pack, index, PACKS.get(pack, 5))

func next_level() -> void:
	index += 1
	if index > 60:
		var keys := PACKS.keys()
		pack = keys[(keys.find(pack) + 1) % keys.size()]
		index = 1
	get_tree().reload_current_scene()
