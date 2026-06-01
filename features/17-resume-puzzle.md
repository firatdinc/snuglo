# 17 · Resume In-Progress Puzzle

**Rank:** 17 / 20  **Status:** PENDING  **Slug:** `resume-puzzle`

## Research basis
'Continue where you left off' is a standard convenience that reduces churn.

## Problem / Why it matters
Leaving mid-level loses placements; returning restarts — friction.

## Design
Persist the in-progress board (placements + elapsed) and restore on reopen; offer Resume/Restart.

## Implementation steps
- Serialize placements+elapsed per levelId to UserDefaults on background/exit.
- On GameView load, if a snapshot exists, restore it.
- Clear on solve/restart.

## Acceptance criteria
- Leaving and returning restores the board.
- Cleared after solve.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
