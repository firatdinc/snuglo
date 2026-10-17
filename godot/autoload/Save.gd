extends Node
## Tek versiyonlu JSON kayıt dosyası (user://snuglo_save.json). Her sistem kendi bölümünü
## `get_section(ad)` ile alır (referans Dictionary), değiştirip `mark_dirty()` çağırır.
## Yazım 0.5 sn debounce'lu; uygulama arka plana/kapanışa giderken hemen flush edilir.
## iOS: kayıt iCloud KV'ye de yedeklenir (SnugloBridge.cloud_save, en çok 30 sn'de bir + arka plana
## geçişte); yerel kayıt yoksa (yeni cihaz / yeniden kurulum) ilk açılışta oradan geri yüklenir.
## Testler için yol: SNUG_SAVE ortam değişkeni.

## Bölümler yeniden yüklendi (import_code / reset_all sonrası) → sistemler durumunu tazelesin.
signal reloaded

const SCHEMA := 1
const DEFAULT_PATH := "user://snuglo_save.json"
## Yedek kodu: "SNUG2:" + base64(JSON) + "." + imza (tuzlu SHA-256'nın ilk 16 hanesi). İmza
## tutmayan (elle düzenlenmiş) kod reddedilir. SNUG1 (imzasız) yalnız geliştirme yapılarında vardı.
const CODE_HEADER := "SNUG2:"
const _CODE_SALT := "snuglo·yorgan·7f3a91c2·dikis"
## Canlı SwiftUI 1.2.0 yedek kodu: base64(binary plist {app: "snuglo", v: 1, data: {...}}).
const CLOUD_KEY := "snuglo.v2.save"
const CLOUD_INTERVAL := 30.0
const CLOUD_MAX := 900000
const DEBOUNCE := 0.5
const _LEGACY := preload("res://autoload/legacy_import.gd")

var path := DEFAULT_PATH
var _data: Dictionary = {}
var _dirty := false
var _timer: Timer
var _cloud_dirty := false
var _cloud_timer: Timer
var _cloud_at := -1000.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var env := OS.get_environment("SNUG_SAVE")
	if env != "":
		path = env
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = DEBOUNCE
	_timer.timeout.connect(flush)
	add_child(_timer)
	_cloud_timer = Timer.new()
	_cloud_timer.one_shot = true
	_cloud_timer.timeout.connect(_cloud_push.bind(false))
	add_child(_cloud_timer)
	var fresh := not FileAccess.file_exists(path)
	_data = _read(path)
	if fresh:
		_restore_from_cloud()
	_import_native_legacy()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PREDELETE:
		flush()
		if what != NOTIFICATION_PREDELETE:
			_cloud_push(true)

## Bölümü döndürür (yoksa boş oluşturur). Dönen Dictionary canlı referanstır.
func get_section(name: String) -> Dictionary:
	if not _data.has(name) or not (_data[name] is Dictionary):
		_data[name] = {}
	return _data[name]

## Değişiklik var → 0.5 sn sonra yaz (art arda çağrılar tek yazıma iner).
func mark_dirty() -> void:
	_dirty = true
	if _timer and _timer.is_inside_tree():
		_timer.start()

## Bekleyen değişikliği hemen diske yaz.
func flush() -> void:
	if not _dirty:
		return
	_dirty = false
	if _timer:
		_timer.stop()
	_data["schema"] = SCHEMA
	_data["saved_at"] = int(Time.get_unix_time_from_system())
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Save: yazılamadı %s (%d)" % [tmp, FileAccess.get_open_error()])
		return
	f.store_string(JSON.stringify(_data))
	f.close()
	DirAccess.rename_absolute(tmp, path)
	_cloud_dirty = true
	_cloud_push(false)

func _bridge() -> Object:
	if OS.get_name() != "iOS" or not Engine.has_singleton("SnugloBridge"):
		return null
	var b := Engine.get_singleton("SnugloBridge")
	return b if b.has_method("cloud_save") else null

## Kaydı iCloud KV'ye yaz (force: arka plana geçiş; değilse CLOUD_INTERVAL sn'de bir).
func _cloud_push(force: bool) -> void:
	if not _cloud_dirty:
		return
	var b := _bridge()
	if b == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not force and now - _cloud_at < CLOUD_INTERVAL:
		if _cloud_timer and _cloud_timer.is_inside_tree() and _cloud_timer.is_stopped():
			_cloud_timer.start(CLOUD_INTERVAL - (now - _cloud_at) + 0.1)
		return
	var json := JSON.stringify(_data)
	if json.length() > CLOUD_MAX:
		push_warning("Save: iCloud için çok büyük (%d)" % json.length())
		return
	b.cloud_save(CLOUD_KEY, json)
	_cloud_at = now
	_cloud_dirty = false

## Yerel kayıt yok → iCloud'daki v2 kaydını geri yükle (varsa).
func _restore_from_cloud() -> void:
	var b := _bridge()
	if b == null:
		return
	var parsed = JSON.parse_string(String(b.cloud_load(CLOUD_KEY)))
	if parsed is Dictionary and parsed.has("schema"):
		_data = _migrate(parsed)
		_dirty = true
		flush()
		print("[Save] iCloud yedeğinden geri yüklendi")

## Tüm ilerlemeyi siler (Ayarlar → ilerlemeyi sıfırla).
func reset_all() -> void:
	_data = {"schema": SCHEMA}
	_dirty = true
	flush()
	reloaded.emit()

