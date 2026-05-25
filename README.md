# Snuglo

Cozy block-logic puzzle game for iOS — drag pastel blocks onto a grid, solve at your own pace, no timer pressure.

## Highlights
- **240 levels** across 4 packs (Cozy Beginnings 5×5 → Spice Route 6×6 → Mambo Nights 7×7 → Woodland Retreat 8×8)
- **Daily Puzzle** with deterministic date-seeded levels
- **Nordic Hearth design system** — warm pastels, soft cocoa text, lavender CTAs
- **3 locales** — English, Türkçe, Español
- **Light & Dark mode**
- **VoiceOver + Dynamic Type** accessibility
- **StoreKit 2 IAP** — 3 pack unlocks, Remove Ads, Hint consumable
- **Audio + Haptics** with user-controlled toggles
- **Daily reminder** local notification

## Project structure
- `Sources/SnugloEngine/` — Swift package: domain models, level generator (Voronoi BFS), solution checker, daily puzzle
- `SnugloApp/` — SwiftUI iOS app target
  - `App/` — entry point, AppRouter (NavigationStack)
  - `Core/Theme/` — Nordic Hearth design tokens
  - `Core/Persistence/` — ProgressStore (@Observable + UserDefaults)
  - `Core/Audio,Haptics,Notifications,Store,Ads/` — managers
  - `Features/{Splash,Onboarding,MainMenu,LevelsList,PackDetail,Game,Pause,LevelComplete,Stats,Shop,Settings,Navigation}/` — 11 screens
  - `MockData/` — Pack + LevelItem + PackProvider bridge
  - `Resources/` — Localizable.strings (en/tr/es), launch screen, app icon
- `Tests/` — engine + app unit tests (66 tests)
- `Designs/` — design system spec + HTML mockups
- `.swiftlint.yml` — 0-warning lint config

## Requirements
- Xcode 15+
- iOS 18.0+
- xcodegen + swiftlint (`brew install xcodegen swiftlint`)

## Build
```
cd SnugloApp
xcodegen generate
open SnugloApp.xcodeproj
```
Or via SPM:
```
swift build
swift test
```

## CI
GitHub Actions workflow (`.github/workflows/ci.yml`) ships with v1.0.0 — macOS-15 runner, `swiftlint --strict` + `swift test` + `xcodebuild build`.

## Roadmap
v1.0 ships as a complete cozy puzzle. Future versions:
- v1.1 — Real AdMob integration (replace placeholder)
- v1.1 — Final audio asset delivery
- v1.1 — Final app icon art
- v1.2 — More packs, daily streak rewards

## License
TBD (Faz J — to be filled before launch).
