# ui-01 · Main Menu Hub Redesign (declutter)

**Rank:** 01 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `mainmenu-hub`

## UX / market basis
Apple HIG: one clear primary action per screen; content hierarchy via grouping. Top casual games surface rewards as a compact hub, not a long stack.

## Why it makes the app look more premium / appealing
The feature wave added 10+ stacked cards (streak, daily, progress, spin, calendar, chest, endless, weekly, quests, continue). It now reads as a cluttered list — hurts the premium feel.

## Design
Group secondary rewards (spin/chest/calendar) into a compact horizontal 'rewards rail' of icon-buttons with availability badges; keep ONE primary CTA (daily puzzle / continue). Section the rest. Reduce vertical stacking.

## Implementation steps
- MainMenuView.scrollContent: replace the long VStack with: hero (daily puzzle), a compact rewards rail (spin/chest/calendar as 3 icon tiles w/ '!' badges), then quests + weekly grouped, then continue.
- Extract a `rewardTile` component; keep existing overlays/stores.
- Tighten spacing; ensure it fits without endless scroll.

## Acceptance criteria
- Main menu reads as a clean hub, not a 10-card stack.
- All entry points still reachable.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
