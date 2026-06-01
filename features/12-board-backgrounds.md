# 12 · Cozy Board Backgrounds

**Rank:** 12 / 20  **Status:** PENDING  **Slug:** `board-backgrounds`

## Research basis
Customization/themes are top-requested; cozy ambience increases session comfort.

## Problem / Why it matters
The board background is a single flat surface — no cozy variety.

## Design
Selectable board backdrops (e.g. Parchment, Dawn, Forest, Night) applied behind the grid, chosen in Settings.

## Implementation steps
- `BoardBackground` enum → gradient/texture from AppColors tokens.
- `@AppStorage("boardBackground")`; GridView/board renders the active backdrop.
- Settings picker with previews.

## Acceptance criteria
- Switching backdrop changes the board scene.
- Persists.
- Single-palette.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
