# Snuglo — StoreKit Configuration Setup

## Dosya: `Snuglo.storekit`

Bu dosya Xcode'un **StoreKit Configuration File** formatındadır (JSON, Xcode 13+).
Sandbox / Simulator ortamında gerçek App Store bağlantısı gerekmeden IAP testi sağlar.

---

## Xcode'da Aktifleştirme

### 1. Dosyayı Xcode Project'e Ekle

Eğer `Snuglo.storekit` Xcode project navigator'ında görünmüyorsa:

1. Xcode → File → Add Files to "SnugloApp"
2. `SnugloApp/Resources/Snuglo.storekit` seç
3. Target membership: **SnugloApp** ✓

### 2. Scheme'e Bağla

1. Xcode menüsü: **Product → Scheme → Edit Scheme…**
2. **Run** sekmesi → **Options** alt sekmesi
3. **StoreKit Configuration**: açılır listeden `Snuglo.storekit` seç
4. **Close**

> ⚠️ Bu ayar `.xcscheme` dosyasına kaydedilir. Takım üyeleri kendi Xcode'larında da aynı adımı yapmalı.

### 3. Simulator'da Test

```
Scheme: SnugloApp (iPhone Simulator)
StoreKit Config: Snuglo.storekit bağlı
```

- Uygulama çalıştığında `StoreManager.loadProducts()` çağrısı gerçek App Store yerine
  bu config'den product bilgisi çeker.
- Satın alma diyaloğunda "Confirm" → işlem anında tamamlanır, kart bilgisi istenmez.
- "Clear Transactions": Xcode menüsü → Debug → StoreKit → Clear Transactions

### 4. Sandbox Testing (gerçek cihaz, Developer hesabı)

1. Apple Developer → Certificates, Identifiers → App ID: `com.felabs.snuglo`
2. App Store Connect → My Apps → Snuglo → In-App Purchases → aşağıdaki 5 SKU'yu oluştur
3. Cihazda Settings → App Store → Sandbox Account ile oturum aç

---

## 5 SKU Listesi

| Product ID | Tür | Fiyat | Açıklama |
|---|---|---|---|
| `com.snuglo.pack.spice_route` | Non-Consumable | $2.99 | Spice Route Pack (6×6, 60 level) |
| `com.snuglo.pack.mambo_nights` | Non-Consumable | $3.99 | Mambo Nights Pack (7×7, 60 level) |
| `com.snuglo.pack.woodland_retreat` | Non-Consumable | $4.99 | Woodland Retreat Pack (8×8, 60 level) |
| `com.snuglo.removeads` | Non-Consumable | $4.99 | Reklamları kalıcı kaldır |
| `com.snuglo.hints.small` | Consumable | $0.99 | +10 hint ekler |

---

## Faz G-2 Köprüsü (AdMob)

`StoreManager.shared.adsRemoved` — `Bool` property.

Faz G-2'de AdMob entegrasyonunda:
```swift
if !StoreManager.shared.adsRemoved {
    // Banner / Interstitial göster
}
```

---

## Notlar

- `cozy-beginnings` pack'i **ücretsiz** — SKU yok, her zaman açık.
- `hintsSmall` consumable: satın alım tamamlandığında `ProgressStore.shared.addHints(10)` çağrılır.
  Hint count `ProgressStore` içinde `hintCount: Int` olarak tutulur ve UserDefaults'ta persist edilir.
- Non-consumable'lar ayrıca `UserDefaults` key `snuglo.purchased.v1` altında cache'lenir
  (App Store erişimsiz durumlarda hızlı okuma için).
