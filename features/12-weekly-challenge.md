# 12 · Weekly Rotating Challenge

**Rank:** 12 / 20  **Status:** DONE ✅  **Slug:** `weekly-challenge`

## Market / competitor basis (research)
'Weekly challenges keep players engaged & earn exclusive rewards'; events boost retention.

## Why it makes the game more addictive / juicy
A week-long meta-goal pulls players back across multiple days.

## Design
Deterministic weekly challenge (ISO week) with a goal + progress + exclusive reward.

## Implementation steps
- WeeklyChallenge model from week number; progress in ProgressStore (resets weekly).
- MainMenu card; grant reward + toast on completion.

## Acceptance criteria
- Weekly card shows goal+progress; resets each ISO week; reward once.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
