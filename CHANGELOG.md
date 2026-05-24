# Changelog — Snuglo

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
