# 16 · Discard / Trash a Piece

**Rank:** 16 / 20  **Status:** DONE ✅ (adapted)  **Slug:** `trash-discard`

## Market / competitor basis (research)
Trash/discard is an explicitly requested feature (Woody Block Puzzle).

## Why it makes the game more addictive / juicy
Removes a stuck-feeling → fewer quits, longer sessions.

## Design
A discard action (limited/charged) removes a chosen tray piece (and in endless, swaps a fresh one).

## Implementation steps
- Drag-to-trash zone or button on selected piece.
- ViewModel removes/replaces the piece; limit via count/cost; haptic+sound.

## Acceptance criteria
- Discard removes a tray piece; limited so not abusable.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
