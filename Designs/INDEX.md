# Snuglo — Design Index (Stitch import)

Source: Stitch project **"Snuglo Puzzle Game UI Kit"** (`projects/15600773873971770463`).
Design system: **Nordic Hearth** (Hygge, soft minimalism, tactile modernism).
Imported: 2026-05-25.

## Design System Tokens (Nordic Hearth)

**Colors (light theme):**
- Background / surface: `#FDF8FB` (warm off-white, paper-like)
- Surface containers: `#F8F2F5` → `#F2ECF0` → `#ECE7EA` → `#E6E1E4` (tonal layering)
- Primary (Lavender CTA): `#65587A`, hover/pressed darker by 5%
- Primary container: `#C5B5DC`
- On-primary: `#FFFFFF`
- Secondary: `#675C58` (cocoa)
- Tertiary: `#665F31` (warm olive)
- Text on surface: `#1C1B1D` (deep cocoa, never pure black)
- On-surface-variant: `#49454D`
- Outline: `#7A757E` / `#CBC4CE`
- Error: `#BA1A1A`

**Block fills (game pieces):** Soft pastels — lavender, sage, peach/blush, cream, dusty olive (see screenshots 06, 08 for reference).

**Typography:**
- Headlines: **Plus Jakarta Sans** (SF Rounded substitute) — 28/22/18 px, weight 600, letter-spacing −0.02em
- Body: **Be Vietnam Pro** (SF Pro substitute) — 17/15 px, weight 400
- Numeric (timers, scores): **Space Grotesk** (SF Mono substitute) — 20 px, weight 500
- Labels: Be Vietnam Pro 12 px, weight 500, letter-spacing 0.05em, UPPERCASE
- Body color: NEVER pure black; use `#3A332D` (soft cocoa)

**Shapes:**
- Primary cards: 20 px radius (modals, scoreboards)
- Buttons: 14 px radius ("softer than standard")
- Game blocks: 10 px radius
- Icons: 1.5 px stroke, round caps & joins

**Spacing:** 4 px baseline. Screen margin 24 px, internal padding 16 px, stacks 8/16/32.

**Elevation:** Tonal layering, never harsh shadows.
- L0 background: `#FDF8FB`
- L1 cards/board: `#FFFFFF` + ambient glow shadow `0px 4px 12px rgba(58, 51, 45, 0.06)`
- L2 active blocks: 0.5 px white-50% inner stroke on top edge (bevel)
- Picked-up block: shadow opacity 0.12, scale 1.10×

**Bottom tab bar:** 4 tabs — `PLAY · LEVELS · STATS · SHOP`. Active tab uses lavender pill background + icon tint.

## Screen Manifest

