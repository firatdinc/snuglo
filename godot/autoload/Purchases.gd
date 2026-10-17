extends Node
## Uygulama içi satın almalar (Swift RevenueCatManager + StoreManager portu).
## Arka uç sırası: 1) RevenueCat (GodotxRevenueCat singleton, ~/starwatch ile aynı kullanım)
## 2) StoreKit 2 (GodotApplePlugins "StoreKitManager"; addon projede yok → normalde devre dışı)
## 3) YALNIZ MASAÜSTÜ debug build'de anında ücretsiz. Cihazda (iOS/Android) mağaza tekili yoksa
##    satın alma HER ZAMAN başarısız olur (Kikko dersi: yanlış eklenti anahtarı yüzünden mağaza
##    tekili gelmedi ve canlıda herkese bedava verildi). tools/ios_release.sh de arşivden önce
##    RevenueCat'in Xcode projesinde olduğunu denetler.
## Göç: eski Swift sürümünden premium/reklamsız bayrağı geldiyse (Save "legacy_iap_restore")
## ilk açılışta sessizce RC restore çalışır; o bitene kadar RC'nin "hak yok" cevabı yerel hakkı silmez.
## Haklar: "premium" (sınırsız enerji + reklamsız + tüm paket/kozmetikler) ve "ads_removed".
## Tüketilenler: gem paketleri, 10 ipucu, 3 anahtar. Haklar yerelde de önbelleklenir.

signal products_ready
## Sahiplik/hak değişti (premium, reklamsız...).
signal entitlements_changed

const PREMIUM := "com.snuglo.premium"            # tüketilmeyen, $4.99
const REMOVE_ADS := "com.snuglo.removeads"       # tüketilmeyen, $2.99
const HINTS_SMALL := "com.snuglo.hints.small"    # +10 ipucu
const KEYS_SMALL := "com.snuglo.keys.small"      # +3 anahtar
const HINTS_PER_PACK := 10
const KEYS_PER_PACK := 3
## RevenueCat hak kimlikleri + public SDK anahtarı (Swift Secrets; istemcide durması güvenli).
const ENT_PREMIUM := "premium"
const ENT_ADS := "ads_removed"
const RC_SINGLETON := "GodotxRevenueCat"
const RC_PUBLIC_KEY := "appl_erSFinQjoSgmOmLkTtReFfwrKzf"
const RC_OFFERING := "default"
## Gem paketleri (Swift GemPack.catalog).
const GEM_PACKS := [
	{"id": "com.snuglo.gems.tier1", "gems": 100, "price": "$0.99", "best": false},
	{"id": "com.snuglo.gems.tier2", "gems": 550, "price": "$4.99", "best": false},
	{"id": "com.snuglo.gems.tier3", "gems": 1200, "price": "$9.99", "best": false},
	{"id": "com.snuglo.gems.tier4", "gems": 2600, "price": "$19.99", "best": true},
	{"id": "com.snuglo.gems.tier5", "gems": 7000, "price": "$49.99", "best": false},
]
const NON_CONSUMABLE := [PREMIUM, REMOVE_ADS]
const FALLBACK_PRICE := {PREMIUM: "$4.99", REMOVE_ADS: "$2.99", HINTS_SMALL: "$0.99", KEYS_SMALL: "$0.99"}

var _rc: Object = null
var _sk: Object = null
var _sk_products := {}   # StoreKit: id → StoreProduct
var _prices := {}        # id → mağaza fiyat metni
var _waiting := ""
var _restoring := false
var _silent_restore := false   # göç sonrası sessiz restore sürüyor (toast yok, hak düşürme yok)
var _s: Dictionary       # {"owned": [...], "premium": bool, "ads_removed": bool, "delivered_tx": [...]}

func _ready() -> void:
	_load()
	Save.reloaded.connect(_load)
	if Engine.has_singleton(RC_SINGLETON):
		_rc = Engine.get_singleton(RC_SINGLETON)
		_rc.connect("customer_info_changed", _on_rc_customer_info)
		_rc.connect("purchase_result", _on_rc_purchase)
		_rc.connect("products", _on_rc_products)
		_rc.connect("restore_finished", _on_rc_restore)
		_rc.initialize(RC_PUBLIC_KEY, "", OS.is_debug_build())
		_rc.fetch_products(all_ids())
		_legacy_restore()
	elif ClassDB.class_exists("StoreKitManager"):
		_sk = ClassDB.instantiate("StoreKitManager")
		_sk.products_request_completed.connect(_on_sk_products)
		_sk.purchase_completed.connect(_on_sk_purchase)
		_sk.transaction_updated.connect(_sk_deliver)
		_sk.current_entitlements_fetch_completed.connect(_on_sk_entitlements)
		_sk.restore_completed.connect(func(_a, _b): _sk.fetch_current_entitlements())
		_sk.start()
		_sk.request_products(PackedStringArray(all_ids()))
		_sk.fetch_current_entitlements()
	elif _on_device():
		push_error("[Purchases] mağaza eklentisi yok (GodotxRevenueCat) - satın almalar kapalı")

