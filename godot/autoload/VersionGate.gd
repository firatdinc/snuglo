extends Node
## Uzak sürüm kontrolü (Swift VersionGate): GitHub gist JSON'u okunur.
## sürüm < ios.minVersion → "forced" (kapatılamaz güncelleme duvarı)
## sürüm < ios.latestVersion → "soft" (kapatılabilir; kapatılan sürüm hatırlanır)
## Ağ/ayrıştırma hatası oyuncuyu ASLA engellemez (durum "unknown" kalır).
## Sürüm: ProjectSettings application/config/version. Masaüstü/test'te kontrol yapılmaz.

signal state_changed(state: String)

const CONFIG_URL := "https://gist.githubusercontent.com/firatdinc/aeb3a641f9ba15c3c837977de9eb1830/raw"
const APP_STORE_URL := "https://apps.apple.com/app/id6772764229"

var state := "unknown"      # unknown | up_to_date | soft | forced
var latest_version := ""
var _http: HTTPRequest
var _s: Dictionary

func _ready() -> void:
	_s = Save.get_section("version")
	Save.reloaded.connect(func() -> void: _s = Save.get_section("version"))
	if OS.has_feature("mobile"):
		check()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and OS.has_feature("mobile"):
		check()

func current_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0"))

func check() -> void:
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
	if not (cfg is Dictionary) or not (cfg.get("ios") is Dictionary):
		return
	apply_config(cfg)

## Yapılandırmayı uygula (test edilebilir).
func apply_config(cfg: Dictionary) -> void:
	latest_version = str(cfg.ios.get("latestVersion", ""))
	var cur := current_version()
	if is_less(cur, str(cfg.ios.get("minVersion", "0"))):
		state = "forced"
	elif is_less(cur, latest_version):
		state = "up_to_date" if String(_s.get("dismissed_soft", "")) == latest_version else "soft"
	else:
		state = "up_to_date"
	state_changed.emit(state)

func dismiss_soft() -> void:
	_s.dismissed_soft = latest_version
	Save.mark_dirty()
	if state == "soft":
		state = "up_to_date"
		state_changed.emit(state)

func open_store() -> void:
	OS.shell_open(APP_STORE_URL)

## "1.2" < "1.10" gibi sayısal karşılaştırma.
static func is_less(a: String, b: String) -> bool:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in maxi(pa.size(), pb.size()):
		var x := int(pa[i]) if i < pa.size() else 0
		var y := int(pb[i]) if i < pb.size() else 0
		if x != y:
			return x < y
	return false
