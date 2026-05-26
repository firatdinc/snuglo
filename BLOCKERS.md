# Blockers

Bu dosya, agent'ların takıldığı veya ilerideki version'lara bırakılan maddeler içerir.

---

## v1.1 — Bug Fix + Stitch Design Refactor (2026-05-25) ✅ KAPANDI

### Bug fixes resolved in v1.1:
| # | Bug | Severity | Resolution |
|---|-----|----------|------------|
| 1 | AppRouter.selectTab() unwinds stack | BLOCKER | ✅ selectTab() no longer calls popToRoot() |
| 2 | GameView viewModel re-init flash | IMPORTANT | ✅ init(levelId:) initializes viewModel upfront |
| 3 | MainMenuView hardcoded progress | IMPORTANT | ✅ reads ProgressStore.shared.totalLevelsCompleted() |
| 4 | SplashView task leak | IMPORTANT | ✅ splashTask stored + cancelled onDisappear |
| 5 | PauseSheet swipe-dismiss timer leak | IMPORTANT | ✅ onDismiss: always calls startTimer() |
| 6 | SettingsView notif denial silent | IMPORTANT | ✅ checks UNAuthorizationStatus after request |
| 7 | BLOCKER-07 custom fonts not registered | IMPORTANT | ✅ Resources/Fonts/ + UIAppFonts in Info.plist |
| 8 | BLOCKER-01 UILaunchScreen.UIColorName | IMPORTANT | ✅ custom Info.plist replaces GENERATE_INFOPLIST |
| 9 | NotificationSchedulerTests compile fail | IMPORTANT | ✅ stub redirects to NotificationServiceTests |
| 10 | HUD timer hardcoded system font | NITPICK | ✅ AppTypography.numericLabel (Space Grotesk) |
| 11 | Info.plist duplicate copy build error | BUILD | ✅ excluded from sources wildcard in project.yml |

### Design refactor resolved in v1.1:
- ✅ Colors.swift: gameBoardBackground, gridLine, blushAccent, divider, softCocoa tokens
- ✅ Typography.swift: 3-font variable-axis (Plus Jakarta Sans / Be Vietnam Pro / Space Grotesk)
- ✅ Reusable components: PrimaryButton, SecondaryButton, CardSurface, RowDivider
- ✅ GridView, LevelCompleteSheet, PauseSheet, Stats, PackDetail, Settings: token alignment
- ✅ StitchTokenTests: 22 new tests for v1.1 tokens

### v1.2 Backlog (items deferred from v1.1 original backlog):
- XCUITest target setup (defer to CI bootstrap)
- Real app icon art (1024×1024 + variants)
- Real audio assets (5 SFX wav + bgm_cozy.mp3)
- Real AdMob SDK integration (replace placeholder)
- Native speaker review of TR/ES translations

### v1.2 Backlog (new — from whiteboard analysis):
- Game Center Leaderboard screen
- Profile tab
- Separate Tutorial screen / flow
- Fail state (distinct popup from LevelCompleteSheet)
- Daily Puzzle as separate nav entry point
- PlusJakartaSans-SemiBold.ttf / SpaceGrotesk-Medium.ttf explicit files (currently using variable axis — works but non-standard for App Store font audits)

### v1.2 Backlog (new — from v1.1.0 IOS-54 audit):
- Delete `SnugloApp/Features/Game/PauseOverlayView.swift` (dead code — not referenced anywhere; superseded by `PauseSheet`). Left in place for v1.1.0 to keep this release purely additive.
- ~~Tab bar labels render as raw localization keys~~ — ✅ fixed in v1.1.1
- `xcuserdata/` + `.swiftpm/xcode/xcuserdata/` accidentally committed in IOS-54 wrap-up commit — add to `.gitignore` and `git rm --cached` in v1.2.

### v1.2 Backlog (new — from v1.1.1 hotfix):
- Tab label "İSTATİSTİK" still wraps in Turkish locale (renders as two lines "İSTATİSTİ\nK"). Either truncate / use shorter label ("İSTATS"?) or reduce font size at smallest tab widths. Cosmetic; doesn't block release.
- Continue card refresh when returning from GameView: currently `continuePack/continueLevel` are computed at MainMenu render time, but if the user completes a level and the view is cached, the card may not refresh. Add `.id(ProgressStore.shared.totalLevelsCompleted())` or observe ProgressStore to invalidate.

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
- `pickup.wav`, `tock.wav`, `thud.wav`, `complete.wav`, `shimmer.wav`, `click.wav`
- `SoundService.swift` placeholder'larla şimdilik sessiz çalışacak.

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
