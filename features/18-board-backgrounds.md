# 18 · Cozy Board Backgrounds

**Rank:** 18 / 20  **Status:** DONE ✅  **Slug:** `board-backgrounds`

## Market / competitor basis (research)
Customization/themes are top-requested; collection of backdrops adds an unlock loop.

## Why it makes the game more addictive / juicy
More to collect/customize → identity & return visits.

## Design
Selectable board backdrops (Parchment/Dawn/Forest/Night) behind the grid, chosen in Settings/Shop.

## Implementation steps
- BoardBackground enum → gradient/texture from AppColors tokens; `@AppStorage`.
- Board renders active backdrop; picker with previews + unlock gating.

## Acceptance criteria
- Switching backdrop changes the board scene; persists.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
