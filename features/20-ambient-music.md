# 20 · Ambient Music Tracks

**Rank:** 20 / 20  **Status:** PENDING  **Slug:** `ambient-music`

## Research basis
Cozy atmosphere & soothing audio are core to the cozy-puzzle appeal (calm aesthetics research).

## Problem / Why it matters
Music is a single on/off with one bed; no cozy track variety.

## Design
A small set of ambient tracks selectable in Settings; loops gently; respects the music toggle.

## Implementation steps
- AudioManager/SoundService: track selection + looping bed.
- `@AppStorage("musicTrack")`; Settings → Sound picker.
- Duck/stop on background; honor musicEnabled.

## Acceptance criteria
- Selecting a track changes the ambient loop.
- Honors music toggle.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
