# ui-07 · Game HUD Polish

**Rank:** 07 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `game-hud`

## UX / market basis
Clarity & grouping in the play screen reduce cognitive load (HIG). The HUD gained chips/buttons.

## Why it makes the app look more premium / appealing
Game HUD now packs back / level / timer / skip / pause + chain chip + combo + toasts; spacing & grouping can feel busy.

## Design
Tidy HUD grouping & spacing: balance left/right clusters, align the chain chip, ensure the toast/combo don't collide with chrome.

## Implementation steps
- GameView gameHUD/progressRow: refine spacing, alignment, and z-order.
- Position chain chip + combo pop so they never overlap HUD/timer.
- Consistent 40pt circular buttons + spacing.

## Acceptance criteria
- Game HUD reads clean & balanced with all elements.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
