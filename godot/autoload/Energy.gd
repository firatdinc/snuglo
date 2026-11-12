extends Node
## Enerji (Swift EnergyStore): en çok 50, ücretli oyun başı -5, 3 dk'da +1 (zaman damgası
## çapası → uygulama kapalıyken de dolar). Premium sınırsız. Zen/Endless/Tower ücretsiz.
## Yarım kalan ücretli bölüme geri girmek tekrar ücretlendirmez (open_levels).

const MAX := 50
const COST := 5
const REGEN_SECONDS := 180.0
const AD_REFILL := 10

## Test/debug: unix saniye verilirse "şimdi" bu olur.
var now_override := -1.0
## Oyun ekranı bir kez "-5 ⚡" animasyonu oynatsın (consume_spend_animation ile tüketilir).
var pending_spend_animation := 0

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)

func _load() -> void:
	_s = Save.get_section("energy")
	if not _s.has("value"):
		_s["value"] = MAX
		_s["anchor"] = _now()
	if not _s.has("open_levels"):
		_s["open_levels"] = []

func _now() -> float:
	return now_override if now_override >= 0.0 else Time.get_unix_time_from_system()

## Sınırsız mı (premium).
func unlimited() -> bool:
	return Purchases.is_premium()

## Ücretsiz mod mu (zen/endless/tower bölümleri enerji harcamaz).
static func is_free_level(level_id: String) -> bool:
	return level_id.begins_with("endless") or level_id.begins_with("tower")

## Birikmiş dolumu uygula, güncel enerjiyi döndür.
func refresh() -> int:
	if unlimited():
		return MAX
	var now := _now()
	var v := int(_s.value)
	if v >= MAX:
		_s.anchor = now
		return v
	var gained := int((now - float(_s.anchor)) / REGEN_SECONDS)
	if gained > 0:
		v = mini(MAX, v + gained)
		_s.value = v
		_s.anchor = now if v >= MAX else float(_s.anchor) + gained * REGEN_SECONDS
		Save.mark_dirty()
	return v

var current: int:
	get: return refresh()

func is_full() -> bool:
	return refresh() >= MAX

func can_start_game() -> bool:
	return unlimited() or refresh() >= COST

## Sonraki 1 enerjiye kalan sn (dolu/premium → 0).
func seconds_until_next() -> int:
	if unlimited() or refresh() >= MAX:
		return 0
	var into := fmod(_now() - float(_s.anchor), REGEN_SECONDS)
	return maxi(0, ceili(REGEN_SECONDS - into))

## Oyun başlatabilecek kadar enerjiye kalan sn.
func seconds_until_playable() -> int:
	if can_start_game():
		return 0
	var needed := COST - refresh()
	var into := fmod(_now() - float(_s.anchor), REGEN_SECONDS)
	return maxi(0, ceili(REGEN_SECONDS - into + (needed - 1) * REGEN_SECONDS))

## Oyun başlat: yeterliyse 5 düş. level_id verilirse yarım kalan girişte ücret alınmaz.
## Ücretsiz bölümler (endless/tower) ve premium hep true.
func start_game(level_id := "") -> bool:
	if unlimited() or is_free_level(level_id):
		return true
	if level_id != "" and level_id in _s.open_levels:
		return true
	if refresh() < COST:
		return false
	_spend(level_id)
	return true

## Ücretli bölümü bilerek yeniden başlatma = yeni deneme, yine ücretli.
func charge_restart(level_id: String) -> bool:
	if unlimited() or is_free_level(level_id):
		return true
	if refresh() < COST:
		return false
	_spend(level_id)
	return true

func _spend(level_id: String) -> void:
	if int(_s.value) >= MAX:
		_s.anchor = _now()
	_s.value = int(_s.value) - COST
	if level_id != "" and not level_id in _s.open_levels:
		(_s.open_levels as Array).append(level_id)
	pending_spend_animation = COST
	Save.mark_dirty()

## Bölüm bitince (Progress.record_level çağırır): sonraki taze başlangıç yine ücretli.
func end_paid_session(level_id: String) -> void:
	if level_id in _s.open_levels:
		(_s.open_levels as Array).erase(level_id)
		Save.mark_dirty()

func consume_spend_animation() -> int:
	var a := pending_spend_animation
	pending_spend_animation = 0
	return a

## Enerji ver (ödüllü reklam +10, hediye). En çok MAX.
func add(amount: int) -> void:
	if unlimited() or amount <= 0:
		return
	var v := refresh()
	if v >= MAX:
		_s.anchor = _now()
	_s.value = mini(MAX, v + amount)
	Save.mark_dirty()

## İlerlemeyi sıfırla → dolu bar.
func reset() -> void:
	_s.value = MAX
	_s.anchor = _now()
	_s.open_levels = []
	pending_spend_animation = 0
	Save.mark_dirty()
