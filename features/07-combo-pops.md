# 07 · Combo Placement Pops

**Rank:** 7 / 20  **Status:** DONE ✅  **Slug:** `combo-pops`

## Market / competitor basis (research)
Combo systems & 'dopamine-triggering particle effects' are core satisfying feedback (juice research).

## Why it makes the game more addictive / juicy
Rewards fast, confident play within a level → flow & satisfaction.

## Design
Rapid successive correct placements show a rising 'Combo xN' pop + sparkle near the board; small bonus.

## Implementation steps
- GameView: track lastPlaceTime+comboCount (window ~2.5s).
- Floating ComboPopup (scale+fade) over the board + sparkle.
- Small bonus scaling into solve reward.

## Acceptance criteria
- Quick placements show Combo x2/x3 with juice.
- Resets on idle.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
