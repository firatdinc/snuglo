# 11 · Color-Blind Pattern Mode

**Rank:** 11 / 20  **Status:** PENDING  **Slug:** `colorblind-patterns`

## Research basis
Accessibility aids App Store featuring; 'mix colors with symbols/patterns' + luminosity-based palettes (colorblind research).

## Problem / Why it matters
Blocks differ by hue only — hard for color-blind players; also a featuring gap.

## Design
A toggle that overlays distinct patterns/symbols per block color and/or switches to a luminosity-distinct palette.

## Implementation steps
- Add subtle per-color glyph/pattern in BlockView + GridView cell render.
- `@AppStorage("colorblindMode")`; Settings → Gameplay toggle.
- Patterns derived deterministically from piece color index.

## Acceptance criteria
- Toggle adds patterns so colors are distinguishable without hue.
- Persists.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
