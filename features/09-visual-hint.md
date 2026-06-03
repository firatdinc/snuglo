# 09 · Visual Placement Hint

**Rank:** 9 / 20  **Status:** DONE ✅  **Slug:** `visual-hint`

## Market / competitor basis (research)
Getting-unstuck/undo are top requests; reducing frustration extends sessions (avoids rage-quit).

## Why it makes the game more addictive / juicy
Keeps players in flow instead of quitting when stuck → longer sessions.

## Design
A Hint (consumes hintCount) highlights one valid piece+target with a pulsing outline ~2s.

## Implementation steps
- Compute a valid placement via viewModel/SnugloEngine.
- Highlight target cells (snap-ghost style) + glow tray piece.
- Wire to a hint button; decrement; empty → shop.

## Acceptance criteria
- Hint highlights a real valid move; consumes a hint.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
