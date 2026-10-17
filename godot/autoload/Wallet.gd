extends Node
## Cüzdan (Swift WalletStore + ProgressStore.hintCount + ChestStore.keys tek yerde):
## coin (yumuşak), gem (sert), ticket (Kule girişi; yalnız gem ile alınır), cup (gösterimlik
## kupa, başarımlardan), hint (ipucu envanteri), key (sandık açma anahtarı).
## Her değişim Events.wallet_changed yayar.

const CURRENCIES := ["coin", "gem", "ticket", "cup", "hint", "key"]
const SPENDABLE := ["coin", "gem", "ticket", "hint", "key"]
## Swift başlangıcı: hepsi 0.
const START := {"coin": 0, "gem": 0, "ticket": 0, "cup": 0, "hint": 0, "key": 0}
## Oyun içi güçlendirme gem fiyatları (Swift PowerUp.gemCost). "shuffle" UI'da "Yeniden başlat".
const POWERUP_COST := {"hint": 30, "peek": 20, "shuffle": 15}
## Takas: 1 gem = 100 coin, 1 ticket = 50 gem (Swift CurrencyRate).
const COIN_PER_GEM := 100
const GEM_PER_TICKET := 50
## Günlük fırsat (Swift DailyDeal). "ad" türü ödüllü reklam ister (Ads).
const DEALS := [
	{"id": "deal_gems_ad", "title": "shop.deal.gems.title", "message": "shop.deal.gems.message",
		"kind": "ad", "earn": "gem", "amount": 20},
	{"id": "deal_coins_ad", "title": "shop.deal.coins.title", "message": "shop.deal.coins.message",
		"kind": "ad", "earn": "coin", "amount": 150},
	{"id": "deal_gems_coins", "title": "shop.deal.exchange.title", "message": "shop.deal.exchange.message",
		"kind": "spend", "from": "coin", "cost": 300, "earn": "gem", "amount": 5},
	{"id": "deal_ticket_gems", "title": "shop.deal.ticket.gems.title", "message": "shop.deal.ticket.gems.message",
		"kind": "spend", "from": "gem", "cost": 80, "earn": "ticket", "amount": 2},
]
## Reklamla kazanılan para paketleri (Swift CurrencyPack; ödüllü reklam → grant).
const AD_PACKS := [
	{"id": "cp_coins_sm", "title": "shop.pack.coins.sm", "earn": "coin", "amount": 50},
	{"id": "cp_coins_md", "title": "shop.pack.coins.md", "earn": "coin", "amount": 150},
	{"id": "cp_gems_sm", "title": "shop.pack.gems.sm", "earn": "gem", "amount": 10},
]

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(func() -> void:
		_load()
		for c in CURRENCIES:
			Events.wallet_changed.emit(c, balance(c), 0))

func _load() -> void:
	_s = Save.get_section("wallet")
	for c in CURRENCIES:
		_s[c] = int(_s.get(c, START[c]))

func balance(currency: String) -> int:
	return int(_s.get(currency, 0))

var coins: int:
	get: return balance("coin")
var gems: int:
	get: return balance("gem")
var hints: int:
	get: return balance("hint")
var tickets: int:
	get: return balance("ticket")
var cups: int:
	get: return balance("cup")
var keys: int:
	get: return balance("key")

func can_afford(currency: String, amount: int) -> bool:
	return amount > 0 and currency in SPENDABLE and balance(currency) >= amount

## Ekle (reason: log/analitik için kısa etiket, örn. "level", "chest").
func add(currency: String, amount: int, reason := "") -> void:
	if amount <= 0 or not currency in CURRENCIES:
		return
	_s[currency] = balance(currency) + amount
	Save.mark_dirty()
	if OS.is_debug_build() and reason != "":
		print_verbose("[Wallet] +%d %s (%s)" % [amount, currency, reason])
	Events.wallet_changed.emit(currency, balance(currency), amount)

