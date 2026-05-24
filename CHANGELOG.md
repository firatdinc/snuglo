# Changelog — Snuglo

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
