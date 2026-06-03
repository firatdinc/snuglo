# 10 · Streak Milestone Rewards

**Rank:** 10 / 20  **Status:** DONE ✅  **Slug:** `streak-milestones`

## Market / competitor basis (research)
Streak reward cycles maximize retention; extends the shipped play-streak.

## Why it makes the game more addictive / juicy
Milestone payoffs reinforce the daily-return habit.

## Design
Crossing playStreak 7/14/30/… grants a one-time currency reward + celebratory flame toast.

## Implementation steps
- ProgressStore: lastRewardedStreak; award on new milestone (idempotent); migration.
- MainMenu milestone toast.

## Acceptance criteria
- Day 7 grants once; no double-grant on relaunch.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
