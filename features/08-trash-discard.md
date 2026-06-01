# 08 · Discard / Trash a Piece

**Rank:** 8 / 20  **Status:** PENDING  **Slug:** `trash-discard`

## Research basis
Trash-can/discard is an explicitly requested feature (Woody Block Puzzle).

## Problem / Why it matters
If a tray piece is awkward there's no way to skip it — increases frustration.

## Design
A discard action (limited uses or small cost) removes a chosen tray piece and replaces/skips it.

## Implementation steps
- Add a discard affordance (drag-to-trash zone or a button on the selected piece).
- ViewModel: remove the piece from unplaced (or swap with a fresh generated one in endless).
- Limit via a per-level count or small currency cost; haptic + sound.

## Acceptance criteria
- Discarding removes a tray piece.
- Limited/charged so it can't be abused.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