## Native tekil iOS'ta ağaçtan uzun yaşar; çıkışta bağları kopar (starwatch dersi).
func _exit_tree() -> void:
	if _rc == null:
		return
	for pair in [["customer_info_changed", _on_rc_customer_info], ["purchase_result", _on_rc_purchase],
			["products", _on_rc_products], ["restore_finished", _on_rc_restore]]:
		if _rc.is_connected(pair[0], pair[1]):
			_rc.disconnect(pair[0], pair[1])
	_rc = null

func _on_device() -> bool:
	return OS.get_name() == "iOS" or OS.get_name() == "Android"

## Debug anında-ücretsiz yalnız masaüstü debug'da; cihazda asla (release ya da debug).
func _free_grants_allowed() -> bool:
	return OS.is_debug_build() and not _on_device()

## Eski sürümden IAP bayrağı geldiyse RC'den sessizce geri yükle (bir kez).
func _legacy_restore() -> void:
	if _rc == null or not bool(Save.raw().get("legacy_iap_restore", false)):
		return
	Save.raw().erase("legacy_iap_restore")
	Save.mark_dirty()
	_silent_restore = true
	_rc.restore_purchases()

func _load() -> void:
	_s = Save.get_section("purchases")
	var d := {"owned": [], "delivered_tx": [], "premium": false, "ads_removed": false}
	for k in d:
		if not _s.has(k):
			_s[k] = d[k]

static func all_ids() -> Array:
	var ids := [PREMIUM, REMOVE_ADS, HINTS_SMALL, KEYS_SMALL]
	for p in GEM_PACKS:
		ids.append(p.id)
	return ids

func backend() -> String:
	return "revenuecat" if _rc else ("storekit" if _sk else "debug")

func is_store_available() -> bool:
	return _rc != null or _sk != null

# --- Haklar ---

func owns(id: String) -> bool:
	return id in _s.owned

## Premium: sınırsız enerji, reklamsız, tüm paketler + kozmetikler açık.
func is_premium() -> bool:
	return bool(_s.premium) or owns(PREMIUM)

## Reklamsız: reklam kaldır VEYA premium.
func ads_removed() -> bool:
	return bool(_s.ads_removed) or owns(REMOVE_ADS) or is_premium()

func gem_pack(id: String) -> Dictionary:
	for p in GEM_PACKS:
		if p.id == id:
			return p
	return {}

## Yerelleştirilmiş fiyat; mağaza cevap vermediyse yedek.
func get_price(id: String) -> String:
	if _prices.has(id):
		return String(_prices[id])
	var gp := gem_pack(id)
	if not gp.is_empty():
		return gp.price
	return FALLBACK_PRICE.get(id, "")

# --- Satın alma ---

## Sonuç: Events.purchase_completed / purchase_failed.
func buy(id: String) -> void:
	if not id in all_ids():
		Events.purchase_failed.emit(id)
		return
	if id in NON_CONSUMABLE and owns(id):
		Events.purchase_completed.emit(id)
		return
	if _waiting != "":
		Events.purchase_failed.emit(id)   # aynı anda tek satın alma
		return
	if _rc:
		_waiting = id
		_rc.purchase(id)
		return
	var p = _sk_products.get(id)
	if _sk and p:
		_waiting = id
		_sk.purchase(p)
		return
	if _free_grants_allowed():
		print("[Purchases] DEBUG ücretsiz verildi: ", id)
		_grant(id)
	else:
		if _on_device():
			push_error("[Purchases] mağaza yok, satın alma reddedildi: " + id)
		Events.purchase_failed.emit(id)
		Events.toast.emit("toast.purchase.failed", [])

func restore() -> void:
	_restoring = true
	if _rc:
		_rc.restore_purchases()
	elif _sk:
		_sk.restore_purchases()
	else:
		_restoring = false
		Events.toast.emit("toast.restore.done", [])

## Ürünün içeriğini ver (tüketilen: cüzdana; tüketilmeyen: sahiplik + hak).
func _grant(id: String) -> void:
	var gp := gem_pack(id)
	if not gp.is_empty():
		Wallet.add("gem", int(gp.gems), "iap")
	elif id == HINTS_SMALL:
		Wallet.add("hint", HINTS_PER_PACK, "iap")
	elif id == KEYS_SMALL:
		Wallet.add("key", KEYS_PER_PACK, "iap")
	else:
		if not owns(id):
			(_s.owned as Array).append(id)
		if id == PREMIUM:
			_s.premium = true
		if id == REMOVE_ADS:
			_s.ads_removed = true
		entitlements_changed.emit()
	Save.mark_dirty()
	Save.flush()
	Events.purchase_completed.emit(id)

