# 13 · Sound Pack Selection (ASMR)

**Rank:** 13 / 20  **Status:** PENDING  **Slug:** `sound-packs`

## Research basis
Players request 'tactile ASMR-style audio feedback' (Woodoku comparison).

## Problem / Why it matters
One SFX set; no way to choose a more tactile/ASMR feel.

## Design
Selectable SFX packs (e.g. Classic, Wood, Soft) mapping the same Sound events to different assets/synth params.

## Implementation steps
- SoundService: a `pack` setting selecting which sample/params to play per Sound.
- `@AppStorage("soundPack")`; Settings → Sound picker.
- Graceful fallback if an asset is missing.

## Acceptance criteria
- Changing pack changes placement/clear sounds.
- Persists.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
