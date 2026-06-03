# ui-09 · Iconography Consistency

**Rank:** 09 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `iconography`

## UX / market basis
One icon language (weight, size, style) across the product is a core polish rule (HIG/Material).

## Why it makes the app look more premium / appealing
New views use varied SF Symbol weights/sizes and badge styles.

## Design
Standardize icon sizes/weights via tokens and unify badge/iconBadge styling across cards, rails, HUD.

## Implementation steps
- Define icon size tokens (sm/md/lg) + a standard iconBadge.
- Apply across the new cards/rails/HUD.
- Consistent stroke/fill discipline per hierarchy.

## Acceptance criteria
- Icons share one consistent visual language.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
