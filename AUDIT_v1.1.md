# Faz K — Audit v1.1 Stitch Refactor Status

_Date: 2026-05-26 | Branch: feature/IOS-54-v1-1-failed-items-cleanup-fix_

## Methodology

Each screen's Swift source was scanned for:
1. `.font(.system(...))` on **Text** views (must be `AppTypography`) vs on **Image(systemName:)** (icon sizing — acceptable)
2. Inline button patterns matching `PrimaryButton`/`SecondaryButton` signatures
3. Inline card surface patterns matching `CardSurface` modifier (`.surfaceContainerLowest` + radius `AppRadius.card` + `outlineVariant.opacity(0.3)` stroke + `shadowL1()`)
4. Hex literal colors (must use `AppColors` tokens)

## Baseline

- `swift test` → 66/66 passing
- `xcodebuild build` (iPhone 17, iOS 26.3.1) → exit 0
- `grep '\.system('` in features → 35 hits, **0 on Text views** (all on `Image(systemName:)`)
- `grep 'Color(hex:'` in features → 0 hits
- `grep 'PrimaryButton('` in features → **0 hits** (component exists, never imported)
- `grep 'SecondaryButton('` in features → **0 hits** (same)
- `grep 'CardSurface\|.cardSurface'` in features → **0 hits**

## Screen Audit

| # | Screen | File | Status | Gaps |
|---|--------|------|--------|------|
| 01 | Splash | `SplashView.swift` | ✅ Full | None — uses tokens, no inline buttons, decorative logo grid |
| 02 | Onboarding | `OnboardingView.swift` | 🟡 Partial | "Next" / "Get Started" CTA inline → `PrimaryButton` |
| 03 | Main Menu | `MainMenuView.swift` | 🟡 Partial | `dailyPuzzleCard` + `continueCard` use inline card pattern → `.cardSurface()` |
| 04 | Levels List | `LevelsListView.swift` | 🟡 Partial | Pack rows use inline card pattern → `.cardSurface()` |
| 05 | Pack Detail | `PackDetailView.swift` | 🟡 Partial | Hero card / level tile cells use inline card pattern |
| 06 | Game Play | `GameView.swift` | ✅ Full | HUD timer pill uses tokens; back/pause buttons are SF Symbol icon buttons (no inline CTA) |
| 07 | Pause Overlay | `PauseSheet.swift` | 🟡 Partial | 3 inline buttons: Resume → `PrimaryButton`, Restart + Home → `SecondaryButton` |
| 08 | Level Complete | `LevelCompleteSheet.swift` | 🟡 Partial | "Next" inline → `PrimaryButton`; Replay + Home are smaller secondary actions (lavender outlined, keep as-is or wrap in lighter helper) |
| 09 | Stats | `StatsView.swift` | 🟡 Partial | KPI cards + pack progress section + chart section + donut section all use inline card pattern → `.cardSurface()` |
| 10 | Shop | `ShopView.swift` | 🟡 Partial | Snuglo Plus / Hint pack cards use inline card pattern; Subscribe CTA inline — confirm during refactor |
| 11 | Settings | `SettingsView.swift` | 🟡 Partial | Section cards use inline card pattern; rows could optionally use `RowDivider` |

## Dead Code

- `Features/Game/PauseOverlayView.swift` — defined but never referenced (`grep -rln "PauseOverlayView"` returns only the file itself). Out of v1.1 DoD scope; flag in BLOCKERS for v1.2 deletion.

## Refactor Plan (Faz L — order of attack)

Smallest, highest-confidence changes first:

1. **PauseSheet** — 3 buttons (Resume → Primary, Restart + Home → Secondary). Mechanical replacement, exact signature match. ~50 LOC delta.
2. **LevelCompleteSheet** — 1 button (Next → Primary). Replay/Home are intentionally smaller outlined CTAs per Stitch — leave inline.
3. **OnboardingView** — 1 button (Get Started / Next polymorphic → Primary).
4. **CardSurface rollout** — apply `.cardSurface()` to 6 screens with the inline pattern:
   - StatsView (4 sections)
   - MainMenuView (2 cards)
   - LevelsListView (pack rows)
   - PackDetailView (hero + tiles)
   - ShopView (offer cards)
   - SettingsView (section groups)

Each refactor: edit → `swift test` → commit → next.

## DoD Mapping

| # | DoD Item | Status After Audit |
|---|----------|--------------------|
| 1 | 11 ekran auditi tamam — `Designs/INDEX.md` ile birebir | ✓ (this doc) |
| 2 | `Typography.swift` custom font'lar | ✓ (already true) |
| 3 | Tüm CTA'lar `PrimaryButton`/`SecondaryButton` kullanır | ⏳ Faz L tasks 1-3 |
| 4 | `swift test` 0 fail | ✓ baseline; preserve through refactor |
| 5 | `xcodebuild` temiz (iPhone 17, iOS 26.3.1) | ✓ baseline; preserve |
| 6 | `CHANGELOG.md` v1.1.0 entry | ⏳ Faz N |
| 7 | v1.1.0 annotated tag | ⏳ Faz N |
