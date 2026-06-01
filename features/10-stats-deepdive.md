# 10 · Stats Deep-Dive

**Rank:** 10 / 20  **Status:** PENDING  **Slug:** `stats-deepdive`

## Research basis
Completionists value progress/stats; charts increase session depth (puzzle stats research).

## Problem / Why it matters
StatsView is shallow; rich data (best times, attempt distribution, play heatmap) exists or is derivable but unshown.

## Design
Expand StatsView: best-time trend, star distribution, a 7/30-day play heatmap from playedDays.

## Implementation steps
- Hand-rolled SwiftUI charts (bars/heatmap) — no heavy deps; single-palette.
- Pull from ProgressStore (playedDays, levelProgress, averageTime).
- Accessible summaries for VoiceOver.

## Acceptance criteria
- Stats shows distribution + a play heatmap.
- Reads real data.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
