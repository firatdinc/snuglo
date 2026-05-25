# STATE_SNAPSHOT_v1.0 — Snuglo Ground Truth

> **Tarih:** 2026-05-25  
> **Branch:** feature/DEV-12-v1-0-ground-truth-state-snapshot  
> **HEAD:** 60db363 (Faz I-1 SwiftLint 0 warning)  
> **Doküman amacı:** v1.0 öncesi gerçek durum — tamamlanan fazlar, kod yapısı, test sayıları, açık blocker'lar, Faz J için kalan işler.

---

## 1. Build / Test Status

| Komut | Sonuç | Not |
|-------|-------|-----|
| `swift build` | ✅ 0 error, 0 warning | ~1.4 s (clean build) |
| `swift test` (SnugloEngine) | ✅ 7 test dosyası, tüm testler geçti | DailyPuzzle, LevelGenerator, LevelLoader, PieceCellCount, SeededRandom, SolutionCheckerEdgeCase, SolutionCheckerSanity |
| `xcodebuild test -scheme SnugloApp` | ✅ **66 test passed, 0 failed** | SnugloAppTests (12 dosya) + SnugloEngineTests (7 dosya) |
| `swiftlint lint --strict` | ✅ **0 violation, 0 serious** | exit 0 — Faz I-1 sonrası |

**Deployment Target:** iOS 18.0  
**Swift Version:** 5.9  
**Marketing Version:** 1.0.0  
**Bundle ID:** com.felabs.snuglo

---

## 2. Tamamlanan Fazlar

| Faz | Başlık | Merge SHA | Durum |
|-----|--------|-----------|-------|
| A | Build stabilize — SnapCalculator, iOS 18 deployment target, PBX temizlik | IOS-16 fix | ✅ |
| B | Nordic Hearth tema — Colors (25 token), Typography, Spacing, AppColors | IOS-12 | ✅ |
| C | 11 ekran NavigationStack — Splash, Onboarding, MainMenu, LevelsList, PackDetail, Game, LevelComplete, Pause, Stats, Shop, Settings | IOS-19, IOS-23 | ✅ |
| D | 240 level — LevelGenerator (procedural), 4 pack × 60 level, DailyPuzzle, PackProvider | IOS-24, IOS-27, IOS-28 | ✅ |
| E | Persistence + Stats — ProgressStore (UserDefaults), StatsView gerçek veri, 17 test | `04ac39e` | ✅ |
| F | Audio + Haptics — AudioManager, HapticsManager, NotificationScheduler, GameView hook'ları, 11 test | `9ae64c4` | ✅ |
| G-1 | StoreKit 2 IAP — StoreManager 5 SKU, ShopView, PackProvider lock, hintCount, 13 test | `b42c0c4` | ✅ |
| G-2 | Ads Placeholder — AdsManager frequency cap, ATT consent, 12 test | `ece1059` | ✅ |
| H-1 | Localization TR/EN/ES — 112 key, 3 dil + InfoPlist.strings | — | ✅ |
| H-2 | Accessibility + Dark Mode + Launch — 25 token adaptive, VoiceOver, Dynamic Type, Reduce Motion, LaunchScreen | — | ✅ |
| I-1 | SwiftLint — 117 → 0 violation, `.swiftlint.yml` config, 3 manuel fix | `41dd12d` | ✅ |

**Toplam tamamlanan faz:** 11 (A → I-1)

---

## 3. Kod Yapısı

### Sources/SnugloEngine (Swift Package)

```
Sources/SnugloEngine/
  Engine/
    DailyPuzzle.swift         — günlük bulmaca seçimi (seed tabanlı)
    LevelGenerator.swift      — recursive rect bölme, procedural üretim
    LevelLoader.swift         — pack manifest + JSON yükleme
    SeededRandom.swift        — tekrarlanabilir RNG
    SolutionChecker.swift     — tek-çözüm doğrulama
  Models/
    Coord.swift
    Level.swift
    Piece.swift
    Placement.swift
    PlacementResult.swift
```

