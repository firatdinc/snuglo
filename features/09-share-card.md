# 09 · Share Result Card

**Rank:** 9 / 20  **Status:** PENDING  **Slug:** `share-card`

## Research basis
Social sharing/leaderboards drive virality; share images are a standard growth lever.

## Problem / Why it matters
Winning produces no shareable artifact — zero organic reach.

## Design
On level complete, a 'Share' button renders a branded result card (level, time, stars, streak) via ImageRenderer + ShareLink.

## Implementation steps
- `ResultCard` SwiftUI view (branded, single-palette).
- ImageRenderer → UIImage; SwiftUI ShareLink in LevelCompleteSheet.
- Include app name + a tasteful watermark.

## Acceptance criteria
- Share button exports a clean result image.
- Share sheet appears.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
