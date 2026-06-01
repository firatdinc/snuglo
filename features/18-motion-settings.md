# 18 · Granular Motion & Effects Settings

**Rank:** 18 / 20  **Status:** PENDING  **Slug:** `motion-settings`

## Research basis
Accessibility & user control; Reduce Motion respect is an Apple HIG expectation.

## Problem / Why it matters
Animations are global; some players want calmer visuals beyond system Reduce Motion.

## Design
A Settings 'Effects' section: toggles for particles, screen-shake/flash, and animation intensity.

## Implementation steps
- `@AppStorage` flags (particlesEnabled, flashEnabled).
- Gate SolveCelebration / invalidFlash / tilt on these flags + reduceMotion.
- Settings UI section + localization.

## Acceptance criteria
- Toggling effects off disables the matching juice.
- Persists.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
