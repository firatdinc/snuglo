extends Node
## Nook = sahne restorasyonu (Swift NookStore v2). Her paketin sahnesi 6 parçaya bölünür;
## pakette her 10 tamamlanan bölüm 1 parça hakkı verir (türetilmiş, ödül kancası yok).
## Oyuncu parçayı sürükleyip yerleştirir (yalnız "placed" kaydedilir). Paket tamamen
## bitince maskotu kurtarılır. Sahne/maskot: Progress.PACKS[].scene / .art.

const PIECES_PER_SCENE := 6
const LEVELS_PER_PIECE := 10

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("nook")
	if not _s.has("placed"):
		_s["placed"] = {}

func earned_pieces(pack_id: String) -> int:
	return mini(PIECES_PER_SCENE, Progress.pack_completed_count(pack_id) / LEVELS_PER_PIECE)

func placed_pieces(pack_id: String) -> int:
	return mini(PIECES_PER_SCENE, int((_s.placed as Dictionary).get(pack_id, 0)))

func available_pieces(pack_id: String) -> int:
	return maxi(0, earned_pieces(pack_id) - placed_pieces(pack_id))

func is_restored(pack_id: String) -> bool:
	return placed_pieces(pack_id) >= PIECES_PER_SCENE

## Sıradaki parçayı yerleştir. Yerleşen index (0 tabanlı) ya da -1.
func place_next_piece(pack_id: String) -> int:
	var cur := placed_pieces(pack_id)
	if cur >= earned_pieces(pack_id):
		return -1
	_s.placed[pack_id] = cur + 1
	Save.mark_dirty()
	return cur

## Tüm paketlerde yerleştirilmeyi bekleyen parça (menü rozeti).
func total_available() -> int:
	var n := 0
	for p in Progress.PACKS:
		n += available_pieces(p.id)
	return n

func is_mascot_unlocked(pack_id: String) -> bool:
	return Progress.is_pack_complete(pack_id)

func unlocked_mascot_count() -> int:
	return Progress.packs_completed()

## 0..1: yerleşen parça / (paket sayısı × 6).
func completion() -> float:
	var done := 0
	for p in Progress.PACKS:
		done += placed_pieces(p.id)
	return minf(1.0, float(done) / float(Progress.PACKS.size() * PIECES_PER_SCENE))

func reset() -> void:
	_s.placed = {}
	Save.mark_dirty()
