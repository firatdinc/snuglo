# 16 · Interactive First-Level Tutorial

**Rank:** 16 / 20  **Status:** PENDING  **Slug:** `onboarding-interactive`

## Research basis
Guided onboarding boosts new-user retention (progressive difficulty research).

## Problem / Why it matters
Onboarding is static; first real interaction (drag a piece) isn't guided.

## Design
An interactive coach mark on the first level: a pulsing hand prompts the first drag, dismissed on success.

## Implementation steps
- Detect first-ever level via a flag; overlay a coach hand + tooltip.
- Dismiss when the player places the first piece.
- Respect Reduce Motion.

## Acceptance criteria
- First-ever level shows a guided drag prompt.
- Shown once.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
