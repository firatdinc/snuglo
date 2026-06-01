# 14 · Achievement Unlock Toasts

**Rank:** 14 / 20  **Status:** PENDING  **Slug:** `achievements-toast`

## Research basis
Achievement/reward loops maximize retention; visible unlock moments add delight.

## Problem / Why it matters
Achievements exist (AchievementRules/Stats) but unlocking is silent — no feedback.

## Design
Show an unlock toast (icon+title) the moment an achievement is earned; a small currency reward.

## Implementation steps
- Hook achievement evaluation post-solve; diff newly-unlocked.
- `AchievementToast` overlay (slide+fade); queue multiple.
- Optional small reward via WalletStore.

## Acceptance criteria
- Earning an achievement shows a toast.
- No duplicate toasts.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
