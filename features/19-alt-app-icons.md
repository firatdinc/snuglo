# 19 · Alternate App Icons

**Rank:** 19 / 20  **Status:** PENDING  **Slug:** `alt-app-icons`

## Research basis
Personalization & a light prestige reward; standard iOS feature, no provisioning needed.

## Problem / Why it matters
Single app icon — no personalization or unlock reward surface.

## Design
Offer 3–4 alternate app icons selectable in Settings via setAlternateIconName.

## Implementation steps
- Add alternate icon image sets + Info.plist CFBundleAlternateIcons (xcodegen project settings).
- Settings picker calling UIApplication.setAlternateIconName.
- Graceful handling if unsupported.

## Acceptance criteria
- Selecting an icon changes the home-screen icon.
- Persists (system).
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
