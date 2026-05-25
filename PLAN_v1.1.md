# PLAN v1.1 — Bug Fix + Stitch Design Refactor

_Date: 2026-05-25 | Branch: feature/IOS-53-v1-1-bug-fix-stitch-design-refactor_

---

## Whiteboard Summary

The whiteboard (felabs-whiteboard-1779640648643.png) diagrams the full v2 app flow:

```
Levels (Duolingo style) → Daily Puzzle → Ana Ekran → Leaderboard (Game Center) → Profile
```

**Main menu 3 CTA:** Play, Tutorial, Store

**Game flow:**
Ana Ekran → Set seçimi → Oyun ekranı →
- Tebrikler popup: Next Level / Try Again / Return Home
- Fail popup: Try Again / Return Home

**v1.1 SCOPE (this task):** Bug fixes + Stitch design alignment
**v1.2 BACKLOG (do NOT implement):**
- Game Center Leaderboard screen
- Profile tab
- Separate Tutorial screen
- Fail state (distinct from LevelCompleteSheet)
- Daily Puzzle as separate entry point in nav

---

## Stitch Screenshots Observed

| File | Size | Key observations |
|------|------|-----------------|
| shop.png | 38K | "Snuglo Plus" featured card lavender, hints grid, tab bar |
| pause.png | 13K | Clean white card dialog, lavender primary CTA, secondary outlines |
| stats.png | 18K | 4 KPI cards, bar chart, donut, Space Grotesk numbers |
| packdetail.png | 46K | Hero photo + "Morning Dew", 3-col level grid with star ratings |
| settings.png | 22K | Clean list rows, lavender toggles, accordion sections |

---

## Bug Audit Results

| # | Bug | Severity | Status |
|---|-----|----------|--------|
| 1 | AppRouter.selectTab() called popToRoot() — tab switching unwound to Splash | BLOCKER | ✅ Fixed (uncommitted, keep) |
| 2 | GameView viewModel re-init on onAppear → brief flash of wrong level | IMPORTANT | ✅ Fixed (uncommitted, keep) |
| 3 | MainMenuView: hardcoded "Level 12" + PackProvider.dailyPuzzle() called on every render | IMPORTANT | ✅ Fixed (uncommitted, keep) |
| 4 | SplashView task leak: async task not stored/cancelled on disappear | IMPORTANT | Fix in this task |
| 5 | GameView PauseSheet swipe-to-dismiss does NOT restart timer | IMPORTANT | Fix in this task |
| 6 | SettingsView: showNotifDeniedAlert never triggered — denial silently ignored | IMPORTANT | Fix in this task |
| 7 | GameView HUD timer uses hardcoded .system(size:14,...) instead of AppTypography.numericLabel | NITPICK | Fix (token alignment) |
| 8 | GridView: grid background surfaceContainerLow ≠ Stitch game board #F2EBE0 | NITPICK | Fix (design) |
| 9 | GridView: grid lines 1pt outlineVariant ≠ Stitch #E5DCC8 @1.5px | NITPICK | Fix (design) |
| 10 | LevelCompleteSheet: success circle bg primaryContainer ≠ Stitch blush #F5E6E0 | NITPICK | Fix (design) |
| 11 | Custom fonts not registered (BLOCKER-07 since Faz B) | IMPORTANT | Fix in this task |
| 12 | Info.plist custom (BLOCKER-01 partial): UILaunchScreen.UIColorName cannot use GENERATE_INFOPLIST | IMPORTANT | Fix in this task |

---

## Design Refactor Scope

### 7a Foundation
1. Font registration: Plus Jakarta Sans (variable), Be Vietnam Pro (static ×2), Space Grotesk (variable)
2. Colors.swift: add gameBoardBackground, gridLine, blushAccent, divider, softCocoa tokens
3. Typography.swift: Font.custom + UIFontDescriptor variation for all 7 Stitch tokens
4. Create custom Info.plist (fixes UILaunchScreen + UIAppFonts)
5. Update project.yml: add Fonts resource, switch to custom Info.plist

### 7b Reusable Components
- PrimaryButton (lavender bg, scale press)
- SecondaryButton (white + divider border)
- CardSurface ViewModifier (radius 20 + shadow)
- RowDivider (1px divider color)

### 7c Screens
- GameView: gameBoardBackground grid, gridLine 1.5px, HUD timer font
- GridView: game board colors
- PauseSheet: match Stitch screenshot (clean dialog, no toggles)
- LevelCompleteSheet: blushAccent circle
- Stats: Space Grotesk for KPI numbers
- Settings: minor token alignment
- MainMenu, PackDetail, Shop, LevelsList, Splash, RootView: incremental token updates

### 7d Tests
- No new tests required (font/color are visual, engine tests unchanged)
- Ensure existing 20+ tests still pass

---

## Risk Register

| Risk | Mitigation |
|------|-----------|
| Variable font rendering on iOS Simulator | UIFontDescriptor variation fallback documented; system font still renders if font not found |
| Info.plist migration breaks build | Keep INFOPLIST_KEY_* as build settings comments; Info.plist keys replicate all needed values |
| xcodegen pbxproj conflicts | Run xcodegen generate after all file changes; commit resulting pbxproj |
| BLOCKER-01 UILaunchScreen fix might break launch | LaunchBackground.colorset already in Assets.xcassets; only needs plist plumbing |

---

## File Change List

### New files
- `SnugloApp/Info.plist`
- `SnugloApp/Resources/Fonts/PlusJakartaSans-Regular.ttf`
- `SnugloApp/Resources/Fonts/BeVietnamPro-Regular.ttf`
- `SnugloApp/Resources/Fonts/BeVietnamPro-Medium.ttf`
- `SnugloApp/Resources/Fonts/SpaceGrotesk-Regular.ttf`
- `SnugloApp/Core/Components/PrimaryButton.swift`
- `SnugloApp/Core/Components/SecondaryButton.swift`
- `SnugloApp/Core/Components/CardSurface.swift`
- `SnugloApp/Core/Components/RowDivider.swift`

### Modified files
- `SnugloApp/project.yml` (Fonts resource, custom Info.plist)
- `SnugloApp/Core/Theme/Colors.swift` (5 new Stitch tokens)
- `SnugloApp/Core/Theme/Typography.swift` (Font.custom)
- `SnugloApp/Features/Game/GridView.swift` (Stitch game board)
- `SnugloApp/Features/Game/GameView.swift` (bug fix + HUD font)
- `SnugloApp/Features/Splash/SplashView.swift` (task cancel bug fix)
- `SnugloApp/Features/Settings/SettingsView.swift` (notif denial bug fix)
- `SnugloApp/Features/Pause/PauseSheet.swift` (Stitch redesign)
- `SnugloApp/Features/LevelComplete/LevelCompleteSheet.swift` (blush accent)
- `SnugloApp/Features/Stats/StatsView.swift` (numericLabel)
- All other screens: minor token updates
- `CHANGELOG.md` (v1.1 entry)
- `BLOCKERS.md` (✅ resolved + v1.2 backlog)

---

## v1.2 Backlog (do NOT implement in v1.1)

- Game Center Leaderboard integration
- Profile screen / tab
- Tutorial screen (separate from onboarding)
- Fail/lose state (vs success state)
- Real audio assets (wav/mp3 files)
- Real app icon (1024×1024 final art)
- Real AdMob SDK
- Native speaker TR/ES review
- Real font if variable font rendering issue found on-device
