# 01 · Solve Celebration — Confetti & Win Juice

**Rank:** 1 / 20  **Status:** DONE ✅  **Slug:** `solve-celebration`

## Research basis
Game feel/juice drives dopamine & retention; 'dopamine-triggering particle effects' & 'satisfying feedback loops' (Fruit Merge, juice-genre research).

## Problem / Why it matters
Solving a level currently plays a wave + opens the complete sheet. There is no celebratory burst — the single most cited 'satisfying' moment is under-delivered.

## Design
On solve, fire a short confetti/particle burst overlay (warm AppColors palette) + a star/title pop, then the existing flow. Respect Reduce Motion (static sparkle fallback).

## Implementation steps
- New `SolveCelebration.swift`: TimelineView + Canvas particle burst (gravity, fade), single-palette colors, allowsHitTesting(false).
- GameView: `@State showCelebration`; trigger in `onChange(isSolved)`; auto-stop ~1.8s; gate on !reduceMotion (else a brief sparkle).
- Layer above board, below the LevelComplete cover.

## Acceptance criteria
- Solving a level shows a confetti burst then the complete sheet.
- No layout shift / input capture.
- Reduce Motion → no falling particles.
- Build green.

## Constraints (always)
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green (generic/platform=iOS) before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
