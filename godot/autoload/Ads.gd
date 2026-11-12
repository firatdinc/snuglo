extends Node
## Reklam kuralları (Swift AdsManager) + iOS'ta gerçek AdMob (Poing 5.1.0, autoload/ads_admob.gd).
## Kurallar: geçiş reklamı her 3 tamamlamada bir, oturumun ilk 30 sn'sinde yok, oturum
## başına en çok 5; ödüllüde 45 sn bekleme + günde en çok 20. Reklamsız/premium → hepsi kapalı.
## iOS: UMP rızası → ATT (canlı sürümün istemi) → SDK → önden yükleme; debug build'de Google test
## birimleri. Masaüstü/test: eklenti yok → is_supported() false; ödüllü reklam debug build'de
## anında ödül verir (yalnız masaüstü), sürümde hiç verilmez.

const INTERSTITIAL_EVERY := 3
const MAX_INTERSTITIALS_PER_SESSION := 5
const WARMUP_SECONDS := 30.0
const REWARDED_COOLDOWN := 45.0
const MAX_REWARDED_PER_DAY := 20

## AdMob iOS (Fırat'ın hesabı ca-app-pub-8571533711927103). Uygulama kimliği project.godot
## [admob] general/ios/app_id → Info.plist GADApplicationIdentifier (boşsa her açılışta çöker).
const IOS_APP_ID := "ca-app-pub-8571533711927103~5613795076"
const IOS_INTERSTITIAL := "ca-app-pub-8571533711927103/7206078348"
const IOS_REWARDED := "ca-app-pub-8571533711927103/4579915005"
## Google'ın resmi iOS test birimleri (debug build).
const TEST_INTERSTITIAL := "ca-app-pub-3940256099942544/4411468910"
const TEST_REWARDED := "ca-app-pub-3940256099942544/1712485313"
const PROVIDER := "res://autoload/ads_admob.gd"

var _completions := 0
var _interstitials := 0
var _session_start := 0.0
var _s: Dictionary
var _p: Node = null          # ads_admob.gd (yalnız iOS + eklenti)
var _on_reward := Callable()
var _muted_before := false

func _ready() -> void:
	_session_start = Time.get_unix_time_from_system()
	_load()
	Save.reloaded.connect(_load)
	if OS.get_name() == "iOS" and Engine.has_singleton("PoingGodotAdMob"):
		_p = load(PROVIDER).new()
		_p.name = "AdMob"
		var dbg := OS.is_debug_build()
		_p.interstitial_unit = TEST_INTERSTITIAL if dbg else IOS_INTERSTITIAL
		_p.rewarded_unit = TEST_REWARDED if dbg else IOS_REWARDED
		add_child(_p)
		_p.finished.connect(_on_finished)
		_p.tracking_decided.connect(func(st: int) -> void: set_consent(st == 3))
		Purchases.entitlements_changed.connect(func() -> void:
			if enabled():
				_p.ensure_sdk())
		# ATT penceresi yalnız uygulama etkinken çıkar: ilk kareler geçsin.
		get_tree().create_timer(1.0).timeout.connect(func() -> void: _p.start(enabled()))

func _load() -> void:
	_s = Save.get_section("ads")
	var d := {"day": "", "count": 0, "last": 0.0, "consent": false}
	for k in d:
		if not _s.has(k):
			_s[k] = d[k]

func is_supported() -> bool:
	return _p != null

func enabled() -> bool:
	return not Purchases.ads_removed()

## Bölüm tamamlandı: geçiş reklamı gösterilmeli mi (sayaç ilerler). iOS'ta true dönerse
## reklam şu an gösterilmeye başlamıştır.
func on_level_completed() -> bool:
	if not enabled():
		return false
	_completions += 1
	if _completions % INTERSTITIAL_EVERY != 0:
		return false
	if Time.get_unix_time_from_system() - _session_start < WARMUP_SECONDS:
		return false
	if _interstitials >= MAX_INTERSTITIALS_PER_SESSION:
		return false
	if _p == null or not _p.interstitial_ready():
		return false
	if not _p.show_interstitial():
		return false
	_interstitials += 1
	_mute(true)
	return true

func _roll_day() -> void:
	var today := Progress.local_key()
	if today > String(_s.day):
		_s.day = today
		_s.count = 0

## Ödüllü reklam şu an gösterilebilir mi (yüklü + bekleme bitti + günlük sınır altında).
## Reklamsız/premium: reklam hiç açılmaz, ödül anında verilir (yalnız günlük sınır geçerli).
func rewarded_ready() -> bool:
	_roll_day()
	if not enabled():
		return int(_s.count) < MAX_REWARDED_PER_DAY
	var loaded: bool = _p.rewarded_ready() if _p != null else _desktop_fallback()
	return loaded and int(_s.count) < MAX_REWARDED_PER_DAY \
		and Time.get_unix_time_from_system() - float(_s.last) >= REWARDED_COOLDOWN

func rewarded_cooldown_remaining() -> int:
	if not enabled():
		return 0
	return maxi(0, int(REWARDED_COOLDOWN - (Time.get_unix_time_from_system() - float(_s.last))))

## Ödüllü reklam; on_reward yalnız sonuna kadar izlenirse (reklam kapanınca) çağrılır.
func show_rewarded(on_reward: Callable) -> void:
	if not rewarded_ready():
		return
	if not enabled():
		_s.count = int(_s.count) + 1
		Save.mark_dirty()
		on_reward.call()
		return
	if _p != null:
		_on_reward = on_reward
		_mute(true)
		if not _p.show_rewarded():
			_on_reward = Callable()
			_mute(false)
			return
	_s.count = int(_s.count) + 1
	_s.last = Time.get_unix_time_from_system()
	Save.mark_dirty()
	if _p == null and _desktop_fallback():
		print("[Ads] DEBUG ödüllü reklam: ödül verildi")
		on_reward.call()

## Debug anında-ödül yalnız masaüstünde (cihazda gerçek/test reklamı gelir).
func _desktop_fallback() -> bool:
	return OS.is_debug_build() and OS.get_name() != "iOS" and OS.get_name() != "Android"

func _on_finished(_shown: bool, earned: bool) -> void:
	_mute(false)
	var cb := _on_reward
	_on_reward = Callable()
	if earned and cb.is_valid():
		cb.call()

## Reklam sesi oyun müziğiyle çakışmasın: tam ekran reklam boyunca ana veri yolu sessiz.
func _mute(on: bool) -> void:
	if on:
		_muted_before = AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, _muted_before)

func set_consent(v: bool) -> void:
	_s.consent = v
	Save.mark_dirty()
