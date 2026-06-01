# Snuglo — 20-Feature Autonomous Build (loop state)

This file is the **single source of truth** for the autonomous loop. It survives
chat compaction. On each wakeup, read this, do the next PENDING feature, mark it
DONE, commit+push, then schedule the next wakeup (~270s). When all 20 are DONE,
run **step 21** (HTML report) and STOP.

## Ranking & status

| # | Feature | Spec | Status |
|---|---------|------|--------|
| 1 | Solve Celebration (confetti/juice) | `01-solve-celebration.md` | DONE ✅ |
| 2 | Combo Multiplier & pop | `02-combo-scoring.md` | PENDING |
| 3 | Visual Placement Hint | `03-visual-hint.md` | PENDING |
| 4 | Unlockable Block Skins | `04-block-skins.md` | PENDING |
| 5 | Streak Milestone Rewards | `05-streak-milestones.md` | PENDING |
| 6 | Weekly Rotating Challenge | `06-weekly-challenge.md` | PENDING |
| 7 | Endless Zen Mode | `07-endless-zen.md` | PENDING |
| 8 | Discard / Trash a Piece | `08-trash-discard.md` | PENDING |
| 9 | Share Result Card | `09-share-card.md` | PENDING |
| 10 | Stats Deep-Dive | `10-stats-deepdive.md` | PENDING |
| 11 | Color-Blind Pattern Mode | `11-colorblind-patterns.md` | PENDING |
| 12 | Cozy Board Backgrounds | `12-board-backgrounds.md` | PENDING |
| 13 | Sound Pack Selection (ASMR) | `13-sound-packs.md` | PENDING |
| 14 | Achievement Unlock Toasts | `14-achievements-toast.md` | PENDING |
| 15 | 30-Day Daily Reward Calendar | `15-daily-calendar.md` | PENDING |
| 16 | Interactive First-Level Tutorial | `16-onboarding-interactive.md` | PENDING |
| 17 | Resume In-Progress Puzzle | `17-resume-puzzle.md` | PENDING |
| 18 | Granular Motion & Effects Settings | `18-motion-settings.md` | PENDING |
| 19 | Alternate App Icons | `19-alt-app-icons.md` | PENDING |
| 20 | Ambient Music Tracks | `20-ambient-music.md` | PENDING |
| 21 | **HTML feature report** | `report.html` | PENDING |

## Loop protocol (do this each wakeup)
1. Read this file → find the first PENDING row.
2. Read its spec MD. Implement fully in `~/Desktop/snuglo`.
3. `cd SnugloApp && xcodegen generate && xcodebuild build ... ` → MUST be `BUILD SUCCEEDED`.
   (SourceKit "No such module" diagnostics are false positives — only the build counts.)
4. Mark the row DONE here (and set the spec's Status: DONE). Add a one-line note in the log below.
5. `git add -A && git commit` (message: `feat(NN): <feature>`) and `git push`.
6. If more PENDING remain → `ScheduleWakeup` ~270s with the loop prompt.
   If feature 20 just finished → do step 21 (build `features/report.html`, a clean
   futuristic UI summarizing all 20 features + advantages), commit+push, then STOP
   (no further wakeup).
7. If context is heavy, `/compact` is fine — this file holds all state.

## Build command
```
cd ~/Desktop/snuglo/SnugloApp && xcodegen generate && \
xcodebuild build -project SnugloApp.xcodeproj -scheme SnugloApp \
  -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Log
- (init) Specs created, ranking set. Starting feature 1.
- #1 Solve Celebration: SolveCelebration.swift (confetti TimelineView+Canvas) wired in GameView onSolve; Reduce-Motion gated; BUILD SUCCEEDED.
