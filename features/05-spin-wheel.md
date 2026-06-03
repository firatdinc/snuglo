# 05 · Daily Spin Wheel

**Rank:** 5 / 20  **Status:** DONE ✅  **Slug:** `spin-wheel`

## Market / competitor basis (research)
Daily spin/wheel bonuses are a classic, proven daily-return hook across casual games.

## Why it makes the game more addictive / juicy
Free daily variable reward → strong daily-open habit; anticipation loop.

## Design
A once-per-day spin wheel granting currency/power-ups; animated spinning with easing + win highlight.

## Implementation steps
- WheelView: rotating segments, spring-decelerated spin, deterministic-but-fair outcome.
- Gate to once/day via lastSpinDay in ProgressStore; grant via WalletStore.
- Entry point on MainMenu (badge when available).

## Acceptance criteria
- One spin per day awards a reward.
- Locks until next day.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
