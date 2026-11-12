extends Node
## Uzak canlı ayar (güncelleme beklemeden sezon/etkinlik aç-kapa). GitHub gist JSON'u:
##   {"seasons": {"advent-quilt": {"enabled": true, "start": "2026-12-01", "end": "2026-12-31"}}}
## - "enabled": false → sezon tarihten bağımsız KAPALI; true → tarih penceresinde açık.
## - "start"/"end" verilirse koddaki tarihlerin yerine geçer.
## - Progress.SEASONS'ta "remote": true olan sezon, uzaktan enabled=true gelmeden hiç açılmaz.
## Son başarılı yanıt kayda yazılır (çevrimdışı açılışta da geçerli). Ağ/ayrıştırma hatası
## mevcut durumu bozmaz. Açılışta ve uygulama öne gelince yeniden okunur.

signal changed

const CONFIG_URL := "https://gist.githubusercontent.com/erguncengiz/a56801f63e056845fe2a546b9dbc6704/raw/snuglo_live.json"

var _http: HTTPRequest
var _s: Dictionary

func _ready() -> void:
	_s = Save.get_section("live")
	Save.reloaded.connect(func() -> void: _s = Save.get_section("live"))
	if _should_fetch():
		fetch.call_deferred()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and _should_fetch():
		fetch()

func _should_fetch() -> bool:
	return DisplayServer.get_name() != "headless" and not CONFIG_URL.contains("GIST_ID")

func fetch() -> void:
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 8.0
		_http.request_completed.connect(_on_done)
		add_child(_http)
	if _http.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_http.request(CONFIG_URL, ["Cache-Control: no-cache"])

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var cfg = JSON.parse_string(body.get_string_from_utf8())
	if cfg is Dictionary:
		apply(cfg)

## Yapılandırmayı uygula ve kaydet (test edilebilir).
func apply(cfg: Dictionary) -> void:
	var seasons = cfg.get("seasons", {})
	if not (seasons is Dictionary):
		return
	_s.seasons = seasons
	Save.mark_dirty()
	changed.emit()

## Sezonun uzak ayarı ({} = yok).
func season(id: String) -> Dictionary:
	var all = _s.get("seasons", {})
	if all is Dictionary and all.get(id) is Dictionary:
		return all[id]
	return {}
