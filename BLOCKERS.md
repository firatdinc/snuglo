# Blockers

Bu dosya, agent'ların takıldığı veya ilerideki version'lara bırakılan maddeler içerir.

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

### [BLOCKER-01] App icon ve launch screen — ⚠️ PARTIAL (Faz H-2)
- **Durum:** `AppIcon.appiconset` — 1024×1024 lavender placeholder eklendi. `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` ayarlı.
- **Kalan:** Faz J — gerçek art-2d icon (Snuglo logosu). Faz J'de `AppIcon-1024.png` replace edilecek.
- **Launch Screen Background:** `LaunchBackground.colorset` hazır ama `GENERATE_INFOPLIST_FILE=YES` ile `UILaunchScreen.UIColorName` sub-key set edilemiyor.
  **FAZ J AKSİYONU:** `project.yml`'den `GENERATE_INFOPLIST_FILE: YES` kaldır, custom `Info.plist` oluştur, `UILaunchScreen > UIColorName: LaunchBackground` ekle.

### [BLOCKER-02] Parça renk field'ı engine'de yok
- **Durum:** `Piece` modeli `color` field'ı içermiyor (v0.1 kasıtlı tasarım).
- **Etki:** v0.2'de renk, `level.pieces` dizin tabanlı atanıyor (`colorKeys[index % 6]`).
- **Planlanan:** v0.4 level generator'ında parça renklerini level JSON'a eklemeyi değerlendirin, VEYA UI katmanında index-tabanlı atama yeterli kabul edilirse ilerideki version'larda da devam edilebilir.

---

## Gelecek Version'lar (placeholder)

### [BLOCKER-03] Ses dosyaları — v0.5'te gerekli
- `click.caf`, `error.caf`, `place.caf`, `snap.caf`, `solve.caf` (5 dosya, `Resources/Sounds/`)
- Faz F'de `.caf` formatına geçildi; placeholder'lar sessiz (44100 Hz PCM, 70 byte). Gerçek ses Faz J'de.

### [BLOCKER-04] App Store Connect IAP ürünleri — v0.7'de gerekli
- Product ID'leri kod tarafında tanımlanacak; ASC'de kullanıcı tarafından oluşturulmalı.

### [BLOCKER-05] TelemetryDeck App ID — v0.8'de gerekli
- Kullanıcının kendi TelemetryDeck hesabını açıp App ID eklemesi gerekecek.

---

## v1.0-B — Nordic Hearth Theme (Faz B)

### [BLOCKER-06] Dark mode renk token'ları — ✅ FAZ H-2'DE KAPATILDI
- **Durum:** `Colors.swift` rewritten — 25 token, her biri `Color(light:dark:)` adaptive.
- `UIColor { traitCollection }` bridge kullanıldı (no Asset Catalog dependency).
- Block palette dark shift: blockLavender `#7A6D8C`, blockSage `#6F8A6B`, vb.

### [BLOCKER-07] Custom font bundle dosyaları — Faz H'de tamamlanacak
- **Durum:** Faz B'de sistem-font fallback'ler kullanıldı (SF Rounded / SF Pro / SF Mono).
  Plus Jakarta Sans, Be Vietnam Pro, Space Grotesk bundle'a eklenmedi.
- **Etki:** Tasarım görsel olarak yakın ama birebir eşleşmiyor.
- **Planlanan:** Faz H — `.ttf` / `.otf` dosyaları `SnugloApp/Resources/Fonts/` altına eklenecek,
  `Info.plist`'e `UIAppFonts` array kaydedilecek, `Typography.swift` güncellenecek.
- **Not:** `Typography.swift` başında sistem-font fallback notu ve TODOlar zaten mevcut.
