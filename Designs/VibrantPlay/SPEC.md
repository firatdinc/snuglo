# Vibrant Play — Snuglo redesign spec (from Stitch)

Source: Stitch project "Snuglo Puzzle Game UI Kit" → design system "Vibrant Play".
Each screen below has a screenshot (PNG) in this folder = the visual target.
`main-menu.html` is the raw Stitch HTML for one screen (layout/spacing reference).

## Design tokens (Vibrant Play)
- **Background:** `#f4faff` (very light blue). Card/surface: `#ffffff`.
- **Primary (CTA blue):** `#30A7E7`; pressed/darker `#2589C1` / `#006591`; light tints `#89ceff` `#c9e6ff`.
- **Secondary / accent (gold):** `#FFB800`; variants `#D99C00` `#feb700` `#ffdea8`.
- **Text:** `#141d21` (near-black, NOT pure). Borders / dim: `#dbe4ea` `#e0e9ef` `#d2dbe1`.
- **Error:** `#ffdad6`.
- **Font:** Plus Jakarta Sans (headings + body). Icons: Material Symbols Outlined (→ map to SF Symbols on iOS).
- **Shapes:** large rounded cards (~20px), pill-shaped primary buttons, rounded block tiles, soft shadows.
- **Chrome:** bottom tab bar — **Play · Levels · Stats · Shop**. Playful 3D mascots (hippo/sloth) per screen.

This is a big departure from the current **Nordic Hearth** theme (warm pastels, lavender `#65587a`, cocoa text). Vibrant Play = bright, energetic, kid-friendly.

## Screen → Snuglo mapping
| PNG | Snuglo screen (`Features/`) | Notes |
|-----|------------------------------|-------|
| `splash.png` | Splash | restyle |
| `onboarding.png` | Onboarding | restyle |
| `main-menu.png` | MainMenu | **NEW chrome:** bottom tab bar, "Daily Challenge" hero banner, Daily-Activity streak. ⚠️ also shows a **language-lesson list (English/German/…)** that does NOT fit a block-puzzle game — Stitch hallucinated this from the user's Duolingo references. |
| `levels-list.png` | LevelsList | restyle |
| `level-map.png` | LevelsList / PackDetail | island map style |
| `game-play.png` | Game | block puzzle restyled — grid, colored block tiles, tray, **Hint** (already shipped IOS-58), progress bar, mascot, timer |
| `level-complete.png` | LevelComplete | restyle |
| `stats.png` | Stats | restyle |
| `shop.png` | Shop | restyle |
| `settings.png` | Settings | restyle |

## ⚠️ Content-vs-app mismatch to resolve before building
The Game screen is correctly the block puzzle, but the Main Menu mixes in
language-learning content (lessons/languages) that does not belong in Snuglo.
Decide scope:
- **A. Pure visual restyle** — apply Vibrant Play tokens/shapes/mascots to Snuglo's existing puzzle screens; keep current content (packs/levels), ignore the language-lesson list.
- **B. Restyle + playful gamification** — A plus add bottom tab bar, daily-challenge hero banner, daily-activity streak (drop language lessons — incoherent for a puzzle).
- **C. Concept pivot** — turn Snuglo into a language-learning app (adopt lessons too) = effectively a new product.
