# Changelog — Snuglo

---

## [v1.0-D2] — DailyPuzzle + PackProvider (2026-05-25)

### Yeni: `Sources/SnugloEngine/Engine/DailyPuzzle.swift`

- **`DailyPuzzle.swift`** *(new)* — Tarih-tabanlı deterministik bulmaca üretici.
  - `today(timezone:) → Level` — bugünün bulmacası (UTC baz).
  - `forDate(_:timezone:) → Level` — belirli tarih için level üretir.
  - `seed(for:timezone:) → UInt64` — debug/test amacıyla raw seed değeri.
  - `gridSize(for:) → Int` — UTC weekday'e göre grid boyutu.
  - Seed: `year×10000 + month×100 + day` (örn. 2026-01-01 → 20260101).
  - Haftalık gridSize rotasyonu: Mon/Fri→5×5, Tue/Sat→6×6, Wed/Sun→7×7, Thu→8×8.
  - Aynı tarih → deterministik aynı Level (id: `"daily-0"`).
  - **UTC ENFORCEMENT (BLOCKER fix):** `timezone` parametresi API uyumluluğu için kabul
    edilir ancak tüm DateComponents hesaplamaları `TimeZone(identifier: "UTC")!` ile
    yapılır. Farklı timezone'lardaki cihazlar her zaman aynı günlük bulmacayı görür.
    Regression lock: 2026-01-01 Perşembe → seed=20260101, gridSize=8. ✓

### Yeni: `SnugloApp/MockData/PackProvider.swift`

