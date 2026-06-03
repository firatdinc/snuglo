# Snuglo — 20-Feature Autonomous Build (loop state)

Single source of truth for the autonomous loop. Survives chat compaction.
On each wakeup: do the next PENDING feature, build green, mark DONE, schedule the
next wakeup (~270s). When all 20 are DONE → step 21 (HTML report). Then STOP.

> **NO commit / NO push at any point.** The user reviews EVERYTHING at the end
> (all working-tree changes + the report) and pushes themselves. Just leave
> changes in the working tree. All features are competitor/market-demand driven,
> aimed at making the game juicier, more fun, and more addictive (longer sessions).

## Ranking & status

| # | Feature | Spec | Status |
|---|---------|------|--------|
| 1 | Solve Celebration (confetti/juice) | `01-solve-celebration.md` | DONE ✅ |
| 2 | Win-Streak Chain Bonus | `02-winstreak-chain.md` | DONE ✅ |
| 3 | Daily Quests | `03-daily-quests.md` | DONE ✅ |
| 4 | Reward Chests (variable reward) | `04-reward-chests.md` | DONE ✅ |
| 5 | Daily Spin Wheel | `05-spin-wheel.md` | DONE ✅ |
| 6 | XP & Player Level Progression | `06-xp-level.md` | DONE ✅ |
| 7 | Combo Placement Pops | `07-combo-pops.md` | DONE ✅ |
| 8 | Unlockable Block Skins | `08-block-skins.md` | DONE ✅ |
| 9 | Visual Placement Hint | `09-visual-hint.md` | DONE ✅ |
| 10 | Streak Milestone Rewards | `10-streak-milestones.md` | DONE ✅ |
| 11 | Endless Zen Mode | `11-endless-zen.md` | DONE ✅ |
| 12 | Weekly Rotating Challenge | `12-weekly-challenge.md` | DONE ✅ |
| 13 | Achievement Unlock Toasts | `13-achievements-toast.md` | DONE ✅ |
| 14 | Share Result Card | `14-share-card.md` | DONE ✅ |
| 15 | 30-Day Daily Reward Calendar | `15-daily-calendar.md` | DONE ✅ |
| 16 | Discard / Trash a Piece (→ Endless skip) | `16-trash-discard.md` | DONE ✅ |
| 17 | Stats Deep-Dive | `17-stats-deepdive.md` | DONE ✅ |
| 18 | Cozy Board Backgrounds | `18-board-backgrounds.md` | DONE ✅ |
| 19 | Color-Blind Pattern Mode | `19-colorblind-patterns.md` | DONE ✅ |
| 20 | Sound Pack Selection (ASMR) | `20-sound-packs.md` | DONE ✅ |
| 21 | **HTML feature report (Phase 1)** | `report.html` | DONE ✅ |

## Phase 2 — 10 UI improvements (after step 21, same loop)
Right after the Phase-1 report, CONTINUE the loop with 10 UI/visual-polish steps
to make the whole project look beautiful, premium & appealing ("alıcı"). Same
rules: research/market-driven, single-palette AppColors, Reduce-Motion safe,
build green, NO commit/push. At step 21 (when starting Phase 2) first CREATE specs
`features/ui-01..ui-10.md` (ranked) + add a Phase-2 table here, then implement one
per wakeup. Suggested scope (refine when specced): polished empty/loading states,
consistent spacing & typography scale audit, refined shadows/elevation, button &
press states, card/surface cohesion, animated tab bar, hero/header polish,
iconography consistency, micro-interactions, app-wide transitions. After ui-10,
extend `report.html` with a Phase-2 section, then STOP.

| UI# | Improvement | Spec | Status |
|-----|-------------|------|--------|
| u1 | Main Menu Hub Redesign (declutter) | `ui-01-mainmenu-hub.md` | DONE ✅ |
| u2 | Unified Reward Modal System | `ui-02-modal-system.md` | DONE ✅ |
| u3 | Cohesive Card System | `ui-03-card-system.md` | DONE ✅ |
| u4 | Typography & Spacing Audit | `ui-04-type-spacing.md` | DONE ✅ |
| u5 | Refined Shadows & Elevation | `ui-05-elevation.md` | DONE ✅ |
| u6 | Button & Press States | `ui-06-press-states.md` | DONE ✅ |
| u7 | Game HUD Polish | `ui-07-game-hud.md` | DONE ✅ |
| u8 | Empty/Loading/First-Run States | `ui-08-states.md` | DONE ✅ |
| u9 | Iconography Consistency | `ui-09-iconography.md` | DONE ✅ |
| u10 | App-Wide Transitions & Micro-interactions | `ui-10-transitions.md` | DONE ✅ |

