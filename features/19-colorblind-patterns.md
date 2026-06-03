# 19 · Color-Blind Pattern Mode

**Rank:** 19 / 20  **Status:** DONE ✅  **Slug:** `colorblind-patterns`

## Market / competitor basis (research)
Accessibility aids App Store featuring; 'mix color with symbols/patterns' + luminosity palettes (colorblind research).

## Why it makes the game more addictive / juicy
Wider audience + featuring → more installs/retention.

## Design
Toggle overlaying distinct patterns/symbols per block color (and/or a luminosity-distinct palette).

## Implementation steps
- Per-color glyph/pattern in BlockView + GridView cell render; `@AppStorage('colorblindMode')`.
- Settings toggle; deterministic patterns from color index.

## Acceptance criteria
- Toggle makes colors distinguishable without hue; persists.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
