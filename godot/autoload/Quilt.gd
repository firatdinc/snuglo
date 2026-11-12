extends Node
## Benim Yorganım: her çözülen bölüm bir yama olur, oyuncunun kişisel yorganına dikilir.
## Yama = çözülmüş tahtanın kendisi (hücre → parça sırası, parça → renk) + o anki kumaş seti.
## PNG saklanmaz; PatchView kayıttan yeniden çizer. Her QUILT_SIZE yamada yorgan tamamlanır,
## arşive (raf) kalkar ve yeni yorgan başlar.
##
## Kayıt (Save "quilt"): {cur: [patch...], done: [[patch...], ...], total: int, pending: [rec...], tut_sew: bool}
## patch: {id, t, s, sec, w, g, c, f} (+ oyuncunun seçimi: pt, cs, ci, ai)
##   g: w*w karakter, hücre başına parça sırası ("a".."z", "A".."Z"); c: sıra → color_index; f: kumaş seti.
##   pt: desen (PatchShapes.PATTERNS; yoksa "board" = eski otomatik yamalar), cs/ci: seçilen kumaş seti/dokusu,
##   ai: vurgu kumaşı dokusu.
## Her biten bölüm bir DİKİLMEMİŞ yama (pending) kazandırır; oyuncu kumaş+desen seçip kendi diker (sew_next).
## Eski kayıtlardaki yamalar olduğu gibi yorganda kalır (pending yok → boş liste).

signal patch_added(patch: Dictionary, index: int)
signal quilt_completed(number: int)
signal pending_changed

const COLS := 8
const QUILT_SIZE := 64
const MAX_PENDING := 200
const ALPHABET := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

var _s: Dictionary
## Oyun ekranından yorgana uçacak son yama (menü/yorgan ekranı dikiş animasyonu için).
var pending_stitch := -1

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("quilt")
	if not _s.has("cur"):
		_s["cur"] = []
	if not _s.has("done"):
		_s["done"] = []
	if not _s.has("total"):
		_s["total"] = 0
	if not _s.has("pending"):
		_s["pending"] = []
	# Göç: yuva (slot) alanı olmayan eski yamalar sıradaki index'lerinde kalır.
	for q in (_s.done as Array) + [_s.cur]:
		for i in (q as Array).size():
			if not (q[i] as Dictionary).has("slot"):
				q[i]["slot"] = i

## Çözülmüş tahtadan yama kaydı üretir (saf; test edilebilir).
## occ: Vector2i → pid, pieces: Array[PieceData].
static func encode(level_id: String, width: int, occ: Dictionary, pieces: Array, stars: int,
		seconds: float, fabric_set: String, ts: int) -> Dictionary:
	var order := {}
	var colors: Array = []
	for p in pieces:
		if order.size() >= ALPHABET.length():
			break
		order[p.id] = order.size()
		colors.append(int(p.color_index))
	var g := ""
	for y in width:
		for x in width:
			var pid: String = String(occ.get(Vector2i(x, y), ""))
			g += ALPHABET[int(order[pid])] if order.has(pid) else "."
	return {"id": level_id, "t": ts, "s": stars, "sec": snappedf(seconds, 0.1), "w": width,
		"g": g, "c": colors, "f": fabric_set}

## Kayıttan parça listesi: [{cells: Array[Vector2i], color: int}] (PatchView çizer).
static func decode(patch: Dictionary) -> Array:
	var w := int(patch.get("w", 0))
	var g := String(patch.get("g", ""))
	var colors: Array = patch.get("c", [])
	var by := {}
	for i in mini(g.length(), w * w):
		var ch := g[i]
		if ch == ".":
			continue
		var k := ALPHABET.find(ch)
		if not by.has(k):
			var cells: Array[Vector2i] = []
			by[k] = {"cells": cells, "color": int(colors[k]) if k < colors.size() else k}
		(by[k].cells as Array).append(Vector2i(i % w, i / w))
	var out: Array = []
	var keys := by.keys()
	keys.sort()
	for k in keys:
		out.append(by[k])
	return out

## Kazanılan bölüm artık yorgana kendiliğinden dikilmez: dikilmeyi bekleyen yama olur.
## Döner: bekleyen sayısı.
func add_from_game(level_id: String, game: Node, stars: int, seconds: float) -> int:
	if game == null or game.lvl == null or game.board == null:
		return -1
	var p := encode(level_id, game.lvl.width, game.board.occ, game.lvl.pieces, stars, seconds,
		Fabrics.current_set, int(Time.get_unix_time_from_system()))
	return add_pending(p)

