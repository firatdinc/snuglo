# 15 · 30-Day Daily Reward Calendar

**Rank:** 15 / 20  **Status:** DONE ✅  **Slug:** `daily-calendar`

## Market / competitor basis (research)
Daily login calendars drive the +40% daily-challenge retention effect; reward cycles maximize retention.

## Why it makes the game more addictive / juicy
Anticipation of escalating day-N rewards builds a daily habit.

## Design
A 30-day reward calendar (claimed/today/upcoming) with escalating rewards + claim animation.

## Implementation steps
- DailyRewardCalculator per-day rewards; 30-cell grid w/ states.
- Claim flow reflecting lastClaimedDay + celebratory animation.

## Acceptance criteria
- Calendar shows 30 days; today claimable; reflects state.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
