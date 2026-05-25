# Blockers

Bu dosya, agent'ların takıldığı veya ilerideki version'lara bırakılan maddeler içerir.

---

## v1.1 Backlog (Faz J — 2026-05-25)

Aşağıdaki maddeler v1.0.0 scope'u dışında bırakılmış; v1.1'de ele alınacak:

- XCUITest target setup (defer to CI bootstrap)
- Real app icon art (1024×1024 + variants)
- Real audio assets (5 SFX wav + bgm_cozy.mp3)
- Real AdMob SDK integration (replace placeholder)
- Native speaker review of TR/ES translations

---

## Faz E — Persistence + Stats (2026-05-25) ✅ KAPANDI

Tüm görevler tamamlandı. Bir minor not:

| # | Bulgu | Durum |
|---|-------|-------|
| 1 | `ColorsTests.test_blockColor_snapshotForKnownIDs` — pre-existing Faz B palette snapshot failure | ⚠️ Faz F'de fix — Faz E ile ilgisi yok |

## Faz F-H için Not: AVAudio + UNUserNotification Entegrasyon Noktaları

- **AVAudio (Faz F):** `GameViewModel.persistProgress()` solve anında çağrılır → burada `AudioManager.shared.playSolveSound()` hook eklenebilir. `SettingsView` zaten `soundEnabled` / `sfxEnabled` `@AppStorage` değişkenlerini tutmaktadır.
- **UNUserNotification (Faz H):** `SettingsView` `dailyReminderEnabled` + `reminderHour/Minute` `@AppStorage` hazır. `ProgressStore.markDailySolved` her çağrıldığında notification rescheduling tetiklenebilir.
- **Faz I:** ProgressStore test coverage tamam (17/17). Hint usage tracking için `ProgressStore.LevelProgress`'e `hintsUsed: Int` field eklenebilir.

---

## Faz A fix2 — IOS-16 (2026-05-25) ✅ KAPANDI

Reviewer task `pBQzr92rXgbgYn9VSddjy` — tüm bulgular kapatıldı:

| # | Bulgu | Fix | Sonuç |
|---|-------|-----|-------|
| 1 | `PBXResourcesBuildPhase` içinde `xcodeproj` referansı | `project.yml` `*.xcodeproj` exclude + `xcodegen generate` | pbxproj temiz ✅ |
| 2 | `onGeometryChange` iOS 18+ / deployment target 17.0 | `IPHONEOS_DEPLOYMENT_TARGET = 18.0` tüm config | 6 config × 18.0 ✅ |
| 3 | SnapCalculator buffer bug (test regresyonu) | guard `pos.x/y` tabanlı — parça boyutundan bağımsız | 8/8 test ✅ |

**xcodebuild build ✅ — TEST SUCCEEDED (8 test, 0 failure) ✅**

---

## v0.2 — Core UI

### [BLOCKER-01] App icon ve launch screen — ⚠️ → v1.1 (known issue)
- **Durum:** `AppIcon.appiconset` — 1024×1024 lavender placeholder eklendi. `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` ayarlı. App builds and runs; placeholder ships with v1.0.0.
- **Gerçek icon:** v1.1'de final art-2d delivery (Snuglo logosu). Bkz. `RELEASE_NOTES.md` Known Limitations.
- **Launch Screen Background:** `UILaunchScreen.UIColorName` GENERATE_INFOPLIST_FILE=YES ile set edilemiyor. v1.0.0'da kabul edildi; custom Info.plist geçişi v1.1'e ertelendi. Bkz. v1.1 Backlog.

### [BLOCKER-02] Parça renk field'ı engine'de yok
- **Durum:** `Piece` modeli `color` field'ı içermiyor (v0.1 kasıtlı tasarım).
- **Etki:** v0.2'de renk, `level.pieces` dizin tabanlı atanıyor (`colorKeys[index % 6]`).
- **Planlanan:** v0.4 level generator'ında parça renklerini level JSON'a eklemeyi değerlendirin, VEYA UI katmanında index-tabanlı atama yeterli kabul edilirse ilerideki version'larda da devam edilebilir.

---

## Gelecek Version'lar (placeholder)

### [BLOCKER-03] Ses dosyaları — ⚠️ → v1.1 (known issue)
- `click.caf`, `error.caf`, `place.caf`, `snap.caf`, `solve.caf` (5 dosya, `Resources/Sounds/`)
- Faz F'de `.caf` formatına geçildi; placeholder'lar sessiz (44100 Hz PCM, 70 byte). AudioManager no-ops gracefully — v1.0.0 ships sessiz SFX. Gerçek ses varlıkları v1.1'e ertelendi. Bkz. v1.1 Backlog.

### [BLOCKER-04] App Store Connect IAP ürünleri — ⚠️ → v1.1 (known issue)
- Product ID'leri kod tarafında tanımlanmış; ASC'de kullanıcı tarafından oluşturulması gerekiyor. StoreKit sandbox/production'a bağlanmadan önce ASC setup gerekli. v1.1 pre-launch adımı.

### [BLOCKER-05] TelemetryDeck App ID — ⚠️ → v1.1 (known issue)
- Kullanıcının kendi TelemetryDeck hesabını açıp App ID eklemesi gerekecek. v1.0.0'da placeholder UUID ile ship edildi; v1.1'de production App ID swap-in yapılacak.

---

## v1.0-B — Nordic Hearth Theme (Faz B)

### [BLOCKER-06] Dark mode renk token'ları — ✅ FAZ H-2'DE KAPATILDI
- **Durum:** `Colors.swift` rewritten — 25 token, her biri `Color(light:dark:)` adaptive.
- `UIColor { traitCollection }` bridge kullanıldı (no Asset Catalog dependency).
- Block palette dark shift: blockLavender `#7A6D8C`, blockSage `#6F8A6B`, vb.

### [BLOCKER-07] Custom font bundle dosyaları — ⚠️ → v1.1 (known issue)
- **Durum:** Faz B'de sistem-font fallback'ler kullanıldı (SF Rounded / SF Pro / SF Mono).
  Plus Jakarta Sans, Be Vietnam Pro, Space Grotesk bundle'a eklenmedi. Faz H'e ertelendi, Faz H'de de tamamlanamadı.
- **v1.0.0 kararı:** Sistem-font fallback'ler v1.0.0 ile ship edildi. Tasarım görsel olarak yakın. v1.1'de font bundle deliverysı yapılacak.
- **v1.1 aksiyonu:** `.ttf` / `.otf` dosyaları `SnugloApp/Resources/Fonts/` altına ekle, `Info.plist`'e `UIAppFonts` array ekle, `Typography.swift` güncelle.
