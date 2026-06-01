# 02 · Combo Multiplier & Pop Feedback

**Rank:** 2 / 20  **Status:** PENDING  **Slug:** `combo-scoring`

## Research basis
'Score multipliers come from chaining combos'; combo systems are a core satisfying retention mechanic (juice research).

## Problem / Why it matters
Placing pieces gives flat reward; rapid successive correct placements aren't rewarded, missing the combo dopamine loop.

## Design
Track placements made within a short window; show a rising 'Combo xN' pop near the board and a small bonus. Decays on idle.

## Implementation steps
- GameViewModel/GameView: track lastPlaceTime + comboCount; increment if within ~2.5s.
- Floating `ComboPopup` view (scale+fade) anchored over the board.
- Apply a small currency/score bonus scaling with combo on solve.

## Acceptance criteria
- Quick consecutive placements show Combo x2, x3…
- Combo resets after idle.
- Bonus reflected in reward.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