func _set_entitlements(premium: bool, ads: bool) -> void:
	if _silent_restore:
		# Göç restore'u bitmeden yerel (eski sürümden gelen) hakkı düşürme; yalnız ekle.
		premium = premium or bool(_s.premium)
		ads = ads or bool(_s.ads_removed)
	if bool(_s.premium) == premium and bool(_s.ads_removed) == (ads or premium):
		return
	_s.premium = premium
	_s.ads_removed = ads or premium
	if not premium:
		(_s.owned as Array).erase(PREMIUM)
	if not ads:
		(_s.owned as Array).erase(REMOVE_ADS)
	Save.mark_dirty()
	entitlements_changed.emit()

# --- RevenueCat ---

func _on_rc_customer_info(_info: Dictionary) -> void:
	call_deferred("_rc_sync")

func _rc_sync() -> void:
	if _rc == null:
		return
	_set_entitlements(bool(_rc.has_entitlement(ENT_PREMIUM)), bool(_rc.has_entitlement(ENT_ADS)))
	if _restoring and not _silent_restore:
		_restoring = false
		Events.toast.emit("toast.restore.done", [])

func _on_rc_restore(_data: Dictionary) -> void:
	_rc_sync()
	_silent_restore = false

## Tüketilebilirler işlem kimliği başına bir kez (StoreKit yolundaki delivered_tx ile aynı defter);
## kimlik gelmezse yalnız bizim başlattığımız bekleyen satın alma teslim edilir (gecikmiş/yinelenen
## olay ikinci kez vermez).
func _on_rc_purchase(data: Dictionary) -> void:
	var pending := _waiting
	var id := str(data.get("product_id", data.get("id", pending)))
	if id == "":
		id = pending
	_waiting = ""
	if not str(data.get("error", "")).is_empty() or bool(data.get("cancelled", false)) \
			or (data.has("success") and not bool(data.success)):
		Events.purchase_failed.emit(id)
		return
	var tid := ""
	for k in ["transaction_id", "transactionIdentifier", "transaction_identifier", "store_transaction_id"]:
		if str(data.get(k, "")) != "":
			tid = str(data[k])
			break
	if not id in NON_CONSUMABLE:
		if tid != "":
			if tid in _s.delivered_tx:
				return
			(_s.delivered_tx as Array).append(tid)
			Save.mark_dirty()
		elif pending == "":
			return
	_grant(id)
	call_deferred("_rc_sync")

## iOS Array, Android ArrayList döndürür.
func _on_rc_products(data: Dictionary) -> void:
	if not str(data.get("error", "")).is_empty():
		return
	var raw = data.get("products", null)
	var list: Array = []
	if raw is Array:
		list = raw
	elif raw != null and raw.has_method("size"):
		for i in int(raw.call("size")):
			list.append(raw.call("get", i))
	for p in list:
		_prices[str(p["id"])] = _repair_mojibake(str(p["price"]))
	products_ready.emit()

## Eklenti UTF-8 fiyatı Latin-1 okuyabiliyor ("âº49,99" → "₺49,99").
func _repair_mojibake(text: String) -> String:
	var buf := PackedByteArray()
	for i in text.length():
		var c: int = text.unicode_at(i)
		if c > 255:
			return text
		buf.append(c)
	var decoded: String = buf.get_string_from_utf8()
	if decoded.is_empty() or decoded == text or decoded.contains("�"):
		return text
	return decoded

# --- StoreKit (yedek) ---

func _on_sk_products(products: Array, _status: int) -> void:
	for p in products:
		if p:
			_sk_products[str(p.product_id)] = p
			_prices[str(p.product_id)] = str(p.display_price)
	products_ready.emit()

func _on_sk_purchase(t, status: int, _err: String) -> void:
	var id := _waiting
	_waiting = ""
	if status == 0 and t:
		_sk_deliver(t)
	else:
		if status == 5:
			Events.toast.emit("toast.purchase.pending", [])
		Events.purchase_failed.emit(id)

## İşlem kimliği başına bir kez teslim, sonra bitir; iade → hakkı geri al.
func _sk_deliver(t) -> void:
	var tid := str(t.transaction_id)
	var id := str(t.product_id)
	if float(t.revocation_date) > 0.0:
		_set_entitlements(is_premium() and id != PREMIUM, ads_removed() and id != REMOVE_ADS)
		t.finish()
		return
	if not tid in _s.delivered_tx:
		(_s.delivered_tx as Array).append(tid)
		_grant(id)
	t.finish()

func _on_sk_entitlements(list: Array) -> void:
	for t in list:
		var id := str(t.product_id)
		if id in NON_CONSUMABLE and not owns(id) and float(t.revocation_date) <= 0.0:
			_grant(id)
	if _restoring:
		_restoring = false
		Events.toast.emit("toast.restore.done", [])

## Debug/test: hakları temizle.
func debug_clear() -> void:
	_s.owned = []
	_s.premium = false
	_s.ads_removed = false
	Save.mark_dirty()
	entitlements_changed.emit()