### SnugloApp (Xcode App Target)

```
SnugloApp/
  App/
    SnugloApp.swift           — @main, ATT request, NotificationScheduler init
    AppRouter.swift           — NavigationStack enum-based routing
    RootView.swift            — EnvironmentObject injection hub
  Features/                  — 11 ekran
    Splash/                  SplashView
    Onboarding/              OnboardingView
    MainMenu/                MainMenuView
    LevelsList/              LevelsListView
    PackDetail/              PackDetailView
    Game/                    GameView, GridView, BlockView, GameViewModel
    LevelComplete/           LevelCompleteSheet
    Pause/                   PauseSheet, PauseOverlayView
    Stats/                   StatsView
    Shop/                    ShopView
    Settings/                SettingsView
  Core/
    Theme/                   Colors.swift (25 token, light/dark), Typography, Spacing, AppColors
    Audio/                   AudioManager
    Haptics/                 HapticsManager
    Notifications/           NotificationScheduler
    Persistence/             ProgressStore (UserDefaults)
    Store/                   StoreManager (StoreKit 2, 5 SKU)
    Ads/                     AdsManager (frequency cap, ATT)
    Services/                SoundService, HapticService
    Components/              BottomTabBar
  Resources/
    Levels/                  pack_1/ … pack_4/ — 4 × 60 = 240 level JSON
    Localization/            en.lproj, tr.lproj, es.lproj (112 key × 3 dil)
    Assets.xcassets/         AppIcon (placeholder), AccentColor, LaunchBackground
    Audio/                   .wav placeholder'lar (sessiz — BLOCKER-03)
```

**Ekran sayısı:** 11  
**Level sayısı:** 240 (4 pack × 60 — Cozy Beginnings 5×5 / Spice Route 6×6 / Mambo Nights 7×7 / Woodland Retreat 8×8)  
**Dil sayısı:** 3 (EN/TR/ES)  
**IAP SKU:** 5 (3 pack unlock + 2 hint bundle)

---

## 4. Test Coverage

| Hedef | Test Dosyası | Kapsam |
|-------|-------------|--------|
| SnugloEngine | `DailyPuzzleTests` | DailyPuzzle seed determinizm |
| SnugloEngine | `LevelGeneratorTests` | Generator output validity |
| SnugloEngine | `LevelLoaderTests` | JSON parse + pack yükleme |
| SnugloEngine | `PieceCellCountTests` | Piece alan hesabı |
| SnugloEngine | `SeededRandomTests` | RNG tekrarlanabilirlik |
| SnugloEngine | `SolutionCheckerEdgeCaseTests` | Edge case: boş, tek parça, çakışma |
| SnugloEngine | `SolutionCheckerSanityTests` | Geçerli/geçersiz çözüm ayrımı |
| SnugloApp | `AdsManagerTests` | Frequency cap, ATT state (12 test) |
| SnugloApp | `AudioManagerTests` | BGM/SFX toggle, enabled state |
| SnugloApp | `BlockColorTests` | Renk atama consistency |
| SnugloApp | `ColorsTests` | Token snapshot (block palette) |
| SnugloApp | `GameViewModelTests` | ViewModel state transitions |
| SnugloApp | `HapticServiceTests` | Haptic trigger no-crash |
| SnugloApp | `HapticsManagerTests` | Enabled/disabled path |
| SnugloApp | `NotificationServiceTests` | Schedule/cancel round-trip |
| SnugloApp | `ProgressStoreTests` | Persistence round-trip, 17 test |
| SnugloApp | `SnapCalculatorTests` | Grid snap hesabı (8 test) |
| SnugloApp | `SoundServiceTests` | Sound play/stop no-crash |
| SnugloApp | `StoreManagerTests` | SKU listesi, lock state (13 test) |

**Toplam (Faz I-1 sonrası):** **66 test passed, 0 failed**

---

## 5. Açık BLOCKER'lar

