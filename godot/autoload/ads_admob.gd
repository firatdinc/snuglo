extends Node
## Poing AdMob 5.1.0 sağlayıcısı (yalnız iOS; Ads.gd çalışma anında load() ile yükler, masaüstü
## testleri bu dosyayı hiç derlemez). ~/WaterSort/globals/AdMobProvider.gd'den uyarlandı.
## Akış: UMP rıza bilgisi → (gerekiyorsa) rıza formu → ATT istemi → MobileAds.initialize → önden yükle.
## Her gösterimden sonra destroy() (eklenti belgesi: yok edilmeyen reklam yerli bellekte kalır)
## ve sıradaki hemen yüklenir.

signal finished(shown: bool, earned: bool)
signal tracking_decided(status: int)

var interstitial_unit := ""
var rewarded_unit := ""
var _interstitial: InterstitialAd
var _rewarded: RewardedAd
var _inter_loader := InterstitialAdLoader.new()
var _rew_loader := RewardedAdLoader.new()
var _consent: ConsentInformation
var _started := false
var _showing := false
var _earned := false
var _init_sdk := true

## init_sdk=false: yalnız rıza + ATT (reklamsız kullanıcı), SDK başlatılmaz.
func start(init_sdk: bool) -> void:
	_init_sdk = init_sdk
	_consent = ConsentInformation.new()
	_consent.update(ConsentRequestParameters.new(),
		func() -> void:
			# Form yalnız rıza GEREKLİ iken (AB/BK, henüz sorulmamış); her açılışta değil.
			if _consent.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED \
					and _consent.get_is_consent_form_available():
				UserMessagingPlatform.load_consent_form(
					func(form: ConsentForm) -> void: form.show(func(_e: FormError) -> void: _after_consent()),
					func(_e: FormError) -> void: _after_consent())
			else:
				_after_consent(),
		func(_e: FormError) -> void: _after_consent())

## ATT, UMP'den SONRA (Google'ın önerdiği sıra); canlı sürümdeki istemin aynısı
## (NSUserTrackingUsageDescription). Yalnız henüz sorulmadıysa sistem penceresi çıkar.
func _after_consent() -> void:
	var b = Engine.get_singleton("SnugloBridge") if Engine.has_singleton("SnugloBridge") else null
	if b == null:
		_start_sdk()
		return
	if int(b.tracking_status()) != 0:
		tracking_decided.emit(int(b.tracking_status()))
		_start_sdk()
		return
	b.tracking_result.connect(func(st: int) -> void:
		tracking_decided.emit(st)
		_start_sdk(), CONNECT_ONE_SHOT)
	b.request_tracking()

func _start_sdk() -> void:
	if _started or not _init_sdk:
		return
	_started = true
	var on_init := OnInitializationCompleteListener.new()
	on_init.on_initialization_complete = func(_s: InitializationStatus) -> void:
		_load_interstitial()
		_load_rewarded()
	MobileAds.set_request_configuration(RequestConfiguration.new())
	MobileAds.initialize(on_init)

## Reklamsız alındıysa sonradan çağrılabilir; zaten başladıysa no-op.
func ensure_sdk() -> void:
	_init_sdk = true
	if _consent != null:
		_start_sdk()

func interstitial_ready() -> bool:
	return _interstitial != null and not _showing

func rewarded_ready() -> bool:
	return _rewarded != null and not _showing

func show_interstitial() -> bool:
	if not interstitial_ready():
		return false
	_showing = true
	_interstitial.show()
	return true

func show_rewarded() -> bool:
	if not rewarded_ready():
		return false
	_showing = true
	_earned = false
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void: _earned = true
	_rewarded.show(listener)
	return true

func _load_interstitial() -> void:
	if interstitial_unit == "":
		return
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial = ad
		var fs := FullScreenContentCallback.new()
		fs.on_ad_dismissed_full_screen_content = func() -> void: _done_interstitial(true)
		fs.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void: _done_interstitial(false)
		ad.full_screen_content_callback = fs
	cb.on_ad_failed_to_load = func(_e: LoadAdError) -> void:
		_interstitial = null
		get_tree().create_timer(30.0).timeout.connect(_load_interstitial)
	_inter_loader.load(interstitial_unit, AdRequest.new(), cb)

func _load_rewarded() -> void:
	if rewarded_unit == "":
		return
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded = ad
		var fs := FullScreenContentCallback.new()
		fs.on_ad_dismissed_full_screen_content = func() -> void: _done_rewarded(true)
		fs.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void: _done_rewarded(false)
		ad.full_screen_content_callback = fs
	cb.on_ad_failed_to_load = func(_e: LoadAdError) -> void:
		_rewarded = null
		get_tree().create_timer(30.0).timeout.connect(_load_rewarded)
	_rew_loader.load(rewarded_unit, AdRequest.new(), cb)

func _done_interstitial(shown: bool) -> void:
	if _interstitial != null:
		_interstitial.destroy()
		_interstitial = null
	_showing = false
	finished.emit(shown, false)
	_load_interstitial()

func _done_rewarded(shown: bool) -> void:
	var got := _earned
	if _rewarded != null:
		_rewarded.destroy()
		_rewarded = null
	_showing = false
	finished.emit(shown, got)
	_load_rewarded()