| # | Title | HTML | Screenshot | Purpose / Notes |
|---|-------|------|------------|----------------|
| 01 | Splash | `html/01-splash.html` | `screenshots/01-splash.png` | App boot screen. Tiny 4×4 pastel block logo + "Snuglo" wordmark, centered. Shows for ~1.2 s while engine/levels hydrate. |
| 02 | Onboarding | `html/02-onboarding.html` | `screenshots/02-onboarding.png` | 3-page intro (page indicator dots). Hero image: pastel blocks on cream surface. Headline "Welcome to Snuglo" / subtitle "A cozy puzzle to fit your day". `Skip` link top-right. |
| 03 | Main Menu | `html/03-main-menu.html` | `screenshots/03-main-menu.png` | Home tab. Top: settings (⚙) / "Snuglo" / shop bag (🛍). Level pill "Level 12 / 240". **Daily Puzzle** card (date stamp, hero artwork, countdown "Refresh in 4h 12m", play ▶ CTA). **Continue** card (pack thumbnail, pack name "Woodland Retreat", level number, lavender progress bar 65%). Bottom tab bar. |
| 04 | Levels List | `html/04-levels-list.html` | `screenshots/04-levels-list.png` | LEVELS tab. Title "Levels" / subtitle "Pick a pack". Cards: **Cozy Beginnings 5×5** (18/30 done), **Spice Route 6×6** (4/30), **Mambo Nights 7×7** (locked padlock). Each card: name, grid badge, progress bar, completion ratio, lavender pack icon tile. |
| 05 | Pack Detail | `html/05-pack-detail.html` | `screenshots/05-pack-detail.png` | Tapping a pack. Hero banner "Morning Dew" (BEGINNER label, progress 9/30). 3-column grid of level tiles: completed (number + ⭐⭐⭐), current (highlighted border), locked (🔒). Back arrow + overflow menu. |
| 06 | Game Play | `html/06-game-play.html` | `screenshots/06-game-play.png` | Active level. Top bar: back arrow / level name "Mambo" / timer ⏱ "01:13". Board: 6×6 grid, soft cream cells, placed pieces (lavender/sage/peach/cream) with size-number label. Bottom tray: 2 remaining pieces. Lavender hint button bottom-right with badge (count remaining). |
| 07 | Pause Overlay | `html/07-pause-overlay.html` | `screenshots/07-pause-overlay.png` | Modal over dimmed game (50% dark overlay). Card: "Paused" / ⏱ 00:01:13 / Resume (primary lavender CTA) / Restart (outlined) / Home (outlined). |
| 08 | Level Complete | `html/08-level-complete.html` | `screenshots/08-level-complete.png` | Modal after solve. "✓" badge with soft glow, "Level complete!" headline, mini grid recap, stat row (TIME 02:45 / STARS ⭐⭐⭐ / HINTS 0), **Next level →** primary CTA, Replay / Home secondary actions. Floating confetti particles (dots). |
| 09 | Stats | `html/09-stats.html` | `screenshots/09-stats.png` | STATS tab. Title "Your Stats". 2×2 KPI grid: **SOLVED 142** / **TIME 48h** / **FASTEST 1:12** / **STREAK 14d** (each with small icon). **Solves per day** weekly bar chart (M-S, current day highlighted lavender, others muted blush). **Hint usage** donut chart "1.2 per game" with legend (No hints / 1-2 / 3+). |
| 10 | Shop | `html/10-shop.html` | `screenshots/10-shop.png` | SHOP tab. Title "Shop" / subtitle "Enhance your cozy experience". **Snuglo Plus** card (lavender) — "Ad-free meditative experience / Unlimited daily hints / Exclusive pastel themes" + Subscribe $4.99/mo CTA. **Hints** horizontal cards: 5 hints $0.99 / 25 hints $2.99 (POPULAR badge) / Unlimited. **Remove Ads** one-time $3.99 row. |
| 11 | Settings | `html/11-settings.html` | `screenshots/11-settings.png` | Push screen (from gear icon). Sections: **SOUND & FEEL** (Music toggle / Sound effects toggle / Haptics toggle, each with circular icon badge). **APPEARANCE** (Theme → "System Default" disclosure). **NOTIFICATIONS** (Daily Reminder toggle + Reminder Time row "8:00 PM"). **ACCOUNT** (Restore Purchases / Privacy Policy / Terms of Service rows). Footer: "SNUGLO V1.0.4". |

## Game Mechanic Confirmation

- **Goal:** Fill the grid completely with rectangular pieces. No overlap, no gaps. (Matches `SNUGLO_SPEC.md`.)
- **Pieces carry a numeric label** equal to their cell count (1/2/3/…). Useful for accessibility (also color-blind friendly).
- **Timer:** Counts UP from 00:00 during play (game.png shows 01:13 elapsed). On Pause overlay it's frozen.
- **Stars:** 0–3 per level. Awarded by speed/efficiency (no hint = ⭐⭐⭐ visible in `08-level-complete.png`).
- **Hints:** Limited resource. Track per-game usage (stats donut), purchasable (5/25/Unlimited via Shop).
- **Daily Puzzle:** One specific puzzle per calendar day, refreshes at local midnight, shown on Main Menu with countdown.
- **Streak:** Consecutive days completing the daily puzzle.

## Content Confirmation

- **Total levels:** 240 (Main Menu shows "Level 12 / 240"). 8 packs × 30 levels OR 4 packs × 60 levels — implementer to confirm from PLAN_v0.2.md / spec.
- **Known pack names:** Cozy Beginnings (5×5), Spice Route (6×6), Mambo Nights (7×7), Woodland Retreat (named on Main Menu "Continue" card; level 12 — likely an 8×8 advanced pack), Morning Dew (BEGINNER hero — possibly an early sub-pack inside Cozy Beginnings, or pack subtitle).

## Implementation Notes for SwiftUI

- All screens are 390 × 844 (iPhone 13/14/15 logical). Test on iPhone SE (375 × 667) for `headline-lg` reflow.
- Replace Google Web fonts with **SF Rounded / SF Pro / SF Mono** (system fonts):
  - Plus Jakarta Sans → `Font.system(size: …, weight: .semibold, design: .rounded)`
  - Be Vietnam Pro → `Font.system(size: …, weight: .regular, design: .default)`
  - Space Grotesk → `Font.system(size: …, weight: .medium, design: .monospaced)`
- Use `Material.regular` or `.ultraThin` only sparingly; the design favors solid surfaces with subtle shadows over glass.
- All radii, spacings, and colors are tokenized — extend `SnugloApp/Core/Theme/Colors.swift` and `Spacing.swift` to add the new tokens (`primaryContainer`, `surfaceContainer*`, `outlineVariant`, `shadowAmbient`, etc.).
