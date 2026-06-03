# 20 · Sound Pack Selection (ASMR)

**Rank:** 20 / 20  **Status:** DONE ✅  **Slug:** `sound-packs`

## Market / competitor basis (research)
Players request 'tactile ASMR-style audio feedback' (Woodoku comparison); satisfying audio = stickiness.

## Why it makes the game more addictive / juicy
Tactile, satisfying sound deepens the placement dopamine loop.

## Design
Selectable SFX packs (Classic/Wood/Soft) mapping Sound events to different assets/params.

## Implementation steps
- SoundService: pack setting selecting sample/params per Sound; `@AppStorage('soundPack')`.
- Settings picker; graceful fallback if asset missing.

## Acceptance criteria
- Changing pack changes placement/clear sounds; persists.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
