# 07 · Endless Zen Mode

**Rank:** 7 / 20  **Status:** PENDING  **Slug:** `endless-zen`

## Research basis
No-timer/relaxing infinite play is the genre's most-loved trait (Woodoku Classic). SnugloEngine is a deterministic generator → infinite levels are cheap.

## Problem / Why it matters
Play is finite (packs). Cozy players want an endless, pressure-free flow.

## Design
An Endless mode: generate levels on the fly (increasing size), no fail, track best run; entry from MainMenu.

## Implementation steps
- Reuse SnugloEngine generator with an incrementing seed/size.
- New route/screen; on solve → auto-advance to the next generated level.
- Track endlessBest in ProgressStore.

## Acceptance criteria
- Endless mode plays continuous generated levels.
- No timer/fail.
- Best run persists.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
