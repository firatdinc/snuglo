# 15 · 30-Day Daily Reward Calendar

**Rank:** 15 / 20  **Status:** PENDING  **Slug:** `daily-calendar`

## Research basis
Daily login calendars drive the +40% daily-challenge retention effect; reward cycles maximize retention.

## Problem / Why it matters
DailyReward grants exist but there's no visible multi-day calendar to anticipate.

## Design
A 30-day reward calendar UI showing claimed/today/upcoming days with escalating rewards.

## Implementation steps
- Use DailyRewardCalculator for per-day rewards; render a 30-cell grid.
- Highlight today; lock future; check/dim past.
- Claim flow + celebratory animation.

## Acceptance criteria
- Calendar shows 30 days with states.
- Today is claimable; reflects lastClaimedDay.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
