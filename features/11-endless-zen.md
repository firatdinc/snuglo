# 11 · Endless Zen Mode

**Rank:** 11 / 20  **Status:** DONE ✅  **Slug:** `endless-zen`

## Market / competitor basis (research)
No-timer infinite play ('just one more') is the genre's most-loved trait (Woodoku Classic); SnugloEngine generates infinitely.

## Why it makes the game more addictive / juicy
Open-ended, pressure-free flow → very long sessions.

## Design
Endless mode: generate levels on the fly (rising size), no fail, track best run; MainMenu entry.

## Implementation steps
- Reuse SnugloEngine generator w/ incrementing seed/size.
- Auto-advance on solve; track endlessBest in ProgressStore.

## Acceptance criteria
- Continuous generated levels; no fail; best persists.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