## Harca; yetmiyorsa hiçbir şey değişmez ve false döner.
func spend(currency: String, amount: int, reason := "") -> bool:
	if not can_afford(currency, amount):
		return false
	_s[currency] = balance(currency) - amount
	Save.mark_dirty()
	if OS.is_debug_build() and reason != "":
		print_verbose("[Wallet] -%d %s (%s)" % [amount, currency, reason])
	Events.wallet_changed.emit(currency, balance(currency), -amount)
	return true

## Ödül sözlüğünü uygular: {"coin": 50, "gem": 1, "hint": 1}.
func grant(reward: Dictionary, reason := "") -> void:
	for c in reward:
		add(String(c), int(reward[c]), reason)

## Güçlendirme öde. hint: önce envanter, sonra gem. peek/shuffle: gem.
## Dönüş: "free" (envanterden) | "gem" | "" (yetersiz). Ücretsiz geri alma
## (oturum başına 1, zen/endless'ta sınırsız) oyun tarafında, bu çağrıdan önce.
func pay_powerup(kind: String) -> String:
	if kind == "hint" and spend("hint", 1, "powerup"):
		return "free"
	if spend("gem", int(POWERUP_COST.get(kind, 0)), "powerup:" + kind):
		return "gem"
	return ""

## Uygulanamayan güçlendirmenin bedelini iade et (pay_powerup'ın dönüşüyle).
func refund_powerup(kind: String, paid: String) -> void:
	if paid == "free":
		add("hint", 1, "refund")
	elif paid == "gem":
		add("gem", int(POWERUP_COST.get(kind, 0)), "refund")

## Takas (amount hedef birimde): coin→gem (100:1), gem→ticket (50:1).
func exchange(from: String, to: String, amount: int) -> bool:
	var rate := 0
	if from == "coin" and to == "gem":
		rate = COIN_PER_GEM
	elif from == "gem" and to == "ticket":
		rate = GEM_PER_TICKET
	if amount <= 0 or rate == 0 or not spend(from, amount * rate, "exchange"):
		return false
	add(to, amount, "exchange")
	return true

func exchange_coins_to_gems(gem_amount: int) -> bool:
	return exchange("coin", "gem", gem_amount)

## Bugünün fırsatı (yerel tarih; Swift: |y*366+m*31+d| % n).
func daily_deal() -> Dictionary:
	var d := Progress.local_date()
	return DEALS[absi(d.year * 366 + d.month * 31 + d.day) % DEALS.size()]

## Bugünün fırsatı alındı mı (günde bir kez; saat geri alınınca da kapalı).
func deal_claimed() -> bool:
	return String(_s.get("deal_day", "")) >= Progress.local_key() or Progress.clock_rewound()

func mark_deal_claimed() -> void:
	_s.deal_day = Progress.local_key()
	Save.mark_dirty()

## "spend" türü fırsatı uygula (reklam türü için UI reklam izletip claim_ad_deal() çağırır).
func redeem_deal(deal: Dictionary) -> bool:
	if deal.get("kind") != "spend" or deal_claimed():
		return false
	if not spend(String(deal.from), int(deal.cost), "deal"):
		return false
	add(String(deal.earn), int(deal.amount), "deal")
	mark_deal_claimed()
	return true

## Reklam türü fırsatın ödülü (reklam tamamlandıktan sonra). Bugün alındıysa false.
func claim_ad_deal(deal: Dictionary) -> bool:
	if deal.get("kind") != "ad" or deal_claimed():
		return false
	add(String(deal.earn), int(deal.amount), "deal")
	mark_deal_claimed()
	return true

## Debug/test.
func debug_set(currency: String, amount: int) -> void:
	var delta := amount - balance(currency)
	_s[currency] = maxi(0, amount)
	Save.mark_dirty()
	Events.wallet_changed.emit(currency, balance(currency), delta)
