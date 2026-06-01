# 06 · Weekly Rotating Challenge

**Rank:** 6 / 20  **Status:** PENDING  **Slug:** `weekly-challenge`

## Research basis
'Weekly challenges keep players engaged & earn exclusive rewards'; events boost retention (multiple sources).

## Problem / Why it matters
Only a daily puzzle exists; no weekly meta-goal to pull players back across the week.

## Design
A deterministic weekly challenge (seeded by ISO week) with a goal (e.g. solve N levels) + progress bar + reward on completion.

## Implementation steps
- `WeeklyChallenge` model: deterministic from week number; goal + reward.
- Track weekly progress in ProgressStore (resets on week change).
- MainMenu card showing progress; grant reward + toast on completion.

## Acceptance criteria
- A weekly card shows a goal + progress.
- Progress resets each ISO week.
- Reward granted once.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
