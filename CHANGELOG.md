# Changelog — Snuglo

---

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
