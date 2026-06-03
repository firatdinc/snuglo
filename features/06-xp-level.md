# 06 · XP & Player Level Progression

**Rank:** 6 / 20  **Status:** DONE ✅  **Slug:** `xp-level`

## Market / competitor basis (research)
Visible meta-progression (XP, levels) gives a sense of growth that sustains long-term play (RPG-ification of casual).

## Why it makes the game more addictive / juicy
A persistent progress bar players want to fill → 'just reach the next level' sessions.

## Design
Earn XP per solve (bonus for stars/speed); a player level with a bar + level-up reward + celebration.

## Implementation steps
- ProgressStore: totalXP + derived level (curve); award XP on solve.
- MainMenu/Profile: level badge + XP bar; level-up toast + reward.
- Persist; migration.

## Acceptance criteria
- Solving grants XP; filling the bar levels up with a reward.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
