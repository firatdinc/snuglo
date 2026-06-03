# 17 · Stats Deep-Dive

**Rank:** 17 / 20  **Status:** DONE ✅  **Slug:** `stats-deepdive`

## Market / competitor basis (research)
Completionists value rich stats; mastery dashboards deepen engagement.

## Why it makes the game more addictive / juicy
Self-competition (beat your bests) sustains long-term play.

## Design
Expand StatsView: best-time trend, star distribution, 7/30-day play heatmap from playedDays.

## Implementation steps
- Hand-rolled SwiftUI charts (no deps, single-palette).
- Pull from ProgressStore; VoiceOver summaries.

## Acceptance criteria
- Stats shows distribution + play heatmap from real data.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
