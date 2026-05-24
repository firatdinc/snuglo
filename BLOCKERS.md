# Blockers

Bu dosya, agent'ların takıldığı veya ilerideki version'lara bırakılan maddeler içerir.

---

## Faz A fix2 — IOS-16 (2026-05-25) ✅ KAPANDI

Reviewer task `pBQzr92rXgbgYn9VSddjy` bulgularının tamamı kapatıldı:

| # | Bulgu | Fix | Sonuç |
|---|-------|-----|-------|
| 1 | `PBXResourcesBuildPhase` içinde `xcodeproj` referansı | `project.yml` `*.xcodeproj` exclude + `xcodegen generate` | pbxproj'da `PBXResourcesBuildPhase` yok ✅ |
| 2 | `onGeometryChange` iOS 18+ API, deployment target 17.0 | `IPHONEOS_DEPLOYMENT_TARGET = 18.0` tüm config'lerde | pbxproj 6 config × 18.0 ✅ |
| 3 | SnapCalculator API/test uyumsuzluğu (regresyon) | `enum`→`struct`, `snap(fingerAt:piece:)` instance API, `calculateSnap` wrapper | 13/13 test ✅ |
| 4 | `Typography` `.textCase` returns `some View` (iOS 26) | Text helpers `some View` döndürecek şekilde güncellendi | build temiz ✅ |

**xcodebuild build ✅ — TEST SUCCEEDED (13 test, 0 failure) ✅**

---

## Faz A fix — IOS-11

- Faz A fix — orphan GameViewModelTests removed: `SnugloAppTests/GameViewModelTests.swift` (root-level, eski `Snuglo` modül adı + eski API) git rm ile silindi; klasör de kaldırıldı.
- SnapCalculator.swift ve SnapCalculatorTests.swift (9 test) main'de mevcut; review raporundaki "dosya yok" bulgusunun yanlış olduğu doğrulandı.

---

## v0.2 — Core UI

### [BLOCKER-01] App icon ve launch image placeholder
- **Durum:** Eksik — xcodegen `INFOPLIST_KEY_UILaunchScreen_Generation: YES` ile boş launch screen oluşturuldu (beyaz).
- **Etki:** App Store submission için 1024×1024 app icon gereklidir; v1.0 öncesi tamamlanmalı.
- **Planlanan:** v1.0 — `Resources/AppIcon.appiconset/` SwiftUI vektör icon + export script.
- **Aksiyon (kullanıcı):** v1.0 branch'ine kadar beklenebilir; erken test için asset katalog manuel oluşturulabilir.

### [BLOCKER-02] Parça renk field'ı engine'de yok
- **Durum:** `Piece` modeli `color` field'ı içermiyor (v0.1 kasıtlı tasarım).
- **Etki:** v0.2'de renk, `level.pieces` dizin tabanlı atanıyor (`colorKeys[index % 6]`).
- **Planlanan:** v0.4 level generator'ında parça renklerini level JSON'a eklemeyi değerlendirin, VEYA UI katmanında index-tabanlı atama yeterli kabul edilirse ilerideki version'larda da devam edilebilir.

---

## Gelecek Version'lar (placeholder)

### [BLOCKER-03] Ses dosyaları — v0.5'te gerekli
- `pickup.wav`, `tock.wav`, `thud.wav`, `complete.wav`, `shimmer.wav`, `click.wav`
- `SoundService.swift` placeholder'larla şimdilik sessiz çalışacak.

### [BLOCKER-04] App Store Connect IAP ürünleri — v0.7'de gerekli
- Product ID'leri kod tarafında tanımlanacak; ASC'de kullanıcı tarafından oluşturulmalı.

### [BLOCKER-05] TelemetryDeck App ID — v0.8'de gerekli
- Kullanıcının kendi TelemetryDeck hesabını açıp App ID eklemesi gerekecek.

---

## Faz A→J Plan (v1.0 yol haritası)

- **Faz A — Stabilize:** build+test green, drag-drop offset doğrulama, doc sync
- **Faz B — Nordic Hearth Tema:** Colors/Typography/Spacing yenile, BlockView sayısal etiket, dark palette
- **Faz C — Navigation iskeleti:** RootView tab bar, 11 ekran (Splash→Settings), AppRouter
- **Faz D — Content (240 level):** LevelGenerator, 4 pack × 60 = 240 JSON, DailyPuzzleSeeder
- **Faz E — Persistence & Stats:** StatsStore (UserDefaults+JSON), MigrationV1, StatsView (Charts)
- **Faz F — Ses, Haptik, Bildirim:** SoundService (AVAudioPlayer), HapticService, NotificationService
- **Faz G — Monetization:** StoreKit 2, 5 SKU, ShopView, receipt validation, Google Mobile Ads
- **Faz H — Accessibility, Lokalizasyon, Polish:** VoiceOver, Dynamic Type, TR/EN/ES, app icon, dark mode
- **Faz I — Quality Gate:** XCUITest happy path, SwiftLint, manual checklist
- **Faz J — Release artifacts:** RELEASE_NOTES, README, CHANGELOG, store listing copy, git tag v1.0.0

### Discarded tasks (tool/network error — no code impact)

- `feature/DEV-3-v0-2-manuel-code-review-reviewer-proxy`: interrupted, tool/network error — code was already correct per DEV-4 fix commit.
- `feature/DEV-5-execution-plan-oku-v0-2-state-do-rula`: completed, absorbed into main via merge commit `3ec7527`.
- `feature/DEV-6-v1-0-state-snapshot-brief-absorption`: completed, absorbed into main via merge commit `3ec7527`.
- `SnugloAppTests/GameViewModelTests.swift` (root-level stale file): references obsolete `Snuglo` module name and old `GameViewModel()` API — NOT in any build target, harmless dead code. Will be cleaned up in Faz I quality gate.

---

## v1.0-B — Nordic Hearth Theme (Faz B)

### [BLOCKER-06] Dark mode renk token'ları — Faz H'de tamamlanacak
- **Durum:** Faz B'de yalnızca light theme tanımlandı. `AppColors` içinde dark variant yok.
- **Etki:** Dark Mode sistemi açık olduğunda uygulama light renklerle kalır (görsel uyumsuzluk).
- **Planlanan:** Faz H — `Colors.swift`'e `Color(light:, dark:)` çiftleri eklenecek VEYA
  Asset Catalog renk kümesi kullanılacak. Her token için dark hex değeri INDEX.md dark theming
  bölümünde tanımlanmalı (henüz yok).
- **Geçici çözüm:** Uygulama `light` appearance'ı zorla tutabilir
  (`UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .light` — Faz H'e kadar).

### [BLOCKER-07] Custom font bundle dosyaları — Faz H'de tamamlanacak
- **Durum:** Faz B'de sistem-font fallback'ler kullanıldı (SF Rounded / SF Pro / SF Mono).
  Plus Jakarta Sans, Be Vietnam Pro, Space Grotesk bundle'a eklenmedi.
- **Etki:** Tasarım görsel olarak yakın ama birebir eşleşmiyor.
- **Planlanan:** Faz H — `.ttf` / `.otf` dosyaları `SnugloApp/Resources/Fonts/` altına eklenecek,
  `Info.plist`'e `UIAppFonts` array kaydedilecek, `Typography.swift` güncellenecek.
- **Not:** `Typography.swift` başında sistem-font fallback notu ve TODOlar zaten mevcut.