static func _sign(body: String) -> String:
	return (_CODE_SALT + body + _CODE_SALT).sha256_text().left(16)

## Taşınabilir yedek kodu: "SNUG2:" + base64(JSON) + "." + imza.
func export_code() -> String:
	var copy := _data.duplicate(true)
	copy["schema"] = SCHEMA
	var body := Marshalls.utf8_to_base64(JSON.stringify(copy))
	return CODE_HEADER + body + "." + _sign(body)

## Yedek kodu geri yükler: SNUG2 (imzalı) ya da canlı 1.2.0'ın plist kodu (yalnız iOS).
## Başlık/imza/JSON geçersizse hiçbir şeye dokunmadan false döner.
func import_code(code: String) -> bool:
	var c := code.strip_edges().replace("\n", "").replace(" ", "")
	if not c.begins_with(CODE_HEADER):
		return _import_v1_code(c)
	var parts := c.substr(CODE_HEADER.length()).split(".")
	if parts.size() != 2 or parts[1] != _sign(parts[0]):
		return false
	var body := parts[0]
	var re := RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$")
	if body.length() % 4 != 0 or re.search(body) == null:
		return false
	var raw := Marshalls.base64_to_utf8(body)
	if raw == "":
		return false
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return false
	_data = _migrate(parsed)
	_dirty = true
	flush()
	reloaded.emit()
	return true

## Swift SaveTransfer kodu (base64 binary plist). Plist çözümü native köprüde; anahtarlar
## legacy_import eşlemesinden geçip mevcut kaydın üstüne yazılır (Swift de anahtar anahtar yazardı).
func _import_v1_code(c: String) -> bool:
	if c.length() < 16 or c.length() % 4 != 0 or RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$").search(c) == null:
		return false
	var b := _bridge()
	if b == null or not b.has_method("decode_plist"):
		return false
	var bytes := Marshalls.base64_to_raw(c)
	if bytes.is_empty():
		return false
	var payload = b.decode_plist(bytes)
	if not (payload is Dictionary) or String(payload.get("app", "")) != "snuglo" or not (payload.get("data") is Dictionary):
		return false
	var d := _data.duplicate(true)
	var n: int = _LEGACY.apply(d, payload.data)
	if n == 0:
		return false
	d["legacy_imported"] = true
	_data = d
	_dirty = true
	flush()
	reloaded.emit()
	print("[Save] 1.2.0 kodu içe aktarıldı: %d anahtar" % n)
	return true

## Eski Swift sürümünün UserDefaults sözlüğünü (native köprü okur) yeni kayda aktarır.
## Bir kez çalışır (legacy_imported bayrağı); force=true tekrar uygular. Dönüş: işlenen anahtar.
func import_legacy(defaults: Dictionary, force := false) -> int:
	if bool(_data.get("legacy_imported", false)) and not force:
		return 0
	var n: int = _LEGACY.apply(_data, defaults)
	_data["legacy_imported"] = true
	_dirty = true
	flush()
	reloaded.emit()
	return n

## iOS ilk açılış: canlı SwiftUI sürümünün (aynı bundle id) UserDefaults + iCloud KV kaydını
## SnugloBridge'den okuyup bir kez içe aktarır. Kayıt dosyası zaten varsa (Godot sürümü daha
## önce açıldı) legacy_imported bayrağı tekrarı engeller.
func _import_native_legacy() -> void:
	if OS.get_name() != "iOS" or not Engine.has_singleton("SnugloBridge"):
		return
	if bool(_data.get("legacy_imported", false)):
		return
	var b := Engine.get_singleton("SnugloBridge")
	var merged := merge_legacy(b.legacy_defaults(), b.ubiquitous_kv())
	var n := import_legacy(merged)
	# Eski sürümde ücretli hak işaretliyse Purchases ilk açılışta sessizce RC restore yapar.
	if bool(merged.get("snuglo.premium.active", false)) or bool(merged.get("snuglo.ads.removed", false)) \
			or merged.has("snuglo.purchased.v1"):
		_data["legacy_iap_restore"] = true
		_dirty = true
		flush()
	print("[Save] legacy import: %d anahtar (%d UserDefaults)" % [n, merged.size()])

## Swift CloudSync kuralı: iCloud KV'nin revizyonu ("snuglo.cloud.rev") yereldekinden BÜYÜKSE
## KV değerleri UserDefaults'u ezer (yeni cihaz / yeniden kurulum); değilse yerel kazanır.
static func merge_legacy(defaults: Dictionary, kv: Dictionary) -> Dictionary:
	var out := defaults.duplicate()
	if int(kv.get("snuglo.cloud.rev", 0)) > int(defaults.get("snuglo.cloud.rev", 0)):
		for k in kv:
			out[k] = kv[k]
	return out

## Ham kayıt (debug/test).
func raw() -> Dictionary:
	return _data

func _read(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {"schema": SCHEMA}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (parsed is Dictionary):
		push_warning("Save: bozuk kayıt, sıfırdan başlanıyor")
		DirAccess.rename_absolute(p, p + ".bad")
		return {"schema": SCHEMA}
	return _migrate(parsed)

## Şema göçü: eski sürümleri SCHEMA'ya getirir. Yeni alan eklerken sistemler
## varsayılanla okuduğu için çoğu değişiklik göç gerektirmez.
func _migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("schema", 1))
	# if v < 2: ... (gelecek göçler buraya)
	d["schema"] = maxi(v, SCHEMA)
	return d
