# ui-06 · Button & Press States

**Rank:** 06 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `press-states`

## UX / market basis
Tap feedback within ~100ms + a subtle press transform is an HIG/Material expectation; it makes the UI feel alive & responsive.

## Why it makes the app look more premium / appealing
New tappable cards (rewards, entries) lack a consistent pressed state.

## Design
A reusable press style (scale 0.97 + slight dim, spring, light haptic) applied to all tappable cards/buttons; respects Reduce Motion.

## Implementation steps
- Add a `PressableCardStyle` ButtonStyle (scale+dim+haptic).
- Apply to reward/entry cards and primary buttons.
- Reduce-Motion → no scale.

## Acceptance criteria
- Every tappable surface has a clean, consistent press response.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
