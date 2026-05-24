# Changelog — Snuglo

---

## [v1.0-B fix] — Tokens & Tracking (2026-05-25)

### FIX 1 — Stable piece coloring hash
- **`Colors.swift`** — `blockColor(for:)` now uses FNV-1a 32-bit instead of `String.hashValue`.
  Swift's `hashValue` is randomised per-process (SE-0206) and must not be used for any
  persistent or cross-run determinism. FNV-1a produces identical results across every process
  launch, OS version and Swift update; the same piece ID always maps to the same pastel.

### FIX 2 — Headline / label tracking via Text helpers
- **`Typography.swift`** — Added `extension Text` with six helpers that bake in the
  per-scale tracking values specified in INDEX.md:

  | Helper | Font | Tracking |
  |---|---|---|
  | `appHeadlineLarge()` | headlineLarge 28 pt | −0.6 pt (−0.02 em) |
  | `appHeadlineMedium()` | headlineMedium 22 pt | −0.4 pt (−0.02 em) |
  | `appHeadlineSmall()` | headlineSmall 18 pt | −0.3 pt (−0.02 em) |
  | `appLabelSmall()` | labelSmall 12 pt | +0.6 pt (+0.05 em) + UPPERCASE |
  | `appBodyLarge()` | bodyLarge 17 pt | — (bodyText foreground baked in) |
  | `appBodyMedium()` | bodyMedium 15 pt | — (bodyText foreground baked in) |

- **`GameView.swift`** — Raw `.font(AppTypography.xxx)` call-sites replaced:
  - `Text("Snuglo")`: `.font(headlineLarge)` → `.appHeadlineLarge()`
  - `Text(level.id)`: `.font(labelSmall).tracking(0.6).textCase(.uppercase)` → `.appLabelSmall()`
  - `Text("🎉 Solved!")`: `.font(headlineMedium)` → `.appHeadlineMedium()`

### FIX 3 — Body text color token `#3A332D`
- **`Colors.swift`** — Added `static let bodyText = Color(hex: "#3A332D")`.
  Per Designs/INDEX.md body copy must never be pure black; `#3A332D` (warm dark brown) is
  the canonical body color. `appBodyLarge()` / `appBodyMedium()` apply it automatically.

### Build
- `swift build` ✅ | `swift test` ✅ — 23 engine tests, 0 failures
- `xcodebuild test -scheme SnugloApp` ✅ — 13 app tests, 0 failures

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
  - Pastel fill via `AppColors.blockColor(for: piece.id)` (deterministic `FNV-1a % 6`)
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

## [v1.0-A] — Stabilization (2026-05-25)

Stabilization: build & test green; drag-drop offset verified; doc sync for 240-level plan.

### Build
- `swift build` → **BUILD SUCCEEDED** (0 warnings)
- `swift test` (SnugloEngine) → **19 tests passed**, 0 failures
- `xcodebuild test -scheme SnugloAppTests` → **13 tests passed**, 0 failures (4 GameViewModelTests + 9 SnapCalculatorTests)

### Added
- `SnugloApp/Features/Game/SnapCalculator.swift` — pure, testable snap-to-grid logic extracted from `GameView`
- `Tests/SnugloAppTests/SnapCalculatorTests.swift` — 9 unit tests covering center snap, boundary cases, nil-guards, 2-cell piece clamping

### Changed
- `GameView.calculateSnap` refactored to delegate to `SnapCalculator` (thin wrapper, no behaviour change)
- `SnugloApp/SnugloApp.xcodeproj/project.pbxproj` regenerated via `xcodegen generate` to include new source file

### Documentation
- `EXECUTION_PLAN.md` v0.4 section: added 240-level note (4 pack × 60, supersedes old 4 pack × 30)
- `BLOCKERS.md`: added Faz A→J plan summary + discarded-task reconciliation log

### Git
- Merged v0.2 feature branches into `main` (no-ff merge commit `3ec7527`)
- `feature/v1.0-A-stabilize` branched from updated `main`

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
