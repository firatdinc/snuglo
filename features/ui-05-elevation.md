# ui-05 · Refined Shadows & Elevation

**Rank:** 05 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `elevation`

## UX / market basis
A consistent elevation scale reads as premium; random shadows read as amateur (Material elevation, HIG).

## Why it makes the app look more premium / appealing
Several new surfaces use ad-hoc shadowL1 / strokes inconsistently.

## Design
Define 2-3 elevation levels (rest/raised/overlay) and apply consistently to cards, rails, and modals; soften and unify.

## Implementation steps
- Add elevation helpers (or standardize on shadowL1/L2) in the card system.
- Apply rest level to cards, raised to primary CTA, overlay to modals.
- Remove duplicate/competing shadows.

## Acceptance criteria
- Surfaces share a consistent, soft elevation scale.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
