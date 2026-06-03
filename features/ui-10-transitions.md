# ui-10 · App-Wide Transitions & Micro-interactions

**Rank:** 10 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `transitions`

## UX / market basis
Smooth, consistent motion (shared easing/duration, staggered reveals) elevates perceived quality (HIG fluid motion, Material).

## Why it makes the app look more premium / appealing
Transitions are mostly default; reveals appear all-at-once; motion rhythm isn't unified.

## Design
Unify a motion language: standard spring tokens, staggered card entrance on the menu, smooth tab/section changes; all Reduce-Motion-safe.

## Implementation steps
- Define spring/duration motion tokens.
- Add a subtle staggered entrance to menu cards/rails.
- Apply consistent transitions to overlays/sections; honor Reduce Motion.

## Acceptance criteria
- Motion feels cohesive & premium; reduced-motion respected.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
