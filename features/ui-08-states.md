# ui-08 · Empty, Loading & First-Run States

**Rank:** 08 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `states`

## UX / market basis
Polished empty/loading states (skeletons, helpful empties) are a hallmark of premium apps (HIG, Material).

## Why it makes the app look more premium / appealing
Some new surfaces show bare/zero states (no data quests/stats, first-run hubs).

## Design
Add tasteful empty/zero states (icon + one line) and gentle skeletons where data loads, single-palette.

## Implementation steps
- Add zero states to stats/quests/rewards when empty.
- Add a subtle skeleton/shimmer for any async surface.
- Friendly copy, localized.

## Acceptance criteria
- No bare blank states; each has a helpful placeholder.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
