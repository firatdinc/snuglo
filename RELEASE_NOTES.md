# Snuglo v1.0.0 — Release Notes

## What's new
First production-ready release of Snuglo.

## Core features
- 240 hand-tuned puzzles across 4 thematic packs
- Daily Puzzle with date-deterministic seeds and 7-day streak tracking
- Drag-and-drop block placement with snap-to-grid and pickup haptics
- Full progress persistence via UserDefaults; "Reset Progress" in Settings
- Stats screen with KPI cards (levels completed, current streak, daily solved, avg time), pack completion donut, and last-7-days bar chart
- 5 IAP SKUs: 3 pack unlocks (Spice Route, Mambo Nights, Woodland Retreat), Remove Ads, Hints pack (10 hints)
- Sound effects + background music + haptics (all togglable in Settings/Pause)
- Daily reminder local notification with customizable time
- Light / Dark / System appearance picker
- Localizations: English, Türkçe, Español

## Quality
- 66 unit tests across engine + app
- SwiftLint clean (0 warnings, strict)
- Accessibility: VoiceOver labels on all interactive elements; Dynamic Type support; Reduce Motion guards on celebratory animations

## Known limitations (v1.1 targets)
- AdMob integration uses a placeholder presenter — real Google Mobile Ads SDK swap-in is pre-launch
- App icon is a placeholder — final art-2d delivery pending
- Audio asset bundle is empty — sound-designer delivery pending; AudioManager no-ops gracefully
- XCUITest target not yet committed — UI smoke runs in CI prep
- Personalized ads consent uses ATTrackingManager; production needs final NSUserTrackingUsageDescription copy review

## Compatibility
- Minimum iOS: 18.0
- Architectures: arm64 (device), arm64 + x86_64 (simulator)
- Languages: en, tr, es
