# 04 · Unlockable Block Color Skins

**Rank:** 4 / 20  **Status:** PENDING  **Slug:** `block-skins`

## Research basis
Unlockable themes/skins are a top-requested feature AND a proven monetization lever (Woodoku 'unlock stunning themes').

## Problem / Why it matters
Blocks use one deterministic pastel palette (`AppColors.blockColor(for:)`). No way to personalize.

## Design
Add selectable block-color skins (e.g. Nordic, Candy, Ocean, Mono) chosen in Settings; `blockColor(for:)` reads the active skin. Strictly token-based.

## Implementation steps
- Define skin palettes (arrays of AppColors tokens) in a `BlockSkin` enum.
- `@AppStorage("blockSkin")`; `AppColors.blockColor(for:)` maps via active skin.
- Settings → Appearance: a skin picker with swatches. Localize names.

## Acceptance criteria
- Switching skin re-colors all blocks instantly.
- Persists across launches.
- Single-palette rule kept.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
