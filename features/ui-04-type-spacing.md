# ui-04 · Typography & Spacing Audit

**Rank:** 04 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `type-spacing`

## UX / market basis
A consistent type ramp + 4/8 spacing rhythm is foundational to a polished, legible UI (Material type roles, HIG).

## Why it makes the app look more premium / appealing
New views introduced some ad-hoc font sizes/spacings; rhythm drifts.

## Design
Audit the new views to use AppTypography roles + AppSpacing increments only; fix any raw .system sizes / odd paddings where a token fits.

## Implementation steps
- Sweep the feature files; replace stray .system(size:) with AppTypography where appropriate.
- Normalize paddings/gaps to AppSpacing scale.
- Keep numeric/monospaced where data is shown.

## Acceptance criteria
- New UI uses the type/spacing system consistently.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
