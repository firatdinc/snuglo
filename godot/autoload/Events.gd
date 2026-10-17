extends Node
## Global olay veri yolu: sistemler yayınlar, UI dinler (yoklama yok).

## currency: "coin" | "gem" | "hint"; amount: yeni bakiye; delta: değişim (+/-).
signal wallet_changed(currency: String, amount: int, delta: int)
signal level_completed(level_id: String, stars: int, seconds: float)
signal achievement_unlocked(id: String)
signal xp_level_up(level: int)
signal quest_completed(id: int)
signal daily_solved(index: int)
signal streak_changed
signal settings_changed(key: String)
signal purchase_completed(product_id: String)
## Satın alma başarısız / iptal (UI spinner'ı kapatsın).
signal purchase_failed(product_id: String)
## Kozmetik seçimi ya da kilidi değişti.
signal cosmetics_changed
## Kısa bilgi balonu: text_key i18n anahtarı, args tr(text_key) % args için.
signal toast(text_key: String, args: Array)