> Referans: `BLOCKERS.md`

| ID | Açıklama | Kalan Faz |
|----|----------|-----------|
| BLOCKER-01 | **AppIcon:** 1024×1024 placeholder var; gerçek Snuglo logosu yok. `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` ayarlı. | Faz J |
| BLOCKER-01b | **LaunchScreen UIColorName:** `GENERATE_INFOPLIST_FILE=YES` ile `UILaunchScreen.UIColorName` sub-key set edilemiyor. Custom `Info.plist`'e geçiş gerekli. | Faz J |
| BLOCKER-02 | **Piece color:** `Piece` modeli `color` field'ı içermiyor; UI index-tabanlı renk atıyor. Level JSON'a ekleme Faz J kararı. | Faz J / sonrası |
| BLOCKER-03 | **Ses dosyaları:** `pickup.wav, tock.wav, thud.wav, complete.wav, shimmer.wav, click.wav` placeholder — sessiz çalışıyor. | Faz J |
| BLOCKER-04 | **ASC IAP ürünleri:** Product ID'ler kodda tanımlı; App Store Connect'te manuel oluşturulmalı. | Manuel |
| BLOCKER-05 | **TelemetryDeck App ID:** Kullanıcının kendi hesabından alması gerekiyor. | Manuel |
| BLOCKER-07 | **Custom fontlar:** Plus Jakarta Sans / Be Vietnam Pro / Space Grotesk bundle'a eklenmedi; sistem fontu fallback kullanılıyor. | Faz J |

---

## 6. Faz J — Release Prep İçin Kalan İşler

> Referans: `EXECUTION_PLAN.md` → "v1.0 — Launch Prep"

| # | İş | Çıktı |
|---|----|----|
| J-1 | Gerçek AppIcon → SwiftUI vektör + 1024×1024 PNG export script | `Resources/AppIcon.appiconset/` tüm boyutlar |
| J-2 | Custom `Info.plist` — `GENERATE_INFOPLIST_FILE: YES` kaldır, `UILaunchScreen > UIColorName: LaunchBackground` ekle | `SnugloApp/Info.plist` |
| J-3 | Screenshot generation script — `xcrun simctl`, 5 ekran × 3 cihaz boyutu (6.7", 6.5", 5.5") | `scripts/screenshots.sh` |
| J-4 | App Store metadata draft | `APPSTORE_METADATA.md` (name, subtitle, keywords, description 4000 char, promotional text, What's New) |
| J-5 | Privacy Policy + Terms of Service | `legal/privacy-policy.md`, `legal/terms-of-service.md` |
| J-6 | Release build config — Release scheme, dSYM on, bitcode off | `project.yml` release config |
| J-7 | Pre-submission checklist | `pre-submission-checklist.md` |
| J-8 | Custom font dosyaları — `.ttf/.otf` bundle'a ekle, `UIAppFonts` array, `Typography.swift` güncelle | `Resources/Fonts/` |
| J-9 | Ses dosyaları gerçek asset'lere geçiş | `Resources/Audio/*.wav` |

**Manuel (kullanıcı yapacak):**
- Apple Developer Program kaydı + sertifika
- App Store Connect'te app kaydı + provisioning profile
- IAP ürünleri oluşturma (product ID'ler: `com.felabs.snuglo.*`)
- TestFlight beta dağıtımı
- Privacy & Terms hosting (web sitesi)

---

## 7. Referans Dokümanlar

| Doküman | İçerik |
|---------|--------|
| `CHANGELOG.md` | Tüm fazların detaylı değişiklik kaydı |
| `BLOCKERS.md` | Açık/kapalı blocker listesi + aksiyon notları |
| `EXECUTION_PLAN.md` | Faz sırası, kabul kriterleri, Faz J detayı |
| `SNUGLO_SPEC.md` | Tek doğruluk kaynağı — ürün spec, ekran tanımları, level format |
| `RESUME_PROMPT.md` | Agent oturumu sürdürme promptu |
