# ui-03 · Cohesive Card System

**Rank:** 03 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `card-system`

## UX / market basis
A unified surface/elevation/typography system is what separates premium apps from ad-hoc ones (Material/HIG).

## Why it makes the app look more premium / appealing
The many new cards use slightly different paddings, corner radii, borders, and label fonts.

## Design
Define a single `infoCard` modifier (padding, radius, cardSurface, optional accent ring) and apply it across all new cards for visual rhythm.

## Implementation steps
- Add a `.infoCard(accent:)` ViewModifier in a shared file.
- Apply to quests/weekly/chest/spin/calendar/endless cards + Profile XP card.
- Standardize header row (icon + title + trailing value).

## Acceptance criteria
- All cards share consistent padding/radius/elevation/headers.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