func add_pending(rec: Dictionary) -> int:
	var pend: Array = _s.pending
	pend.append(rec)
	while pend.size() > MAX_PENDING:
		pend.pop_front()
	Save.mark_dirty()
	pending_changed.emit()
	return pend.size()

func pending() -> Array:
	return _s.pending

func pending_count() -> int:
	return (_s.pending as Array).size()

## Oyuncunun seçimini kayda işler (saf). cs: kumaş seti, ci: ana doku, ai: vurgu dokusu.
static func with_choice(rec: Dictionary, pt: String, cs: String, ci: int, ai: int) -> Dictionary:
	var p := rec.duplicate()
	p["pt"] = pt
	p["cs"] = cs
	p["ci"] = ci
	p["ai"] = ai
	return p

## Vurgu kumaşı için varsayılan: bölümün ilk parça rengi; ana dokuyla aynıysa komşusu.
static func default_accent(rec: Dictionary, main_idx: int) -> int:
	var cols: Array = rec.get("c", [])
	var a := int(cols[0]) if not cols.is_empty() else main_idx + 3
	if a % Palette.PIECES.size() == main_idx % Palette.PIECES.size():
		a += 5
	return a % Palette.PIECES.size()

## Oyuncunun seçtiği boş yuvaya (slot 0..63) düz kumaş kare olarak dik. Döner: slot (geçersiz/dolu → -1).
## Tamamlanırsa (64) yorgan arşive kalkar; slot yine döner, completed_count artar.
func sew_next(slot: int, cs: String, ci: int) -> int:
	var pend: Array = _s.pending
	if pend.is_empty() or slot < 0 or slot >= QUILT_SIZE or slot in used_slots():
		return -1
	var rec: Dictionary = pend.pop_front()
	var p := with_choice(rec, "plain", cs, ci, ci)
	p["slot"] = slot
	Save.mark_dirty()
	pending_changed.emit()
	add_patch(p)
	return slot

## Yorgandaki (cur) dolu yuvalar.
func used_slots() -> Array:
	var out := []
	for p in (_s.cur as Array):
		out.append(int(p.get("slot", -1)))
	return out

func free_slots() -> Array:
	var used := used_slots()
	var out := []
	for i in QUILT_SIZE:
		if not i in used:
			out.append(i)
	return out

## Yama listesini yuva sırasına dizer: 64 elemanlı, boş yuva {} .
static func by_slot(patches: Array) -> Array:
	var out := []
	out.resize(QUILT_SIZE)
	out.fill({})
	for i in patches.size():
		var sl := int(patches[i].get("slot", i))
		if sl >= 0 and sl < QUILT_SIZE:
			out[sl] = patches[i]
	return out

func tutorial_sew_done() -> bool:
	return bool(_s.get("tut_sew", false))

func set_tutorial_sew_done() -> void:
	_s["tut_sew"] = true
	Save.mark_dirty()

func add_patch(p: Dictionary) -> int:
	var cur: Array = _s.cur
	if not p.has("slot") or int(p.slot) in used_slots():
		var fs := free_slots()
		p["slot"] = fs[0] if not fs.is_empty() else cur.size()
	cur.append(p)
	_s.total = int(_s.total) + 1
	var idx := cur.size() - 1
	pending_stitch = idx
	Save.mark_dirty()
	patch_added.emit(p, idx)
	if cur.size() >= QUILT_SIZE:
		(_s.done as Array).append(cur.duplicate())
		_s.cur = []
		pending_stitch = -1
		Save.mark_dirty()
		quilt_completed.emit((_s.done as Array).size())
		return -1
	return idx

func current() -> Array:
	return _s.cur

func archive() -> Array:
	return _s.done

func total() -> int:
	return int(_s.total)

func completed_count() -> int:
	return (_s.done as Array).size()

## Yamanın kenar türü: "gold" (3★), "season", "daily", "tower", "plain".
static func trim_of(patch: Dictionary) -> String:
	var id := String(patch.get("id", ""))
	var head := id.get_slice("-", 0)
	if head == "daily":
		return "daily"
	if head == "tower":
		return "tower"
	if Progress.is_season(id.rsplit("-", true, 1)[0]):
		return "season"
	if int(patch.get("s", 0)) >= 3:
		return "gold"
	return "plain"

func reset() -> void:
	_s.cur = []
	_s.done = []
	_s.total = 0
	_s.pending = []
	pending_stitch = -1
	Save.mark_dirty()
