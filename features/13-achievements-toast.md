# 13 · Achievement Unlock Toasts

**Rank:** 13 / 20  **Status:** DONE ✅  **Slug:** `achievements-toast`

## Market / competitor basis (research)
Achievement/reward loops add delight & completion compulsion (universal casual mechanic).

## Why it makes the game more addictive / juicy
Surprise unlock moments = dopamine; chase-the-badge retention.

## Design
Show an unlock toast (icon+title) the instant an achievement is earned + small reward.

## Implementation steps
- Diff newly-unlocked post-solve (AchievementRules/Stats).
- AchievementToast overlay (slide+fade); queue multiples; optional reward.

## Acceptance criteria
- Earning shows a toast; no duplicates.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
