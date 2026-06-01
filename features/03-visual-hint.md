# 03 · Visual Placement Hint

**Rank:** 3 / 20  **Status:** PENDING  **Slug:** `visual-hint`

## Research basis
Undo & getting-unstuck are top requests; 'players appreciate not being stuck'. A visible hint reduces rage-quit.

## Problem / Why it matters
`hintCount` exists & is purchasable but there is no visual hint that shows WHERE a piece can go.

## Design
A Hint button (consumes hintCount) highlights one valid piece+target with a pulsing outline for ~2s.

## Implementation steps
- Compute a valid placement via SnugloEngine/viewModel (first unplaced piece that fits).
- Highlight target cells (reuse GridView snap-ghost style) + glow the tray piece.
- Wire to PowerUpBar / a hint button; decrement hintCount; empty → route to shop.

## Acceptance criteria
- Tapping Hint highlights a real valid move.
- Consumes one hint; 0 hints → shop prompt.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
