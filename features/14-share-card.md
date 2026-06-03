# 14 · Share Result Card

**Rank:** 14 / 20  **Status:** DONE ✅  **Slug:** `share-card`

## Market / competitor basis (research)
Social sharing drives organic growth/virality; standard in top casual titles.

## Why it makes the game more addictive / juicy
Shareable wins bring new users & add pride/identity.

## Design
On level complete, a Share button renders a branded result card (level/time/stars/streak) via ImageRenderer + ShareLink.

## Implementation steps
- ResultCard SwiftUI view (branded, single-palette).
- ImageRenderer→UIImage; ShareLink in LevelCompleteSheet.

## Acceptance criteria
- Share exports a clean result image; share sheet appears.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
