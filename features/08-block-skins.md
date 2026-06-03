# 08 · Unlockable Block Skins

**Rank:** 8 / 20  **Status:** DONE ✅  **Slug:** `block-skins`

## Market / competitor basis (research)
Unlockable skins/themes are top-requested AND a proven monetization + collection loop (Woodoku themes).

## Why it makes the game more addictive / juicy
Collection/customization loop: players grind to unlock & show off skins → longer play.

## Design
Selectable block-color skins (Nordic/Candy/Ocean/Mono); some unlocked via currency/level. `blockColor(for:)` reads active skin.

## Implementation steps
- `BlockSkin` enum of AppColors-token palettes; `@AppStorage('blockSkin')`.
- `AppColors.blockColor(for:)` maps via active skin.
- Settings/Shop picker with swatches + unlock gating.

## Acceptance criteria
- Switching skin recolors all blocks; persists; unlock gating works.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