## Loop protocol (each wakeup)
1. Read this file → first PENDING row.
2. Read its spec MD. Implement fully in `~/Desktop/snuglo` per the spec + constraints.
3. Build (command below) → MUST be `BUILD SUCCEEDED`. (SourceKit "No such module"
   diagnostics are FALSE positives — only the real build counts.)
4. Mark the row DONE ✅ here (+ the spec's Status). Append a one-line log entry.
5. **Do NOT commit or push.** Leave changes in the working tree.
6. If PENDING remain → `ScheduleWakeup` ~270s with the loop prompt.
   If feature 20 just finished → step 21: build `features/report.html` (clean,
   professional, futuristic UI summarizing all 20 shipped features + advantages),
   do NOT push, THEN begin **Phase 2**: create `features/ui-01..ui-10.md` specs +
   the Phase-2 table above, and `ScheduleWakeup` to continue (one UI step / wakeup).
   Only after ui-10 is done → extend `report.html` with a Phase-2 section, do NOT
   push, STOP, and tell the user everything is ready for review.
7. If context is heavy, `/compact` is fine — this file holds all state.

## Build command
```
cd ~/Desktop/snuglo/SnugloApp && xcodegen generate && \
xcodebuild build -project SnugloApp.xcodeproj -scheme SnugloApp \
  -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Log
- (init) Specs created; ranking set (competitor/market + addiction/juice focus).
- #1 Solve Celebration: SolveCelebration.swift confetti wired in GameView onSolve; Reduce-Motion gated; BUILD SUCCEEDED.
- (revision) Re-specced 2-20 toward addictive/juicy market-driven mechanics (win-streak, quests, chests, spin wheel, XP, etc.). Switched loop to NO commit/push — user reviews at the very end with the report.
- #2 Win-Streak Chain: ProgressStore winChain/recordWin/breakChain + chainCoinBonus; GameView solve grows chain + coin bonus + intensifies confetti; breaks on fail/quit/restart; HUD 🔥 chip. NO commit. BUILD SUCCEEDED.
- #3 Daily Quests: DailyQuestStore (own UserDefaults, 3 deterministic rotating quests, daily rollover); recordSolve hooked in GameViewModel.persistProgress; MainMenu quests card w/ progress bars + claim (coins/gems); EN/TR/ES. BUILD SUCCEEDED.
- #4 Reward Chests: ChestStore (own UserDefaults; fills every 5 solves; weighted random reward table) + recordSolve hook; MainMenu chest card (meter / Open) + ChestRevealOverlay (wiggle→burst→reveal, Reduce-Motion safe); EN/TR/ES. BUILD SUCCEEDED.
- #5 Daily Spin Wheel: SpinStore (own UserDefaults, once/day, weighted 8-segment table); SpinWheelOverlay (Canvas wedges, 3.3s ease-out spin to weighted index, reveal+confetti, Reduce-Motion lands instantly); MainMenu spin card; EN/TR/ES. BUILD SUCCEEDED.
- #6 XP & Level: XPStore (own UserDefaults, gentle curve, level-up coin reward) awarded on solve (20+stars*10); Profile XP card (level + bar); LevelUpOverlay on MainMenu when pending; EN/TR/ES. Fixed @MainActor on award (WalletStore.earn is main-isolated). BUILD SUCCEEDED.
- #7 Combo Pops: GameView registerCombo() on quick consecutive valid placements (<=2.5s) → floating 'Combo xN' pop + small coin bonus + selection haptic; breakCombo on invalid (via triggerInvalidFeedback); Reduce-Motion safe. BUILD SUCCEEDED.
- #8 Block Skins: 4 palettes in Colors.swift (Nordic/Candy/Ocean/Mono) + blockSkins meta (level-gated unlock); blockColor(for:) reads active skin from @AppStorage(blockSkin); Settings→Appearance skin selector (swatches, lock+Lv); EN/TR/ES. BUILD SUCCEEDED.
- #9 Visual Hint: GameViewModel.lastHintPieceID set on hint; GridView hintPieceID pulsing highlight; GameView onChange(hintsUsed) flashes the hinted piece ~1.7s (TimelineView pulse active for hint too); Reduce-Motion static glow. BUILD SUCCEEDED.
- #10 Streak Milestones: ProgressStore lastRewardedStreak (snapshot migration) + pendingStreakMilestone on crossing [3,7,14,30,60,100]; load() silent catch-up (no pop for pre-existing); MainMenu StreakMilestoneOverlay grants coins/gems on collect; EN/TR/ES. BUILD SUCCEEDED.
- #11 Endless Zen: makeFromPackProvider generates 'endless-N' via LevelGenerator (grid grows with N); GameView relaxed (no timer/fail) + auto-advance to endless-N+1 on solve; EndlessStore tracks best; persistProgress records best (no campaign inflate); MainMenu endless card; EN/TR/ES. BUILD SUCCEEDED.
- #12 Weekly Challenge: WeeklyChallengeStore (own UserDefaults, deterministic from week #, goal solve N/week, big coin+gem reward, weekly rollover); recordSolve hook; MainMenu weekly card w/ progress + claim; EN/TR/ES. BUILD SUCCEEDED.
- #13 Achievement Toasts: AchievementToast banner; GameView queues viewModel.newlyUnlockedAchievements (onChange) and pumps toasts (2.4s each, slide-from-top, selection haptic); GameViewModel.clearNewAchievements(); existing reward grant unchanged. BUILD SUCCEEDED.
- #14 Share Card: ResultCard (branded 340x460, stars/time/level/streak + mascot) rendered via ImageRenderer; LevelCompleteSheet ShareLink (rendered on .task); EN/TR/ES. BUILD SUCCEEDED.
- #15 Daily Calendar: DailyCalendarStore (own UserDefaults, 30-day cycle, escalating reward, missed-day reset); DailyCalendarView 30-cell grid (claimed/today/upcoming) + claim+confetti; MainMenu calendar card; EN/TR/ES (+common.close). BUILD SUCCEEDED.
- #16 Discard (ADAPTED): Snuglo is solve-all → discarding a tray piece breaks solvability. Kept the anti-frustration INTENT: Endless-only HUD 'skip/new puzzle' button (forward.end) discards the generated puzzle and loads the next. BUILD SUCCEEDED.
- #17 Stats Deep-Dive: StatsView gains a 30-day play heatmap (from playedDays) + star-distribution bars (from levelProgress); hand-rolled SwiftUI, single-palette, accessible; EN/TR/ES. BUILD SUCCEEDED.
- #18 Board Backgrounds: BoardBackground enum (parchment/dawn/forest/night, AppColors gradients); GridView.drawBackground paints active gradient (read live); Settings→Appearance board selector swatches; EN/TR/ES. BUILD SUCCEEDED.
- #19 Color-Blind Patterns: AppColors.blockColorIndex + blockGlyphs (unicode); BlockView+GridView draw a per-color glyph when colorblindMode on (resolve(Text)); Settings→Gameplay toggle; EN/TR/ES. Fixed resolve(Image)->resolve(Text). BUILD SUCCEEDED.
- #20 Sound Packs: SoundPack enum (classic/soft/crisp) reshapes SFX via volume+rate (enableRate); SoundService.play applies active pack; Settings sound-pack picker; EN/TR/ES. BUILD SUCCEEDED.
- PHASE 1 COMPLETE (20/20 + report.html). Phase 2 specced (ui-01..ui-10). Continuing with UI polish, NO commit/push.
- UI#1 Main Menu Hub: collapsed spin/calendar/chest into a single rewardsRail (icon tiles + availability dots); reordered to hero→rail→continue→quests→weekly→endless. Big declutter. BUILD SUCCEEDED.
- UI#2 Modal System: shared RewardModal (scrim+spring entrance+confetti) + RewardButton; refactored LevelUp & StreakMilestone overlays to RewardModal; unified Chest/Spin collect buttons to RewardButton. BUILD SUCCEEDED.
- UI#3 Card System: added .infoCard(accent:) modifier (padding+cardSurface+optional ring) in CardSurface.swift; refactored quests/weekly/xp cards to it for consistent padding/radius/elevation. BUILD SUCCEEDED.
- UI#4 Type/Spacing Audit: new views already use AppTypography for text + AppSpacing for layout (remaining .system sizes are intentional icons/Canvas/dense-grid). Extracted shared claimChip (quests+weekly) → consistent type/spacing, removed raw padding(5)→AppSpacing.xs. BUILD SUCCEEDED.
- UI#5 Elevation: added shadowL3() (deep modal lift) to the L1/L2 scale; applied to DailyCalendar card box + ConfirmDialog (replaced ad-hoc shadow). Consistent rest(L1)/drag(L2)/overlay(L3) scale. BUILD SUCCEEDED.
- UI#6 Press States: PressableCardStyle (scale 0.97 + dim + light haptic, Reduce-Motion safe); applied to rewardTile, endlessCard, continueCard, RewardButton. Consistent tactile press feedback. BUILD SUCCEEDED.
- UI#7 Game HUD: moved achievement toast BELOW the HUD (top pad 64) so it never collides with back/level/timer; combo pop repositioned to 0.34h (clear of HUD/toast band). Cleaner play screen. BUILD SUCCEEDED.
- UI#8 Empty States: reusable EmptyStateView (soft icon + helpful line); applied to Stats star-distribution when no levels solved yet. EN/TR/ES. BUILD SUCCEEDED.
- UI#9 Iconography: shared CardIconBadge (48pt rounded square + 22pt semibold symbol, active/dim states); refactored endlessCard to it. One icon language for card badges. BUILD SUCCEEDED.
- UI#10 Transitions: AppMotion tokens (card/pop springs) + appearStagger modifier; main-menu cards now fade-and-rise with a staggered entrance (Reduce-Motion safe). PHASE 2 COMPLETE (10/10).
- DONE. Phase 1 (20 features + report) + Phase 2 (10 UI polish) all complete & build-green. NO commit/push — ready for user review. Loop stopped.

## Phase 3 — follow-up suggestions (same loop, NO commit/push)
Ordered. p3-10 (sounds) is TERMINAL: prep asset wiring + list needed sounds, then STOP and ask the user to provide audio.

| P3# | Item | Spec | Status |
|-----|------|------|--------|
| 1 | Calm Solve Completion Glow | `p3-01-solve-glow.md` | DONE ✅ |
| 2 | Tiered Reward Confetti | `p3-02-tiered-confetti.md` | DONE ✅ |
| 3 | Compact Top Stats Bar | `p3-03-top-stats-bar.md` | DONE ✅ |
| 4 | Shared Hit-Test Helper + test | `p3-04-shared-hittest.md` | DONE ✅ |
| 5 | Streak Freeze / Save (gem) | `p3-05-streak-freeze.md` | DONE ✅ |
| 6 | Watch-Ad → 2× Reward | `p3-06-ad-double.md` | DONE ✅ |
| 7 | Skin Shop (gems) | `p3-07-skin-shop.md` | DONE ✅ |
| 8 | Haptic Intensity Setting | `p3-08-haptic-setting.md` | DONE ✅ |
| 9 | First-Level Coach Hand | `p3-09-onboarding-hand.md` | DONE ✅ |
| 10 | Sound Integration (user audio) → STOP & ask | `p3-10-sound-integration.md` | DONE ✅ (wiring; awaiting audio) |

## Log (cont.)
- FIX: placed-piece re-drag used a rectangular bounding-box hit area → an L/T neighbour stole taps for the piece in its gap. Applied PieceCellsShape contentShape to placedPieceHandle (cell-accurate). BUILD SUCCEEDED.
- CHANGE: removed confetti on level solve (board SolveCelebration trigger) AND on LevelCompleteSheet — confetti now ONLY on reward-collection moments. BUILD SUCCEEDED.
- Phase 3 specced (p3-01..p3-10); starting p3-01.
- P3#1 Solve Glow: SolveGlow (soft tertiary radial bloom over board on solve, Reduce-Motion safe) replaces removed solve confetti; reused showCelebration flag. BUILD SUCCEEDED.
- P3#2 Tiered Confetti: RewardTierFX.intensity(coins:gems:) (small 0.35 / medium 0.6 / jackpot+gems 1.0); wired chest, spin, level-up, streak, calendar confetti to scale by actual reward size. BUILD SUCCEEDED.
- P3#3 Top Stats Bar: combined streak + player level + campaign progress into one compact capsule bar; removed separate streakBadge/progressPill from the menu stack (decluttered). BUILD SUCCEEDED.
- P3#4 Shared Hit-Test: added .pieceHitArea(piece) modifier (single source of truth) applied at tray + board hit sites; PieceOccupancy pure helper + PieceOccupancyTests (overlapping-L regression). App BUILD SUCCEEDED (test in test target, not run here).
- P3#5 Streak Freeze: ProgressStore.streakFreezes (snapshot migration) + buyStreakFreeze (5 gems) + applyFreezeBridge (auto-bridges a single missed day before recompute); Settings Gameplay 'Streak Freeze' row (held count + buy). BUILD SUCCEEDED.
- P3#6 Ad Double: ChestReveal + SpinWheel show an optional 'Watch -> 2x' button (AdsManager.showRewarded grants the reward again); opt-in, one-shot. EN/TR/ES. BUILD SUCCEEDED.
- P3#7 Skin Shop: CosmeticsStore (own UserDefaults, unlockedSkins) + skinCost(unlockLevel); skins now usable if level>=unlockLevel OR purchased; Settings skin swatch shows gem price when locked, tap buys+equips (or error if short). BUILD SUCCEEDED.
- P3#8 Haptic Strength: HapticService reads hapticLevel (full/light); light softens all impacts to a gentle tap and skips the buzzy per-cell selection ticks; notify kept. Settings Sound 'Haptic Strength' picker. EN/TR/ES. BUILD SUCCEEDED.
- P3#9 Coach Hand: CoachOverlay (pulsing hand + Drag a piece prompt) shown once on the very first campaign level (0 completed, fresh board); dismissed on first drag; @AppStorage(coachShown); Reduce-Motion safe. EN/TR/ES. BUILD SUCCEEDED.
- P3#10 Sound Integration (WIRING): SoundService rebuilt — drop-in <event>.caf per event + optional per-pack <event>_soft/_crisp variants (native rate) with graceful fallback (reward/levelUp→solve, combo→snap). New dedicated events wired: reward (chest/spin/streak/calendar), levelUp, combo. Players keyed by asset name; missing files = silent no-op. BUILD SUCCEEDED. TERMINAL — awaiting user-supplied audio files.
- AUDIO INTEGRATED (user mp3 → mono/stereo .caf): 8 SFX (click[click-1]/place/snap/solve/error/reward/levelUp/combo) → Resources/Sounds; 2 music tracks bgm + bgm_zen → Resources/Audio. New MusicService (loop, off-main load, crossfade, respects user's own audio via isOtherAudioPlaying, pauses in background). Wired in RootView (scenePhase + zenMode switch) + Settings music toggle. bgm_zen plays in Zen Mode. All 10 .caf confirmed in app bundle. BUILD SUCCEEDED.
- ZEN SAGE THEME: Zen Mode now shifts the whole app to a soft sage-green palette. AppColors mood tokens → computed vars + tone(normal:zen:) gated on UserDefaults zenMode; blocks/error/secondary/tertiary/skins unchanged. RootView rebuild id includes zenMode for live re-read (same pattern as theme switch). Single-palette preserved. BUILD SUCCEEDED.

## Phase 4 — new features (user-chosen, same rules, NO commit/push)
| P4# | Feature | Status |
|-----|---------|--------|
| 1 | In-game Pause Menu | DONE ✅ |
| 2 | Undo Last Placement | DONE ✅ |
| 3 | Volume Sliders (music + SFX) | DONE ✅ |
| 4 | Comeback Reminder Notification | DONE ✅ |
| 5 | Zen Gentle Motion | DONE ✅ |
| 6 | Music Track Picker | DONE ✅ |
| 7 | Mascot Reactions | DONE ✅ |
| 8 | Export / Import Progress | DONE ✅ |
- P4#1 Pause Menu: extended PauseSheet with Hint (places a solution piece via applyHint; warns if none) + Settings (router.push) actions alongside Resume/Restart/Home; hint hidden in Endless/0 hints; detent grown to fit. EN/TR/ES. BUILD SUCCEEDED.
- P4#2 Undo: full undo already existed (PowerUpBar: 1 free/session + gem + watch-ad). Added cozy enhancement — UNLIMITED FREE undo in relaxed modes (Zen Mode or Endless) via viewModel.unlimitedUndo (computed live); PowerUpBar shows ∞ and never charges; timed campaign/daily keep the gem economy. BUILD SUCCEEDED.
- P4#3 Volume Sliders: musicVolume(0.6)/sfxVolume(1.0) @AppStorage; SoundService.fire multiplies by sfxVolume; MusicService targetVolume=userVolume*0.6 headroom + applyVolume() live. Settings Sound section: two volumeRow sliders (dim when toggle off; SFX previews click, music applies live). EN/TR/ES. BUILD SUCCEEDED.
- P4#4 Comeback Reminder: NotificationService.scheduleComeback() arms gentle localized re-engagement reminders at +2d and +7d (UNTimeInterval, non-repeating); RootView scenePhase cancels on active, re-arms on background when enabled — so they only fire after a real absence. Settings notifications section gets a 'Comeback reminders' toggle (requests auth like daily). EN/TR/ES. BUILD SUCCEEDED.
- P4#5 Zen Gentle Motion: AppMotion.card/.pop now computed + zen-aware (slower response, higher damping = no overshoot) + staggerStep 0.05→0.08 in Zen; AppearStagger uses it. RootView rebuild-on-zenMode propagates. Calmer menu/card rhythm in Zen. BUILD SUCCEEDED.
- P4#6 Music Track Picker: MusicService desiredTrack from musicTrack pref (auto/calm/zen); refresh + install validation use it. Settings Sound section menu picker (Auto/Calm/Zen, music-on only) → refresh() live. EN/TR/ES. BUILD SUCCEEDED.
- P4#7 Mascot Reactions: reusable MascotView (idle breathing bob + one-shot happy hop/wiggle on celebrate; Reduce-Motion safe). LevelComplete hero mascot now celebrates on solve; in-game sloth badge gently idles. BUILD SUCCEEDED.
- P4#8 Export/Import: SaveTransfer (allow-listed keys → binary plist → base64 portable code; faithful value types; header-validated import). SaveTransferSheet in Settings→Account (copy/share export, paste→restore, alerts; restart to fully apply). EN/TR/ES. BUILD SUCCEEDED.
- PHASE 4 COMPLETE (8/8): pause menu+hint/settings, unlimited relaxed undo, volume sliders, comeback reminders, zen gentle motion, music track picker, mascot reactions, save export/import. All build-green, NO commit/push.

## Phase 5 — quality & depth (user-chosen "devam", same rules, NO commit/push)
| P5# | Feature | Status |
|-----|---------|--------|
| 1 | Localization completeness audit (tr/en/es parity) | DONE ✅ |
| 2 | Accessibility pass on new UI | DONE ✅ |
| 3 | Lifetime Stats expansion | DONE ✅ |
| 4 | Pack Completion celebration + reward | DONE ✅ |
| 5 | Solve celebration variety (encouraging messages) | DONE ✅ |
- P5#1 Localization audit: scripted parity check — en/tr/es all 357 keys, full union parity, no duplicates, no empty values, format-specifier counts match. Clean, no fixes needed.
- P5#2 Accessibility: volumeRow slider now natively adjustable with VoiceOver label + % value (removed the .combine that trapped it); SaveTransfer export code gets a concise a11y label (no base64 spell-out); CoachOverlay combined into one labeled element. BUILD SUCCEEDED.
- P5#3 Lifetime Stats: ProgressStore aggregates totalStarsEarned/perfectSolves/bestSolveTime/daysPlayed (campaign-only, derived — no new persistence); StatsView new Lifetime section (stars, perfect 3★, best time, longest streak) reusing kpiCard. EN/TR/ES. BUILD SUCCEEDED.
- P5#4 Pack Completion: PackRewardStore (own UserDefaults; pending persisted so detect→collect survives kill; reward banked only on collect, 200 coin+25 gem one-time/pack). Detection in GameViewModel.persistProgress via packId(from:) + MockData levelCount + packCompletionCount. PackCompleteOverlay (RewardModal + confetti + reward sound) on MainMenu, mirrors level-up/streak pattern. Keys added to SaveTransfer. EN/TR/ES. BUILD SUCCEEDED.
- P5#5 Solve Variety: on each solve a random localized word of encouragement (praise.0-5) pops briefly over the board (AppMotion.pop, Reduce-Motion safe, auto-clears 1.5s, versioned token). EN/TR/ES.
- PHASE 5 COMPLETE (5/5): localization audit (clean), accessibility pass, lifetime stats, pack-completion reward, solve praise variety. All build-green, NO commit/push.

## Phase 6 — depth & retention (autonomous "devam", same rules, NO commit/push)
| P6# | Feature | Status |
|-----|---------|--------|
| 1 | Expanded Achievements | DONE ✅ |
| 2 | Rate-the-app prompt (milestone-gated) | DONE ✅ |
| 3 | Achievements progress bars | DONE ✅ |
| 4 | Combo milestone rewards | DONE ✅ |
| 5 | "Today" summary card on main menu | DONE ✅ |
- P6#1 Expanded Achievements: +6 (levelLegend100, packFinisher, perfectionistMaster25, dedicated7 play-streak, comboChampion bestWinChain≥5, speedDemon <15s) → 16 total. AchievementStats gains packsCompleted/longestPlayStreak/bestWinChain; rules + rewards + categories + sfSymbols + EN/TR/ES added. BUILD SUCCEEDED.
- P6#2 Rate Prompt: @Environment(requestReview) triggered once (hasRequestedReview) on pack-completion collect, gated on totalLevelsCompleted>=8, 1.4s after the reward settles. Self-contained, Apple-throttled. BUILD SUCCEEDED.
- P6#3 Achievement Progress: AchievementRules.progress(current,target); locked cells with target>1 show a thin primary progress bar + N/target. Stats threaded into AchievementCell. BUILD SUCCEEDED.
- P6#4 Combo Milestones: combo ×3/×5/×8 now fire a rigid haptic + reward sound; ×5→+1 gem, ×8→+2 gems, shown as 💎+N in the combo pop (cleared on hide/break). Non-milestone combos keep the light tick+combo sound. BUILD SUCCEEDED.
- P6#5 Today Banner: slim warm greeting (time-of-day) + today's quests count (N/3, green when 3/3) at top of menu; kept to one capsule row to honour the decluttered design. EN/TR/ES.
- PHASE 6 COMPLETE (5/5): +6 achievements, rate prompt, achievement progress bars, combo milestone rewards, today banner. All build-green, NO commit/push.

## Phase 7 — content & polish (autonomous, same rules, NO commit/push)
| P7# | Feature | Status |
|-----|---------|--------|
| 1 | More block skins + board backgrounds | DONE ✅ |
| 2 | Earn-a-hint via rewarded ad (when out) | DONE ✅ |
| 3 | Daily puzzle dedicated share card | DONE ✅ |
| 4 | Pack detail header enrichment | DONE ✅ |
| 5 | Stats share card | DONE ✅ |
- P7#1 Cosmetics: +2 block skins (sunset Lv12, aurora Lv15; palettes in Colors.swift) → 6; +3 board backgrounds (dusk/rose/meadow, AppColors-only gradients) → 7. Settings selectors auto-include. EN/TR/ES. BUILD SUCCEEDED.
- P7#2 Earn-a-hint: PowerUpBar hint state → .rewarded when out of hints AND gems (if a rewarded ad is ready); tap shows HintRewardedSheet → AdsManager.showRewarded grants addHints(1) + applyPowerUp(.hint). Mirrors undo rewarded path. EN/TR/ES. BUILD SUCCEEDED.
- P7#3 Daily Share Card: DailyShareCard (branded 340x440, rabbit mascot + daily streak + dailies-solved + date); rendered via ImageRenderer (scale 3) when today's daily completes; ShareLink button appears on the daily card. EN/TR/ES. BUILD SUCCEEDED.
- P7#4 Pack Header: heroBanner now uses LIVE ProgressStore.packCompletionCount (was static MockData scaffold value bug) + packStarsEarned (stars X/Y row) + localized difficulty from gridSize + sloth mascot + completion seal when 100%. ProgressStore.packStarsEarned() added. EN/TR/ES. BUILD SUCCEEDED.
- P7#5 Stats Share: StatsShareCard (branded 340x460, tiger mascot + levels/stars/perfect/longest-streak); ImageRenderer scale 3; ShareLink in StatsView toolbar. EN/TR/ES.
- PHASE 7 COMPLETE (5/5): +2 skins +3 boards, earn-a-hint ad, daily share card, pack header live-fix+enrich, stats share. All build-green, NO commit/push.

## Phase 8 — juice & retention (autonomous, same rules, NO commit/push)
| P8# | Feature | Status |
|-----|---------|--------|
| 1 | "New Best Time" celebration on level complete | DONE ✅ |
| 2 | Sound preview buttons in Settings | DONE ✅ |
| 3 | Daily quest variety expansion | DONE ✅ |
| 4 | Endless new-best celebration | DONE ✅ |
- P8#1 New Best Time: GameViewModel captures prevBest before markCompleted → newBestTime (genuine improvement, not first solve); LevelCompleteSheet shows a tertiary 'New Best!' badge above the stat pills. EN/TR/ES. BUILD SUCCEEDED.
- P8#2 Sound Preview: Settings sound section adds tap-to-preview chips (place/snap/solve/reward/error) playing the active pack+volume; dims when SFX off. EN/TR/ES. BUILD SUCCEEDED.
- P8#3 Quest Variety: added .perfectSolve quest kind (3-star solves); generate() now a 4-day rotation, quest #2 alternates no-hint/perfect; recordSolve gains stars param (passed from persistProgress). EN/TR/ES. BUILD SUCCEEDED.
- P8#4 Endless New-Best: EndlessStore.record returns Bool (new best); GameViewModel.newEndlessBest; on endless solve the praise overlay shows 'New Record! 🏆' + reward sound + success haptic instead of the random praise. EN/TR/ES.
- PHASE 8 COMPLETE (4/4): new-best-time badge, sound preview, quest variety (+perfectSolve), endless record celebration. All build-green, NO commit/push.

## Hotfixes (user-reported, 2026-06-02)
- FIX raw key in achievement unlock toast: AchievementToast used "achievement.unlocked" but the key is "achievement.unlocked.banner.title" → now localized.
- FIX missing pack.grid_label.5/6/7/8 keys (shown raw in Shop bundle grid badges) → added EN/TR/ES.
- FIX Zen music not switching: MusicService now reads zenMode LIVE from UserDefaults in desiredTrack (was a cached flag set via RootView onChange/onAppear, which the .id rebuild on zenMode could swallow → calm track kept playing in Zen). update(zen:) just calls refresh().
- UX: moved Zen Mode to a prominent card at the TOP of Settings (above Sound); removed the duplicate row from the Gameplay section. BUILD SUCCEEDED.

## Round 2 fixes (user-reported, 2026-06-02)
- SOUND reliability: SoundService now keeps a POOL of 4 players per asset (round-robin via firePool) so rapid/overlapping triggers never cut each other off ("sounds sometimes don't play fully" fixed).
- PAUSE quick settings: PauseSheet gains music/sfx/haptics quick-toggle chips (adjustable mid-game; music toggle calls MusicService.refresh).
- SOLVE PRAISE z-order + redesign: moved the solve flourish OUT of the board overlay (was hidden behind the tray) into the root ZStack at zIndex 70; new PraiseBadge (gradient capsule + sparkle + radial glow, spring entrance, Reduce-Motion safe).
- CHEST satisfying redesign: opaque 0.92 scrim; solid radial-filled medallion (was a faint transparent symbol); anticipation shake+pulse with building light haptics; white burst flash + reward sound + success haptic at the pop; rotating golden sunburst rays; reward springs in with overshoot. Reduce-Motion safe.

## Game-feel design pass (user request "daha oyun gibi", 2026-06-02)
Research-driven signals that read as "game" (vs app), applied within the cozy palette:
- BUTTONS: GameButtonStyle top face gains a glossy upper-half sheen (primary) + a 1px white top rim highlight → candy-button gloss on the existing 3D extruded slabs.
- NUMBERS: AppTypography numeric tokens → SF Rounded heavy/bold (chunky game numbers for scores/currencies/timers; brand font stays on headings/body).
- CURRENCY: BalanceChip redesigned as a glossy raised pill (gradient sheen + rim + L1 shadow + bolder rounded number).
- PROGRESS: new GameProgressBar (inset track + gradient fill + glossy sheen + spring) applied to pack header, XP/profile, weekly card, chest meter.
- CARDS: cardSurface() gains a soft top rim highlight for a moulded, tactile look (app-wide). All build-green, NO commit/push.

## Perf & correctness pass (user-reported freeze, 2026-06-02)
- LOCALIZATION (raw keys in screenshots): keys (pack.grid_label.5-8, achievement.*.title, achievement.category.*) are PRESENT & correct in source AND in the built bundle (verified). The device build was stale — a CLEAN rebuild (Cmd+Shift+K → Run) resolves it. No code change needed.
- FREEZE FIX 1: RootTabView.deviceSafeBottom was a UIApplication.connectedScenes/windows walk computed on EVERY body render (re-runs on any tab/path change). Cached to @State, read once onAppear.
- FREEZE FIX 2: the game-feel effects I added used .mask()/.blendMode(.plusLighter) which force per-element OFFSCREEN render passes — costly across card lists (Shop/Achievements). Replaced rim highlights + sheens with plain gradient strokes/fills (same look, no offscreen) in cardSurface, GameButtonStyle, BalanceChip, GameProgressBar.
- FREEZE FIX 3: ImageRenderer share-card renders (StatsView, MainMenu daily) now deferred ~350-400ms via Task.sleep so the main-actor render never blocks the navigation transition into the screen.
- THREAD/LEAK AUDIT: game timer Task cancelled on disappear + before restart (no runaway); SoundService/StoreManager detached tasks use [weak self]; other detached tasks target singletons (no leak). No concrete leaks found in hot paths. Exhaustive end-to-end actor-isolation audit deferred (workflow-scale).

## CRITICAL localization fix + loading-gate (2026-06-02)
- ROOT-CAUSE of raw keys (achievement.*.title, achievement.category.*, pack.grid_label.*): `LocalizedStringKey("literal.\(interp)")` treats the interpolation as a FORMAT ARGUMENT, so the lookup key becomes "…%@…"/"…%lld…" and never matches → renders the raw key. The keys WERE correct in the built bundle (verified via plistlib) — the bug was purely the runtime key construction. Fixed Achievement.displayNameKey/descriptionKey, AchievementCategory.displayNameKey, Pack.gridLabelKey to build the String first then pass to LocalizedStringKey (matches the already-working pack.titleKey pattern). Logged as a CLAUDE.md gotcha.
- LOADING GATE: new reusable LoadingView + LoadingGate (Core/Components/LoadingGate.swift). ShopView now navigates instantly → shows LoadingView → reveals content after store.loadProducts() completes (ready flag). Heavy content build happens behind the spinner, after the transition → fixes "System gesture gate timed out" + slow Shop nav. Available for any slow screen. BUILD SUCCEEDED.

## Shop clarity pass (user, 2026-06-03)
- "—" mystery icon was the price placeholder (product?.displayPrice ?? "—") shown when the StoreKit product price hasn't loaded. Redesigned the buy control: filled primary pill with cart+price when available, else lock+"Unlock" — never a bare dash. Owned → checkmark "Owned".
- Added ⓘ info badges (top-trailing) to each BundleSection item (Puzzle Packs, Hints, Remove Ads); tap shows a localized alert explaining what it does (shop.info.packs/hints/removeAds .title/.body). EN/TR/ES.
- Coin packs already self-explain (FREE ribbon + Watch-Ad CTA); exchange/daily-deal sections already have descriptive subtitles — left as-is. BUILD SUCCEEDED.
