# 05 · Streak Milestone Rewards

**Rank:** 5 / 20  **Status:** PENDING  **Slug:** `streak-milestones`

## Research basis
Streak bonuses & reward cycles 'maximize retention' (Candy Crush/Block Blast research). Extends the play-streak already shipped.

## Problem / Why it matters
playStreak is shown but crossing 7/14/30 days grants nothing — no payoff loop.

## Design
When playStreak crosses a new milestone (7,14,30,…) grant a one-time currency reward + a celebratory toast.

## Implementation steps
- ProgressStore: `lastRewardedStreak`; on updatePlayStreak, if a new milestone reached, award via WalletStore (idempotent).
- Milestone toast on MainMenu (flame burst).
- Persist lastRewardedStreak in snapshot (migration).

## Acceptance criteria
- Hitting day 7 grants a reward exactly once.
- No double-grants on relaunch.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