- **`PackProvider.swift`** *(new)* — Engine (LevelGenerator) ile UI (Pack/LevelItem) köprüsü.
  - `allPacks() → [Pack]` — MockData.allPacks wrapper (Faz E'de persistence).
  - `levelItems(in packId:) → [LevelItem]` — 60 deterministik LevelItem.
    - Faz D-2: progress statik (hepsi not-completed, sadece index=1 unlocked).
    - Faz E: AppStorage/CoreData'dan okunacak.
  - `loadLevel(packId:levelIndex:) → Level` — engine Level üretir.
  - `loadLevel(id:) → Level?` — `"{packId}-{index}"` format parser.
  - `dailyPuzzle() → Level` — `DailyPuzzle.today()` wrapper.

### UI Ekranları — PackProvider'a Bağlandı

| Ekran | Değişiklik |
|-------|------------|
| `LevelsListView` | `PackProvider.allPacks()` ile 4 pack kartı |
| `PackDetailView` | `PackProvider.levelItems(in:)` ile 60 tile (engine-generated) |
| `GameView` | `GameViewModel.makeFromPackProvider(levelId:)` onAppear'da; `"daily"` → DailyPuzzle |
| `GameViewModel` | `makeFromPackProvider(levelId:)` — `"daily"` ve `"packId-index"` formatı |
| `MainMenuView` | `dailyGridSize: Int { PackProvider.dailyPuzzle().width }` — gerçek engine gridSize badge |

### Yeni Testler

- **`DailyPuzzleTests.swift`** — 12 test: determinizm, tüm hafta günleri (7 test),
  farklı tarih farklı seed, seed hesaplama doğruluğu, geçerli level yapısı, id formatı.

### Test Sonuçları

```
DailyPuzzleTests     14/14 ✅  (+2: UTC enforcement + SolutionChecker validity)
LevelGeneratorTests  19/19 ✅
SeededRandomTests    10/10 ✅
LevelLoaderTests      5/5  ✅
PieceCellCountTests   4/4  ✅
SolutionCheckerEdge  13/13 ✅
SolutionCheckerSanity 1/1  ✅
──────────────────────────────────────────────────────────────
Toplam               66/66 ✅  (swift test 2026-05-25)
xcodebuild           ✅ BUILD SUCCEEDED (iOS 26.2 Simulator, 0 hata)
```

### Faz E Köprüsü

`PackProvider.levelItems(in:)` şimdilik tüm level'ları `isCompleted: false` döndürür.
Faz E'de `@AppStorage("progress_\(packId)")` veya `CoreData` entegrasyonu için:
- `levelItems(in:)` → `UserDefaults.standard.array(forKey: "completed_\(packId)")` okuyacak
- `PackProvider.markCompleted(levelId:stars:)` → UserDefaults/CoreData'ya yazacak
- `MockData.continuePack/continueLevel` → PackProvider'a taşınacak (gerçek veri)
- MainMenuView progressPill → `PackProvider.totalCompletedCount()` sayacını kullanacak

---

## [v1.0-D1] — LevelGenerator Engine (2026-05-25)

### Yeni: `Sources/SnugloEngine/Engine/`

- **`SeededRandom.swift`** *(new)* — `SplitMix64` algoritması ile `RandomNumberGenerator` uyumlu,
  cross-run deterministik PRNG. `SeededRandom(seed:)` + `SeedHash.fnv1a(_:)` (FNV-1a 64-bit,
  Swift `hashValue`'nin aksine run'dan run'a kararlı).

- **`LevelGenerator.swift`** *(new)* — Seeded Voronoi BFS partitioning ile deterministic level üreteci.
  - `generate(packId:levelIndex:gridSize:seedBase:) → Level` — tek level.
  - `generateAll(packId:gridSize:count:) → [Level]` — batch üretim (1…count).
  - `difficultyPieceCount(gridSize:levelIndex:) → Int` — difficulty curve tablosu
    (5×5: 4→5, 6×6: 5→6→7, 7×7: 6→7→8, 8×8: 8→10→12 parça).
  - Her üretilen Level'in `solution`'ı `SolutionChecker.check → .valid` garantili.
  - `defaultSeedBase = 0x534E55474C4F3131` ("SNUGLO11" ASCII).

- **`LevelLoader.swift`** *(D3 ekleme — BLOCKER fix)* — `loadGenerated` ve `gridSize` eklendi:
  - `static func gridSize(for packId:) → Int` — cozy-beginnings→5, spice-route→6, mambo-nights→7, woodland-retreat→8 (kısa form "cozy"/"spice"/"mambo"/"woodland" de desteklenir).
  - `func loadGenerated(packId:levelIndex:seedBase:) throws → Level` — `LevelGenerator.generate` wrapper; infallible (hiçbir zaman throw etmez, `throws` gelecekteki kaynak türleri için).

### Yeni Testler

- **`SeededRandomTests.swift`** — 10 test: determinizm, farklı seed, sıfır-seed güvenliği,
  stdlib entegrasyonu, FNV1a sabit değer (`0x89CF91E4E692ADC1`), boş string, idempotency.
- **`LevelGeneratorTests.swift`** — 19 test: determinizm, geçerli solution (tüm grid boyutları),
  `generateAll` 60 distinct level, grid boyutu koruması, difficulty curve değerleri,
  piece count aralıkları, yapısal bütünlük (toplam hücre = width×height).

### Test Sonuçları

```
LevelGeneratorTests  19/19 ✅
SeededRandomTests    10/10 ✅
LevelLoaderTests      5/5  ✅
PieceCellCountTests   4/4  ✅
SolutionCheckerEdge  13/13 ✅
SolutionCheckerSanity 1/1  ✅
─────────────────────────────
Toplam               52/52 ✅
```

### UI Değişikliği

Yok. PackProvider / MockData bağlantısı Faz D-2'de yapılacak.

---

## [v1.0-C] - 2026-05-25 (Faz C — 11 Ekran Gerçekten Yaratıldı)

Navigation iskelesi: 11 SwiftUI screens (Splash/Onboarding/MainMenu/LevelsList/PackDetail/GamePlay/Pause/LevelComplete/Stats/Shop/Settings); AppRouter (Route enum, @Observable) + NavigationStack; BottomTabBar component; MockData with 4 packs × 60 levels (240 total); Colors.swift extended with missing tokens (surface, onPrimaryContainer, secondaryContainer, tertiaryContainer, surfaceContainerLowest); GameView refactored with levelId param, timer HUD, PauseSheet & LevelCompleteSheet integration.

## [v1.0-C] — Navigation Skeleton (2026-05-25)

### Navigation (C1–C2)
- **`AppRouter.swift`** *(new)* — `@Observable` class with `path: [Route]`, `selectedTab: AppTab`.
  `enum Route`: `onboarding | mainMenu | game(levelID:) | packDetail(packName:) | settings | shop`.
  `enum AppTab`: `play | levels | stats | shop`. Helpers: `push(_:)`, `pop()`, `popToRoot()`.
- **`RootView.swift`** *(new)* — Single `NavigationStack(path:)` rooted at `SplashView`.
  All destinations registered via `.navigationDestination(for: Route.self)`.
- **`SnugloApp.swift`** — Entry point changed from `GameView()` → `RootView()`.

### Screens (C3)
- **`SplashView.swift`** *(new)* — 3×3 pastel block logo, fade-in + soft scale pulse.
  Auto-advances after 1.2 s: `hasOnboarded` → mainMenu or onboarding.
- **`OnboardingView.swift`** *(new)* — 3-page TabView carousel, dot indicators, Skip + Get Started.
  Sets `@AppStorage("hasOnboarded")` on completion.
- **`MainMenuView.swift`** *(new)* — TabView host (PLAY / LEVELS / STATS / SHOP).
  Play tab: progress pill, Daily Puzzle hero card, Continue section.
- **`LevelsListView.swift`** *(new)* — Pack cards (Cozy Beginnings, Spice Route, Nordic Hearth).
  Each card: icon badge, progress bar, tap → packDetail.
- **`PackDetailView.swift`** *(new)* — Banner with progress bar + 3-column LazyVGrid of 30 level tiles.
  Tile states: completed (stars), active, locked.
- **`StatsView.swift`** *(new)* — 2×2 stat cards (Solved 142 / Time 48h / Fastest 1:12 / Streak 14d),
  weekly bar chart, hint donut.
- **`ShopView.swift`** *(new)* — Snuglo Plus hero card, horizontal hint packs scroll, Remove Ads row.
- **`SettingsView.swift`** *(new)* — Toggle rows (Music / SFX / Haptics / Daily reminder), About section.
  Backed by `@AppStorage`.
- **`PauseOverlayView.swift`** *(new)* — Blur dimmer + card: Paused headline, timer, Resume/Restart/Home.
- **`LevelCompleteSheet.swift`** *(new)* — Bottom sheet: check circle, puzzle thumbnail, stats row
  (Time / Stars / Hints), Next Level / Replay / Home actions.

### Theme (C5)
- **`Colors.swift`** — Added `errorContainer`, `surfaceVariant` tokens.
  Made `Color(hex:)` initializer `internal` (was `private`) so feature files can use it.
- **`Typography.swift`** — Removed deprecated Faz B shims: `title`, `subtitle`, `body`, `caption`,
  `mono`, `blockLabel`. No call-sites were using them (confirmed by grep).
- **`Spacing.swift`** — Removed deprecated Faz B shim: `xxl`. No call-sites (confirmed by grep).

---

## [v1.0-B] — Nordic Hearth Theme (2026-05-25)

### Theme System (B1)
- **`Colors.swift`** — Replaced coral/cream palette with full Nordic Hearth token set:
  `background` `surfaceContainerLow/High/Highest` `primary` `primaryContainer` `onPrimary`
  `secondary` `tertiary` `onSurface` `onSurfaceVariant` `outline` `outlineVariant` `error`
  + 6 pastel block fills: `blockLavender/Sage/Peach/Blush/Cream/DustyOlive`
  + `shadowAmbient` tonal shadow base color.
- **`Typography.swift`** — Nordic Hearth scale: `headlineLarge/Medium/Small` (SF Rounded 28/22/18),
  `bodyLarge/Medium` (SF Pro 17/15), `numericLabel` (SF Mono 20), `labelSmall` (SF Pro 12 + UPPERCASE +tracking).
  System-font fallbacks used; custom fonts deferred to Faz H (BLOCKER-07).
  Legacy aliases (`title`, `body`, `caption`, `mono`, `blockLabel`) deprecated with `@available`.
- **`Spacing.swift`** — Updated to design-spec values: `xs=4 sm=8 md=16 lg=24 xl=32`.
  Radius tokens removed from Spacing (moved to Radius.swift).
- **`Radius.swift`** *(new)* — `AppRadius.card=20 / button=14 / block=10`.
- **`Shadow.swift`** *(new)* — `.shadowL1()` (0.06 opacity) / `.shadowL2()` (0.12 opacity) View modifiers.

### Piece Model (B2)
- **`Piece.swift`** — Added `public var cellCount: Int { cells.count }` computed property.
  Domain model unchanged; convenience added for BlockView numeric label.

### BlockView Rebuilt (B3)
- **`BlockView.swift`** — Full rebuild: Canvas-based, all Nordic Hearth tokens:
  - Pastel fill via `AppColors.blockColor(for: piece.id)` (deterministic `hashValue % 6`)
  - Corner radius `AppRadius.block` (10 pt) per cell
  - L1 shadow (idle) / L2 shadow (picked-up, scale 1.10×)
  - Inner-top bevel: 0.5 pt white-50% horizontal line when dragging
  - `piece.cellCount` label always shown, `AppTypography.numericLabel`, `AppColors.onSurface`

### GameView Palette (B4)
- **`GameView.swift`** — Background → `AppColors.background`; tray → `surfaceContainerHigh`;
  header text → `onSurface`/`onSurfaceVariant`; solved banner → `primary` fill.
- **`GridView.swift`** — Board background → `surfaceContainerLow`; grid lines → `outlineVariant`;
  all `AppSpacing.blockRadius/cardRadius` → `AppRadius.block/card`; `.shadowL1()` applied.

### Tests (B5)
- **`PieceCellCountTests.swift`** *(new)* — 4 unit tests for `Piece.cellCount`.
- `swift build` ✅ | `swift test` ✅ — 23 tests, 0 failures.

### Deferred to Faz H
- Dark mode token values (BLOCKER-06)
- Custom font bundle files: Plus Jakarta Sans / Be Vietnam Pro / Space Grotesk (BLOCKER-07)

All notable changes to this project are documented here.
Format: `## vX.Y — Title (YYYY-MM-DD)`

---

## v0.2 — Core UI (2026-05-24)

### Added
- `SnugloApp/` iOS App target (xcodegen, bundle id `com.felabs.snuglo`, iOS 17+, SwiftUI)
- `SnugloApp/project.yml` — xcodegen config with local `SnugloEngine` SPM dependency
- `SnugloApp/App/SnugloApp.swift` — `@main` App entry point
- `SnugloApp/Features/Game/GameViewModel.swift` — `@MainActor @Observable` state machine
  - `tryPlace(pieceID:at:)` — validates via `SolutionChecker`; accepts / rejects placement
  - `checkSolved()` — prints "Solved!" and sets `isSolved = true` when grid fully covered
- `SnugloApp/Features/Game/GameView.swift` — drag-drop game screen
  - Loads `level_5x5.json` on init
  - SwiftUI `DragGesture` with `.named("gameLayout")` coordinate space
  - Snap-to-grid with ±15pt buffer
  - Rejected placement: invalid red border + ease-back animation
  - Ghost overlay shows where piece will land
- `SnugloApp/Features/Game/GridView.swift` — Canvas-based grid renderer
  - Grid lines, placed pieces, snap ghost
- `SnugloApp/Features/Game/BlockView.swift` — piece renderer with drag scale & shadow
- `SnugloApp/Core/Theme/Colors.swift` — full Spec §7 color palette (`AppColors`)
- `SnugloApp/Core/Theme/Typography.swift` — SF font scale (`AppTypography`)
- `SnugloApp/Core/Theme/Spacing.swift` — 4dp base unit tokens (`AppSpacing`)
- `Tests/SnugloAppTests/GameViewModelTests.swift` — 4 ViewModel unit tests

### Build
```
cd SnugloApp && xcodegen generate
xcodebuild -project SnugloApp/SnugloApp.xcodeproj \
           -scheme SnugloApp \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build
```
