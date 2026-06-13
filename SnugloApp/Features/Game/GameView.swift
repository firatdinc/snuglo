import SwiftUI
import SnugloEngine

// MARK: — GameView
// Ref: Designs/html/06-game-play.html
// Active level screen — loads puzzle by levelId, HUD with back/pause/timer,
// drag-drop tray at bottom, pause sheet, level-complete cover.
//
// Faz F adds: AudioManager + HapticsManager hooks on drag events.
// H-2: Dynamic Type constrained (.medium ... .xxxLarge) — grid must not overflow.
//       Reduce Motion — drag spring animations skipped.
//       VoiceOver — HUD buttons labelled; tray blocks labelled.
// IOS-57: Tray clipping fix (TrayLayout, dynamic height, multi-row flow).
//         Re-drag placed pieces (liftPiece + rollback overlay).
//         Visual polish: snap ghost valid/invalid colours, spring tuning.

struct GameView: View {

    // MARK: — Dependencies

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    let levelId: String

    // MARK: — ViewModel

    @State private var viewModel: GameViewModel

    init(levelId: String = "level_5x5") {
        self.levelId = levelId
        self._viewModel = State(initialValue: GameViewModel.makeFromPackProvider(levelId: levelId))
    }

    // MARK: — Drag state

    @State private var draggingPiece: Piece?
    @State private var dragPosition: CGPoint    = .zero
    @State private var snapCoord: Coord?
    @State private var gridFrame: CGRect        = .zero
    /// Live tilt (degrees) of the floating piece — leans toward drag direction for weight.
    @State private var dragTilt: Double         = 0
    /// 0…0.3 red wash over the board on an invalid drop (juicy "nope" feedback).
    @State private var invalidFlash: Double     = 0

    // MARK: — Carousel state (custom paged tray, no ScrollView)
    // We manage the horizontal offset ourselves so a single DragGesture can
    // decide — on the FIRST movement — whether the touch is a horizontal scroll
    // or an upward pick-up, then lock into that mode for the rest of the drag.
    @State private var carouselOffset: CGFloat = 0          // committed page offset (≤ 0)
    @State private var carouselDrag:   CGFloat = 0          // live horizontal delta while scrolling
    @State private var trayGestureMode: TrayGestureMode = .undecided
    @State private var trayViewportFrame: CGRect = .zero    // viewport rect in "gameLayout" space

    private enum TrayGestureMode { case undecided, scrolling, picking }

    // MARK: — UI state

    @State private var showPause         = false
    @State private var showComplete      = false
    @State private var elapsedSeconds    = 0
    @State private var timerTask: Task<Void, Never>?
    @State private var rewardGranted     = false
    @State private var earnedReward: [Currency: Int] = [:]
    /// v1.1.3 UX fix: back button now asks for confirmation before quitting
    /// so the player doesn't lose timer state accidentally.
    @State private var showQuitConfirmation = false
    /// Faz 3: shown when a power-up tap fails due to insufficient gems.
    @State private var showInsufficientGemBanner = false
    /// Rewarded Undo: shown when user taps Undo without enough gems.
    @State private var showUndoRewardedSheet = false
    @State private var showHintRewardedSheet = false
    /// Solve wave: true while the diagonal cell-wave animation plays after solve.
    @State private var showWaveAnimation = false
    /// Shown when the countdown hits zero without solving.
    @State private var showFail = false
    /// Tower: shown when a climb ends (one mistake).
    @State private var showTowerOver = false
    @State private var towerFloorsCleared = 0

    /// Zen / Relax mode (research: the #1 loved feature of the genre). When on,
    /// the timer becomes a calm count-UP and the level can never fail on time.
    @AppStorage("zenMode") private var zenMode = false

    /// Confetti burst on solve (juice). Auto-clears; skipped under Reduce Motion.
    @State private var showCelebration = false
    /// 0…1 — scales the confetti by the win-streak chain length (juicier streaks).
    @State private var celebrationIntensity: Double = 0.5

    // In-level combo: rapid consecutive valid placements build a "Combo xN" pop.
    @State private var comboCount = 0
    @State private var lastPlaceAt: Date?
    @State private var comboVisible = false
    @State private var comboVersion = 0
    /// Gems awarded at the current combo milestone (shown in the pop); 0 if none.
    @State private var comboCoinBonus = 0

    // Visual hint: the hinted piece pulses for a moment after it's placed.
    @State private var hintFlashID: String?
    @State private var hintFlashVersion = 0

    // Energy-spent flourish: shows "−5 ⚡" once when a paid level starts.
    @State private var energySpendAmount: Int?

    // Achievement unlock toasts (queued).
    @State private var achToastQueue: [Achievement] = []
    @State private var achToast: Achievement?

    // First-ever level coach hand (shown once).
    @AppStorage("coachShown") private var coachShown = false
    @State private var showCoach = false

    // A rotating cozy word of encouragement shown briefly on solve.
    @State private var solvePraiseKey: LocalizedStringKey?
    @State private var solvePraiseVersion = 0
    private static let praiseKeys: [LocalizedStringKey] = [
        "praise.0", "praise.1", "praise.2", "praise.3", "praise.4", "praise.5"
    ]

    /// v1.1.4 layout: live cell size of the board, derived from the flexible
    /// board region (see `boardRegion`). The board is a centred square sized to
    /// the SMALLER of its available width and height, so it always fits between
    /// the chrome and the fixed-height tray — and because the tray height is a
    /// constant (never depends on piece count), this value is stable across the
    /// whole game (no grow/shrink as pieces are placed). 0 until first layout.
    @State private var boardCellSize: CGFloat = 0
    /// Whole-screen size from the root GeometryReader (excludes safe area).
    /// Stable — only changes on rotation — so reading it never triggers the
    /// layout loop the old `gridFrame`-based sizing was prone to.
    @State private var availableSize: CGSize = .zero

    /// Width-based fallback used before `boardCellSize` is measured (first
    /// frame) or if the board region hasn't reported a size yet. Stable —
    /// reads only the screen width, never `gridFrame`, so it can't drive the
    /// layout loop the old sizing was prone to.
    private var fallbackCell: CGFloat {
        let screenW = availableSize.width > 0 ? availableSize.width : UIScreen.main.bounds.width
        return max(1, (screenW - AppSpacing.lg * 2) / CGFloat(viewModel.level.width))
    }

    /// The effective board cell size used everywhere (grid, drag math, tray
    /// preferred cell, overlay). Falls back to the width estimate until the
    /// board region measures itself.
    private var cellSize: CGFloat {
        boardCellSize > 0 ? boardCellSize : fallbackCell
    }

    /// True when the current snap position would result in overlap or OOB.
    /// Drives snap ghost colour in GridView — computed from viewModel, no extra state.
    private var snapIsInvalid: Bool {
        guard let coord = snapCoord, let piece = draggingPiece else { return false }
        return viewModel.wouldOverlapOrOOB(pieceID: piece.id, at: coord)
    }

    /// How far the dragged piece floats ABOVE the finger, so the thumb never
    /// covers the piece or the target cells (a core mobile-puzzle feel fix).
    private let dragLift: CGFloat = 46

    /// Finger position adjusted by the lift — the piece's visual centre. Both the
    /// floating overlay and the snap target are computed from this single point,
    /// so the ghost always matches exactly where the piece will land.
    private func liftedPos(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x, y: p.y - dragLift)
    }

    /// Updates the drag position and leans the piece toward the horizontal motion.
    private func setDragPosition(_ p: CGPoint) {
        if !reduceMotion {
            let dx = p.x - dragPosition.x
            dragTilt = max(-9, min(9, Double(dx) * 0.8))
        }
        dragPosition = p
    }

    /// A valid placement landed — grow the in-level combo if it was quick, show a
    /// "Combo xN" pop with a small coin bonus, and auto-hide after a beat.
    private func registerCombo() {
        let now = Date()
        if let last = lastPlaceAt, now.timeIntervalSince(last) <= 2.5 {
            comboCount += 1
        } else {
            comboCount = 1
        }
        lastPlaceAt = now
        guard comboCount >= 2 else { return }
        // Combos pay COIN only (gems stay scarce), and never in relaxed modes
        // (Zen/Endless must not farm currency) — the pop/haptic still play.
        if !relaxed {
            WalletStore.shared.earn(.coin, amount: min(comboCount, 8) * 2)
        }
        // Milestone combos (×3/×5/×8) get a punchier reward + celebration.
        if comboCount == 3 || comboCount == 5 || comboCount == 8 {
            HapticService.shared.impact(.rigid)
            SoundService.shared.play(.reward)
            if !relaxed && comboCount >= 5 {
                let bonus = comboCount >= 8 ? 20 : 10
                WalletStore.shared.earn(.coin, amount: bonus)
                comboCoinBonus = bonus
            }
        } else {
            HapticService.shared.selection()
            SoundService.shared.play(.combo)
        }
        comboVersion += 1
        withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.55)) {
            comboVisible = true
        }
        let token = comboVersion
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1000))
            if comboVersion == token {
                withAnimation(.easeOut(duration: 0.2)) { comboVisible = false }
                comboCoinBonus = 0
            }
        }
    }

    /// Pops the next queued achievement toast and schedules its dismissal.
    private func showNextAchToast() {
        guard !achToastQueue.isEmpty else { achToast = nil; return }
        let next = achToastQueue.removeFirst()
        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
            achToast = next
        }
        HapticService.shared.selection()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2400))
            withAnimation(.easeOut(duration: 0.25)) { achToast = nil }
            try? await Task.sleep(for: .milliseconds(320))
            showNextAchToast()
        }
    }

    /// Resets the combo (invalid drop breaks the streak of clean placements).
    private func breakCombo() {
        comboCount = 0
        lastPlaceAt = nil
        comboCoinBonus = 0
        if comboVisible { withAnimation(.easeOut(duration: 0.15)) { comboVisible = false } }
    }

    /// Invalid drop: error sound + haptic + a quick red wash over the board.
    private func triggerInvalidFeedback() {
        breakCombo()
        SoundService.shared.play(.error)
        HapticService.shared.notify(.error)
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.08)) { invalidFlash = 0.30 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.easeIn(duration: 0.25)) { invalidFlash = 0 }
        }
    }

    private func overlayOffset(for piece: Piece) -> CGPoint {
        let halfW = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1) * cellSize / 2
        let halfH = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1) * cellSize / 2
        let c = liftedPos(dragPosition)
        return CGPoint(x: c.x - halfW, y: c.y - halfH)
    }

    /// Pack display name for HUD title (derived from PackProvider lookup, not stored).
    private var packDisplayName: String {
        PackProvider.allPacks().first { pack in
            PackProvider.levelItems(in: pack.id).contains { item in item.id == levelId }
        }?.title ?? ""
    }

    /// Fraction of pieces placed (0...1) — drives progress bar.
    private var placedFraction: CGFloat {
        let total = viewModel.level.pieces.count
        guard total > 0 else { return 0 }
        return CGFloat(total - viewModel.unplacedPieces.count) / CGFloat(total)
    }

    // MARK: — Body

    var body: some View {
        GeometryReader { rootGeo in
            ZStack(alignment: .topLeading) {
                mainLayout
                if let piece = draggingPiece {
                    let off = overlayOffset(for: piece)
                    BlockView(
                        piece: piece, cellSize: cellSize,
                        isInvalid: viewModel.invalidPieceIDs.contains(piece.id),
                        isDragging: true
                    )
                    .rotationEffect(.degrees(dragTilt))
                    .offset(x: off.x, y: off.y)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true) // overlay duplicate; original already labelled
                    // "poof" out on release; spring the lean back to level
                    .transition(.scale(scale: 0.55).combined(with: .opacity))
                    .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: dragTilt)
                }
                if comboVisible && comboCount >= 2 {
                    comboPop
                        // Clearly over the board, well below the HUD/toast band.
                        .position(x: rootGeo.size.width / 2, y: rootGeo.size.height * 0.34)
                        .allowsHitTesting(false)
                        .transition(.scale.combined(with: .opacity))
                }
                if let a = achToast {
                    AchievementToast(achievement: a)
                        .frame(width: rootGeo.size.width, alignment: .top)
                        // Sit BELOW the HUD (back/level/timer) so they never collide.
                        .padding(.top, 64)
                        .allowsHitTesting(false)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(40)
                }
                if showCoach {
                    TutorialOverlay {
                        showCoach = false
                        coachShown = true
                    }
                    .zIndex(80)
                    .transition(.opacity)
                }
                if showTowerOver {
                    TowerGameOverSheet(
                        floorsCleared: towerFloorsCleared,
                        coinReward: TowerStore.reward(forFloors: towerFloorsCleared),
                        onRetry: {
                            if TowerStore.shared.payEntry() {
                                showTowerOver = false
                                TowerStore.shared.setCurrentFloor(1)
                                router.replaceTop(with: .game(levelID: "tower-1"))
                            }
                        },
                        onHome: {
                            showTowerOver = false
                            router.popToRoot()
                        }
                    )
                    .zIndex(90)
                    .transition(.opacity)
                }
                // Solve praise — centred, ABOVE everything (was hidden behind tray).
                if let praise = solvePraiseKey {
                    PraiseBadge(textKey: praise)
                        .frame(width: rootGeo.size.width, height: rootGeo.size.height)
                        .allowsHitTesting(false)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                        .zIndex(70)
                }
            }
            .frame(width: rootGeo.size.width, height: rootGeo.size.height, alignment: .top)
            .animation(reduceMotion ? nil : AppMotion.pop, value: solvePraiseKey == nil)
            // Block all input while the solve wave animation plays.
            .allowsHitTesting(!showWaveAnimation)
            // Stable: rootGeo.size only changes on rotation, never as pieces are
            // placed, so storing it can't drive a layout loop.
            .onChange(of: rootGeo.size) { _, newSize in
                if newSize != availableSize { availableSize = newSize }
            }
            .onAppear {
                if rootGeo.size != availableSize { availableSize = rootGeo.size }
            }
        }
        .coordinateSpace(.named("gameLayout"))
        .background(AppColors.background.ignoresSafeArea())
        // Lock tab-carousel swipe + nav edge-swipe while the game is on screen —
        // the only way out is the Back button. Restores both when the view leaves.
        .background(GameInteractionLock().allowsHitTesting(false))
        // iOS 17+ replacement for deprecated .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        // iOS 26: .contain ensures children (including game.grid) remain visible
        // to XCTest queries. Without it, the plain identifier may trigger iOS 26's
        // combine behaviour which absorbs children into the container element.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.game")
        // H-2: Constrain Dynamic Type — grid cells overflow at AX5 sizes
        .dynamicTypeSize(.medium ... .xxxLarge)
        // v1.1 bug fix: onDismiss fires when sheet is dismissed by ANY means (button OR swipe).
        // Without this, swiping the sheet down leaves the timer cancelled permanently.
        // Note: multiple_closures_with_trailing_closure — content closure is NOT trailing here.
        .sheet(isPresented: $showPause, onDismiss: { startTimer() }, content: {
            PauseSheet(
                onResume: {},      // startTimer() is called via onDismiss above
                onRestart: { restartFromPause() },
                onQuit: {
                    ProgressStore.shared.breakChain()
                    router.pop()
                },
                onHint: {
                    // Place one solution piece; the HUD pulse animates via onChange.
                    if !viewModel.applyHint() {
                        HapticService.shared.notify(.warning)
                        SoundService.shared.play(.error)
                    }
                },
                onSettings: { router.push(.settings) },
                // Endless puzzles are generated (no canonical hint); campaign only.
                hintsAvailable: !isEndless && ProgressStore.shared.hintCount > 0,
                elapsedSeconds: elapsedSeconds
            )
            .environment(router)
        })
        .overlay {
            if showFail {
                LevelFailSheet(
                    onRetry: {
                        showFail = false
                        GameSessionStore.shared.clear(levelID: levelId)   // fresh attempt
                        viewModel = GameViewModel.makeFromPackProvider(levelId: levelId)
                        elapsedSeconds = 0
                        rewardGranted = false
                        earnedReward = [:]
                        startTimer()
                    },
                    onHome: {
                        showFail = false
                        router.pop()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showFail)
        .fullScreenCover(isPresented: $showComplete) { levelCompleteCover }
        .onChange(of: draggingPiece?.id) { _, id in
            if id != nil, showCoach {
                showCoach = false
                coachShown = true
            }
        }
        .onAppear {
            router.isGameActive = true
            // Resume an in-progress board (campaign/daily) when re-entering a level
            // left unfinished. Must run before startTimer so the clock continues.
            if isResumable, viewModel.placements.isEmpty,
               let session = GameSessionStore.shared.session(for: levelId),
               viewModel.restore(from: session) {
                elapsedSeconds = session.elapsedSeconds
            }
            startTimer()
            // Show the "−5 energy" flourish once, if this entry actually charged
            // (paid campaign start; re-entries & relaxed modes don't set it).
            let spent = EnergyStore.shared.consumeSpendAnimation()
            if spent > 0 { energySpendAmount = spent }
            // Tower: persist the floor we're on so the climb resumes here.
            if isTower { TowerStore.shared.setCurrentFloor(towerFloor) }
            // First-ever campaign level → show the one-time coach hand.
            if !coachShown, !isEndless, dailyIndex == nil,
               viewModel.placements.isEmpty,
               ProgressStore.shared.totalLevelsCompleted() == 0 {
                showCoach = true
            }
            // Pre-warm audio + haptics OFF the gesture path so the first piece
            // drag is instant (was freezing 3–5s while AVAudioSession activated
            // on the main thread during the gesture → "gesture gate timed out").
            SoundService.shared.warmUp()
            HapticService.shared.prepareImpact()
        }
        .onDisappear {
            router.isGameActive = false
            timerTask?.cancel()
            // Persist the in-progress board so re-entry resumes here.
            saveSession()
        }
        // Save whenever the board changes so an app kill mid-level loses nothing.
        .onChange(of: viewModel.placements) { _, _ in saveSession() }
        // Save on backgrounding too (captures the latest elapsed time).
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { saveSession() }
        }
        // Energy-spent flourish — a one-shot "−5 ⚡" badge that pops in near the top,
        // then floats up and fades. Self-clears via onFinish.
        .overlay(alignment: .top) {
            if let amount = energySpendAmount {
                EnergySpendBadge(amount: amount) { energySpendAmount = nil }
                    .padding(.top, AppSpacing.lg)
                    .allowsHitTesting(false)
                    .zIndex(80)
            }
        }
        // v1.1.3: confirmation before quitting — preserves in-progress puzzle.
        // Modern custom modal (replaces the system .confirmationDialog).
        .overlay {
            if showQuitConfirmation {
                ConfirmDialog(
                    icon: "door.left.hand.open",
                    titleKey: "game.quitConfirm.title",
                    messageKey: "game.quitConfirm.message",
                    cancelKey: "game.quitConfirm.cancel",
                    confirmKey: "game.quitConfirm.confirm",
                    onCancel: { dismissQuitConfirmation() },
                    onConfirm: {
                        dismissQuitConfirmation()
                        ProgressStore.shared.breakChain()   // quit mid-play → chain broken
                        router.pop()
                    }
                )
                .zIndex(10)
            }
        }
        .animation(reduceMotion ? .none : .spring(response: 0.32, dampingFraction: 0.82),
                   value: showQuitConfirmation)
        // Rewarded Undo sheet
        .sheet(isPresented: $showUndoRewardedSheet) {
            UndoRewardedSheet(
                onWatchAd: {
                    showUndoRewardedSheet = false
                    // Wait for the sheet to dismiss before presenting the ad (else it
                    // shows from a tearing-down VC and closes instantly).
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(500))
                        AdsManager.shared.showRewarded {
                            let anim: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
                            withAnimation(anim) {
                                viewModel.undoLastMove()
                            }
                            HapticService.shared.impact(.light)
                            SoundService.shared.play(.place)
                        }
                    }
                },
                onDismiss: { showUndoRewardedSheet = false }
            )
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        // Rewarded Hint sheet (out of hints AND gems)
        .sheet(isPresented: $showHintRewardedSheet) {
            HintRewardedSheet(
                onWatchAd: {
                    showHintRewardedSheet = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(500))
                        AdsManager.shared.showRewarded {
                            ProgressStore.shared.addHints(1)
                            _ = viewModel.applyPowerUp(.hint)   // consumes the granted hint
                            HapticService.shared.impact(.light)
                        }
                    }
                },
                onDismiss: { showHintRewardedSheet = false }
            )
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.newlyUnlockedAchievements) { _, new in
            guard !new.isEmpty else { return }
            achToastQueue.append(contentsOf: new)
            viewModel.clearNewAchievements()
            if achToast == nil { showNextAchToast() }
        }
        .onChange(of: viewModel.hintsUsed) { _, _ in
            guard let id = viewModel.lastHintPieceID else { return }
            hintFlashVersion += 1
            let token = hintFlashVersion
            hintFlashID = id
            HapticService.shared.impact(.light)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1700))
                if hintFlashVersion == token { hintFlashID = nil }
            }
        }
        .onChange(of: viewModel.towerFailed) { _, failed in
            guard failed, !showTowerOver else { return }
            timerTask?.cancel()
            TowerStore.shared.endRun()      // climb is over → no resume
            let cleared = max(0, towerFloor - 1)
            towerFloorsCleared = cleared
            let coins = TowerStore.reward(forFloors: cleared)
            if coins > 0 { WalletStore.shared.earn(.coin, amount: coins) }
            HapticService.shared.notify(.error)
            SoundService.shared.play(.error)
            showTowerOver = true
        }
        .onChange(of: viewModel.isSolved) { _, solved in
            if solved {
                timerTask?.cancel()
                // Buzzer-beater: a solve always wins. Clear any fail that raced in on
                // the same MainActor tick so the player never sees BOTH the fail sheet
                // and the success cover (the "lion + 3 stars over a fail" bug).
                showFail = false
                SoundService.shared.play(.solve)
                HapticService.shared.notify(.success)
                // Tower: floor cleared → record + climb straight to the next floor.
                if isTower {
                    let floor = towerFloor
                    TowerStore.shared.record(floor: floor)
                    TowerStore.shared.setCurrentFloor(floor + 1)   // resume point
                    solvePraiseKey = "tower.floorUp"
                    let token = (solvePraiseVersion &+ 1); solvePraiseVersion = token
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(700))
                        router.replaceTop(with: .game(levelID: "tower-\(floor + 1)"))
                    }
                    return
                }
                // NB: the between-level interstitial is no longer fired here. Shown
                // at solve, the level-complete cover presented on top of it and tore
                // it down after ~0.5s (the "ad flash" bug). It now fires from the
                // "Next" handler, after the cover has dismissed.
                if !rewardGranted {
                    rewardGranted = true
                    // Solve currency/XP is computed & applied in
                    // GameViewModel.persistProgress (real stars + mode aware); we
                    // just surface what was granted for the result UI.
                    earnedReward = viewModel.lastSolveReward

                    if !relaxed {
                        // Win-streak chain (campaign/daily only): grow the chain,
                        // pay an escalating coin bonus, intensify the celebration.
                        // Relaxed modes don't build competitive chains.
                        let chain = ProgressStore.shared.recordWin()
                        let chainBonus = ProgressStore.chainCoinBonus(forChain: chain)
                        if chainBonus > 0 {
                            WalletStore.shared.earn(.coin, amount: chainBonus)
                            earnedReward[.coin, default: 0] += chainBonus
                        }
                        // Every 5-win chain milestone drops a chest key.
                        if chain > 0 && chain % 5 == 0 { ChestStore.shared.addKey(1) }
                        celebrationIntensity = min(1, Double(chain) / 5.0)
                    } else {
                        celebrationIntensity = 0.3
                    }
                }
                // Calm completion glow (NOT confetti — confetti is for reward moments).
                if !reduceMotion {
                    showCelebration = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(950))
                        showCelebration = false
                    }
                }
                // A rotating word of encouragement — small cozy variety on each solve.
                // An endless personal-best overrides it with a record shout-out.
                if viewModel.newEndlessBest {
                    solvePraiseKey = "endless.record"
                    HapticService.shared.notify(.success)
                    SoundService.shared.play(.reward)
                } else {
                    solvePraiseKey = Self.praiseKeys.randomElement()
                }
                let praiseToken = (solvePraiseVersion &+ 1)
                solvePraiseVersion = praiseToken
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(1500))
                    if solvePraiseVersion == praiseToken { solvePraiseKey = nil }
                }
                // Wave plays first; SolveWaveOverlay calls onComplete → showComplete = true
                showWaveAnimation = true
            }
        }
    }

    // MARK: — Main layout

    private var mainLayout: some View {
        VStack(spacing: AppSpacing.sm) {
            gameHUD
            progressRow

            // Faz 3: Power-up bar between HUD and puzzle grid
            PowerUpBar(
                viewModel: viewModel,
                onInsufficientGem: { showInsufficientGemBanner = true },
                onUndoRewarded:    { showUndoRewardedSheet = true },
                onHintRewarded:    { showHintRewardedSheet = true }
            )

            if showInsufficientGemBanner {
                AnnouncementBanner(
                    titleKey: "powerup.insufficient.gem.title",
                    messageKey: "powerup.insufficient.gem.message",
                    ctaKey: "powerup.insufficient.gem.cta",
                    onCTA: {
                        showInsufficientGemBanner = false
                        router.selectTab(.shop)
                    },
                    onDismiss: { showInsufficientGemBanner = false }
                )
                .padding(.horizontal, AppSpacing.lg)
            }

            // Board + tray share ONE measured region and are split
            // proportionally (board ≥ ~58%, tray ≤ ~42%). No chrome-height
            // estimate, so it can't starve the board on tall-piece levels, and
            // the tray pieces shrink-to-fit their share (never clipped).
            boardAndTrayRegion
        }
        .padding(.vertical, AppSpacing.md)
        // Pin to the top of the screen so oversized content can never get
        // vertically centred (which is what clipped the HUD off the top and
        // the tray off the bottom). With the board sized to fit, nothing
        // overflows anyway — this is belt-and-braces.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: — Mascot badge

    /// Sloth badge floating above the puzzle grid (gentle idle bob).
    private var mascotBadge: some View {
        MascotView(name: "mascot-sloth", size: 64, clipCircle: false)
            .background(
                AppColors.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.4), lineWidth: 0.5)
            )
            .shadowL1()
            .accessibilityHidden(true)
    }

    // MARK: — Board + tray region (proportional split)

    /// Measures the whole space below the chrome and splits it between the board
    /// (a centred square, gets the larger share) and the tray (gets ≤ ~42%).
    /// The split uses only the MEASURED region — no chrome-height guesswork — so
    /// the board never collapses on tall-piece levels, and the tray pieces are
    /// shrink-to-fit into their share (see trayFitCell) and so are never clipped.
    /// All inputs are stable (region size + the full, constant piece set), so
    /// nothing grows/shrinks as pieces are placed.
    private var boardAndTrayRegion: some View {
        GeometryReader { geo in
            let split = regionSplit(width: geo.size.width, height: geo.size.height)
            VStack(spacing: AppSpacing.md) {
                boardSquare
                    .frame(width: split.boardW, height: split.boardH)
                    .overlay {
                        if showWaveAnimation {
                            SolveWaveOverlay(
                                level: viewModel.level,
                                placements: viewModel.placements,
                                cellSize: cellSize
                            ) {
                                showWaveAnimation = false
                                // Guard the reverse race: if the countdown fail already
                                // concluded the level, don't also present the success cover.
                                if !showFail { showComplete = true }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                        }
                    }
                    // Natural size (no maxHeight fill) so the board+tray GROUP can be
                    // centred together below — otherwise the board ate the slack and
                    // pinned the tray to the region bottom, pushing pieces off-screen
                    // on shorter devices (iPhone 15).
                    .onAppear { publishBoardCell(split.cell) }
                    .onChange(of: split.cell) { _, c in publishBoardCell(c) }

                trayBody(contentHeight: split.trayContentH, cell: split.cell)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private struct RegionSplit {
        var boardW: CGFloat
        var boardH: CGFloat
        var cell: CGFloat
        var trayContentH: CGFloat
    }

    /// Pure split math: fixed tray height — tray never grows/shrinks as pieces
    /// are placed; board takes all remaining space.
    private func regionSplit(width regionW: CGFloat, height regionH: CGFloat) -> RegionSplit {
        let w = CGFloat(viewModel.level.width)
        let h = CGFloat(viewModel.level.height)
        let spacing = AppSpacing.md
        let trayHeaderH: CGFloat = 26
        let boardMaxW = max(0, regionW - AppSpacing.lg * 2)

        // Fixed tray content height — constant regardless of piece count.
        let trayContentH: CGFloat = 100

        let vBudget = max(0, regionH - spacing - trayHeaderH)
        let boardAvailH = max(0, vBudget - trayContentH)

        let boardW = max(0, min(boardMaxW, boardAvailH * (w / h)))
        let boardH = boardW * (h / w)
        let cell = w > 0 ? boardW / w : 0
        return RegionSplit(boardW: boardW, boardH: boardH, cell: cell, trayContentH: trayContentH)
    }

    private func publishBoardCell(_ c: CGFloat) {
        guard c > 0, abs(c - boardCellSize) > 0.5 else { return }
        boardCellSize = c
    }

    /// The board itself (grid canvas + transparent re-drag handles).
    private var boardSquare: some View {
        ZStack(alignment: .topLeading) {
            // Pulse drives the breathing snap-target halo. The timeline only ticks
            // while a piece is in hand (and never under Reduce Motion), so it costs
            // nothing at rest.
            TimelineView(.animation(minimumInterval: 1.0 / 30.0,
                                    paused: (draggingPiece == nil && hintFlashID == nil) || reduceMotion)) { tl in
                let active = draggingPiece != nil || hintFlashID != nil
                let pulse: CGFloat = (active && !reduceMotion)
                    ? CGFloat(0.5 + 0.5 * sin(tl.date.timeIntervalSinceReferenceDate * 4.2))
                    : (hintFlashID != nil ? 0.7 : 0)
                GridView(
                    level: viewModel.level,
                    placements: viewModel.placements,
                    invalidPieceIDs: viewModel.invalidPieceIDs,
                    snapCoord: snapCoord,
                    snapIsInvalid: snapIsInvalid,
                    draggingPieceID: draggingPiece?.id,
                    snapPulse: pulse,
                    hintPieceID: hintFlashID
                )
                // v1.1.1 critical fix: round frame before triggering @State update.
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .named("gameLayout"))
                } action: { frame in
                    let rounded = CGRect(
                        x: frame.origin.x.rounded(),
                        y: frame.origin.y.rounded(),
                        width: frame.width.rounded(),
                        height: frame.height.rounded()
                    )
                    if rounded != gridFrame {
                        gridFrame = rounded
                    }
                }
            }

            // IOS-57: Transparent drag handles for placed pieces (re-drag from board).
            // GeometryReader gets the exact same proposed size as GridView (same ZStack),
            // so geo.size.width / level.width matches GridView's internal cell size exactly.
            // NOTE: must NOT be gated on `draggingPiece == nil` — removing the handle
            // container mid-drag destroys the active gesture's host view so .onEnded
            // never fires (the re-drag would freeze). Keep it mounted throughout.
            if !viewModel.placements.isEmpty {
                GeometryReader { geo in
                    let cs = geo.size.width / CGFloat(viewModel.level.width)
                    ForEach(viewModel.level.pieces, id: \.id) { piece in
                        if let placement = viewModel.placements[piece.id] {
                            placedPieceHandle(piece: piece, placement: placement, cs: cs)
                        }
                    }
                }
            }
        }
        // Invalid-drop red wash (non-geometric → safe overlay, no layout churn).
        .overlay {
            if invalidFlash > 0 {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColors.error.opacity(invalidFlash))
                    .allowsHitTesting(false)
            }
        }
        // Calm solve completion glow, centred over the board.
        .overlay {
            if showCelebration { SolveGlow() }
        }
        // iOS 26: identifier on the ZStack wrapper — Canvas (GridView) is
        // accessibility-opaque, so the identifier must live on an ancestor
        // with real visual bounds and .ignore semantics.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("a11y.puzzleGrid"))
        .accessibilityIdentifier("game.grid")
    }

    // MARK: — HUD (Faz 3b: Vibrant Play — pack name + level subtitle, timer pill, white circle buttons)

    private var gameHUD: some View {
        HStack(spacing: AppSpacing.sm) {
            // Back (v1.1.3: asks for confirmation to prevent accidental quit)
            Button { presentQuitConfirmation() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surfaceContainerLowest, in: Circle())
                    .shadowL1()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("a11y.back"))
            .accessibilityHint(Text("a11y.backHint"))
            .accessibilityIdentifier("game.back")

            Spacer()

            // Level number + pack name subtitle
            VStack(spacing: 2) {
                Text(verbatim: levelDisplayName)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text(verbatim: packDisplayName)
                    .font(AppTypography.labelSmall)
                    .tracking(0.4)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .accessibilityHidden(true)

            Spacer()

            HStack(spacing: AppSpacing.sm) {
                // Timer — countdown capsule pill, turns red when ≤ 30 s remain
                HStack(spacing: 4) {
                    Image(systemName: relaxed ? "leaf.fill" : (timerIsUrgent ? "exclamationmark.circle.fill" : "clock.fill"))
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                    Text(formattedTimer)
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .frame(minWidth: 38, alignment: .leading)
                }
                .padding(.horizontal, AppSpacing.sm + 2)
                .padding(.vertical, AppSpacing.xs + 2)
                .background(timerIsUrgent ? AppColors.error : AppColors.primary, in: Capsule())
                .animation(.easeInOut(duration: 0.3), value: timerIsUrgent)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.remainingTime", comment: ""), levelDisplayName, formattedTimer)))
                .accessibilityIdentifier("game.timer")

                // Endless: discard this puzzle and roll a fresh one (anti-frustration).
                if isEndless {
                    Button { skipEndless() } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .frame(width: 40, height: 40)
                            .background(AppColors.surfaceContainerLowest, in: Circle())
                            .shadowL1()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("a11y.newPuzzle"))
                    .accessibilityHint(Text("a11y.newPuzzleHint"))
                    .accessibilityIdentifier("button.game.skip")
                }

                // Pause
                Button { pauseGame() } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .frame(width: 40, height: 40)
                        .background(AppColors.surfaceContainerLowest, in: Circle())
                        .shadowL1()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("a11y.pause"))
                .accessibilityHint(Text("a11y.pauseHint"))
                // Faz I-2: updated identifier spec
                .accessibilityIdentifier("button.game.pause")
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Progress bar (piece placement progress)

    /// Floating in-level combo pop.
    private var comboPop: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .bold))
            Text(verbatim: "Combo x\(comboCount)")
                .font(AppTypography.headlineSmall)
                .monospacedDigit()
            if comboCoinBonus > 0 {
                Text(verbatim: "🪙+\(comboCoinBonus)")
                    .font(AppTypography.headlineSmall)
            }
        }
        .foregroundStyle(AppColors.onPrimary)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs + 2)
        .background(AppColors.tertiary, in: Capsule())
        .shadowL1()
        .id(comboVersion)
        .scaleEffect(1 + min(Double(comboCount), 6) * 0.04)
    }

    /// Win-streak chip — appears at chain ≥ 2 to reinforce "don't break it".
    private var chainBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .bold))
            Text(verbatim: "x\(ProgressStore.shared.winChain)")
                .font(AppTypography.labelSmall)
                .monospacedDigit()
        }
        .foregroundStyle(AppColors.tertiary)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 3)
        .background(AppColors.tertiary.opacity(0.14), in: Capsule())
        .overlay(Capsule().stroke(AppColors.tertiary.opacity(0.35), lineWidth: 1))
        .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.winStreak", comment: ""), ProgressStore.shared.winChain)))
    }

    private var progressRow: some View {
        HStack(spacing: AppSpacing.sm) {
            if ProgressStore.shared.winChain >= 2 {
                chainBadge
                    .transition(.scale.combined(with: .opacity))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.surfaceContainerHigh)
                        .frame(height: 5)
                    if placedFraction > 0 {
                        Capsule()
                            .fill(LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * placedFraction, height: 5)
                    }
                }
                .frame(height: 5)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 14)

            Text("\(Int(placedFraction * 100))%")
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.primary)
                .monospacedDigit()
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityHidden(true)
    }

    // MARK: — Tray

    /// Tray: fixed height, always 3 columns wide.
    /// ≤ 3 pieces → equal distribution (like UIStackView fillEqually).
    /// > 3 pieces → horizontal scroll, each piece in a 1/3-width column.
    /// Cell size is computed from the FULL piece set so it never changes.
    private func trayBody(contentHeight: CGFloat, cell: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            trayHeader

            GeometryReader { geo in
                let colW  = geo.size.width / 3
                let maxPW = CGFloat(viewModel.level.pieces.map { TrayLayout.pieceWidth($0)  }.max() ?? 1)
                let maxPH = CGFloat(viewModel.level.pieces.map { TrayLayout.pieceHeight($0) }.max() ?? 1)
                let cellByH = geo.size.height / maxPH
                let cellByW = (colW - AppSpacing.xs) / maxPW
                let cs      = max(1, min(cellByH, cellByW))
                let pieces  = viewModel.unplacedPieces

                trayPiecesLayout(pieces: pieces, colW: colW, totalH: geo.size.height, cs: cs)
            }
            .frame(height: contentHeight)
            .background(AppColors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .shadowL1()
        }
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: String(format: NSLocalizedString("a11y.pieceTray", comment: ""), viewModel.unplacedPieces.count)))
        .onChange(of: viewModel.unplacedPieces.count) { _, _ in
            // Piece placed/removed: reset the carousel so the offset can't point
            // past the (now shorter) row.
            carouselOffset   = 0
            carouselDrag     = 0
            trayGestureMode  = .undecided
        }
    }

    @ViewBuilder
    private func trayPiecesLayout(pieces: [Piece], colW: CGFloat, totalH: CGFloat, cs: CGFloat) -> some View {
        if pieces.count <= 3 {
            // Equal distribution: each piece centered in its equal share. A gap
            // between shares + a cell-accurate contentShape give each piece a
            // clean, non-overlapping touch target (fixes "wrong piece grabbed").
            HStack(spacing: AppSpacing.md) {
                ForEach(pieces, id: \.id) { piece in
                    ZStack {
                        BlockView(
                            piece: piece, cellSize: cs,
                            isInvalid: viewModel.invalidPieceIDs.contains(piece.id),
                            isDragging: false
                        )
                        .opacity(draggingPiece?.id == piece.id ? 0.0 : 1.0)
                        .pieceHitArea(piece)
                        .highPriorityGesture(dragGesture(for: piece))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Custom paged carousel — NO ScrollView. 3 pieces visible; a single
            // DragGesture decides per-touch between horizontal scroll and upward
            // pick-up. This avoids the gesture-conflict that made the ScrollView
            // approach swallow horizontal swipes.
            let pageW       = colW                              // one piece per "page"
            let contentW    = colW * CGFloat(pieces.count)
            let viewportW   = colW * 3
            let maxOffset   = max(0, contentW - viewportW)      // how far we can scroll left
            let liveOffset  = carouselOffset + carouselDrag

            HStack(spacing: 0) {
                ForEach(pieces, id: \.id) { piece in
                    BlockView(
                        piece: piece, cellSize: cs,
                        isInvalid: viewModel.invalidPieceIDs.contains(piece.id),
                        isDragging: false
                    )
                    .opacity(draggingPiece?.id == piece.id ? 0.0 : 1.0)
                    .frame(width: colW, height: totalH)
                }
            }
            .frame(width: contentW, alignment: .leading)
            .offset(x: liveOffset)
            .frame(width: viewportW, alignment: .leading)
            .clipped()
            .contentShape(Rectangle())
            .background(
                GeometryReader { g in
                    Color.clear
                        .onAppear  { trayViewportFrame = g.frame(in: .named("gameLayout")) }
                        .onChange(of: g.frame(in: .named("gameLayout"))) { _, f in
                            trayViewportFrame = f
                        }
                }
            )
            .highPriorityGesture(
                carouselGesture(pieces: pieces, colW: colW,
                                pageW: pageW, maxOffset: maxOffset)
            )
        }
    }

    private var trayHeader: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("game.tray.remaining")
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
            Text(verbatim: "\(viewModel.unplacedPieces.count)")
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.primary)
            Spacer()
            // Gem + gold balances — shown here, right above the power-up bar where
            // they're spent, so the player always sees what they can afford.
            HStack(spacing: AppSpacing.sm) {
                currencyTag(.gem)
                currencyTag(.coin)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    /// Compact balance tag (illustrated currency icon + amount) for the tray header.
    private func currencyTag(_ currency: Currency) -> some View {
        let amount = WalletStore.shared.balance(of: currency)
        return HStack(spacing: 3) {
            CurrencyIcon(currency: currency, size: 16)
            Text(verbatim: "\(amount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppColors.onSurface)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.35), value: amount)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(amount) " + NSLocalizedString(currency.displayNameKey, comment: "")))
    }

    // MARK: — Placed-piece drag handle

    /// Transparent hit area placed over a board piece. Initiates relift on drag.
    private func placedPieceHandle(piece: Piece, placement: Placement, cs: CGFloat) -> some View {
        let pw = CGFloat(TrayLayout.pieceWidth(piece))
        let ph = CGFloat(TrayLayout.pieceHeight(piece))
        // Cell-accurate hit area: only the piece's FILLED cells are grabbable, so
        // an L/T-shaped neighbour's bounding box can't steal taps meant for the
        // piece sitting in its concave gap (fixes "grabs the wrong placed piece").
        return Color.clear
            .frame(width: pw * cs, height: ph * cs)
            .pieceHitArea(piece)
            .offset(x: CGFloat(placement.origin.x) * cs,
                    y: CGFloat(placement.origin.y) * cs)
            .highPriorityGesture(reliftGesture(for: piece))
    }

    // MARK: — Shared snap update (lift-aware + juicy hover feedback)

    /// Recomputes the snap target from the lifted finger position and layers the
    /// tactile feedback: a firm tick when the piece first enters the board, a soft
    /// selection tick each time it hovers to a new cell. One code path for all
    /// three drag gestures (tray / carousel / re-drag).
    private func updateSnap(for piece: Piece, at location: CGPoint) {
        let newSnap = SnapCalculator.snap(
            at: liftedPos(location),
            piece: piece,
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSize: (width: viewModel.level.width, height: viewModel.level.height)
        )
        guard newSnap != snapCoord else { return }
        if newSnap != nil && snapCoord == nil {
            HapticService.shared.impact(.medium)   // entered the board
            SoundService.shared.play(.snap)
        } else if newSnap != nil {
            HapticService.shared.selection()        // hovered to a new cell
        }
        snapCoord = newSnap
    }

    // MARK: — Tray drag gesture
    // H-2: Reduce Motion — replace .spring with .none for all placement animations.

    private func dragGesture(for piece: Piece) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("gameLayout"))
            .onChanged { value in
                if draggingPiece == nil {
                    draggingPiece = piece
                    dragPosition  = value.location   // seed (no tilt spike on pick)
                    dragTilt      = 0
                    HapticService.shared.prepareImpact()
                    HapticService.shared.impact(.light)   // "lift into hand"
                    SoundService.shared.play(.click)
                }
                setDragPosition(value.location)
                updateSnap(for: piece, at: value.location)
            }
            .onEnded { _ in
                if let coord = snapCoord {
                    let animation: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
                    withAnimation(animation) {
                        viewModel.tryPlace(pieceID: piece.id, at: coord)
                    }
                    if viewModel.invalidPieceIDs.contains(piece.id) {
                        triggerInvalidFeedback()
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(400))
                            viewModel.clearInvalid(pieceID: piece.id)
                        }
                    } else if !viewModel.isSolved {
                        SoundService.shared.play(.place)
                        HapticService.shared.impact(.rigid)   // satisfying "thunk"
                        registerCombo()
                    }
                }
                let resetAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.80)
                withAnimation(resetAnimation) {
                    draggingPiece = nil
                    snapCoord     = nil
                    dragTilt      = 0
                }
            }
    }

    // MARK: — Carousel gesture (custom paged tray)
    // A single DragGesture on the carousel viewport. On the FIRST significant
    // movement it locks into one of two modes and stays there for the whole drag:
    //
    //   • |dx| dominates                → .scrolling : pan the row horizontally,
    //                                     snap to the nearest page on release.
    //   • upward & |dy| dominates       → .picking   : identify the piece under
    //                                     the finger and drag it onto the grid
    //                                     (same place/snap logic as the tray).
    //
    // Because we own the horizontal offset (no ScrollView), there is no recognizer
    // to compete with — horizontal swipes always scroll, upward drags always pick.

    private func carouselGesture(pieces: [Piece], colW: CGFloat,
                                 pageW: CGFloat, maxOffset: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("gameLayout"))
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                // Decide the mode once, on the first qualifying movement.
                if trayGestureMode == .undecided {
                    if abs(dx) > abs(dy) {
                        trayGestureMode = .scrolling
                    } else if dy < 0 {                       // moving upward → pick up
                        trayGestureMode = .picking
                        // Identify which piece sits under the touch start point.
                        let localX = value.startLocation.x - trayViewportFrame.minX
                        let contentX = localX - carouselOffset
                        let idx = max(0, min(pieces.count - 1, Int(contentX / colW)))
                        let piece = pieces[idx]
                        draggingPiece = piece
                        dragPosition  = value.startLocation   // seed
                        dragTilt      = 0
                        HapticService.shared.prepareImpact()
                        HapticService.shared.impact(.light)
                        SoundService.shared.play(.click)
                    } else {
                        // Downward-only drag: ignore (don't scroll, don't pick).
                        return
                    }
                }

                switch trayGestureMode {
                case .scrolling:
                    // Rubber-band clamp: allow a little overscroll past the ends.
                    let raw = dx
                    let projected = carouselOffset + raw
                    let clamped: CGFloat
                    if projected > 0 {
                        clamped = projected * 0.35
                    } else if projected < -maxOffset {
                        clamped = -maxOffset + (projected + maxOffset) * 0.35
                    } else {
                        clamped = projected
                    }
                    carouselDrag = clamped - carouselOffset

                case .picking:
                    guard let piece = draggingPiece else { return }
                    setDragPosition(value.location)
                    updateSnap(for: piece, at: value.location)

                case .undecided:
                    break
                }
            }
            .onEnded { value in
                let mode = trayGestureMode
                trayGestureMode = .undecided

                switch mode {
                case .scrolling:
                    // Commit the current visual position into carouselOffset and
                    // zero the live drag TOGETHER, so liveOffset stays unchanged
                    // (no jump back to the drag's start point), then animate the
                    // snap to the nearest page from there.
                    let settled = carouselOffset + carouselDrag
                    carouselOffset = settled
                    carouselDrag   = 0
                    let page = (-settled / pageW).rounded()
                    let maxPage = (maxOffset / pageW).rounded(.up)
                    let clampedPage = max(0, min(maxPage, page))
                    let target = max(-maxOffset, min(0, -clampedPage * pageW))
                    let anim: Animation? = reduceMotion ? nil
                        : .spring(response: 0.32, dampingFraction: 0.85)
                    withAnimation(anim) {
                        carouselOffset = target
                    }

                case .picking:
                    guard let piece = draggingPiece else { return }
                    if let coord = snapCoord {
                        let anim: Animation? = reduceMotion ? nil
                            : .spring(response: 0.3, dampingFraction: 0.75)
                        withAnimation(anim) {
                            viewModel.tryPlace(pieceID: piece.id, at: coord)
                        }
                        if viewModel.invalidPieceIDs.contains(piece.id) {
                            triggerInvalidFeedback()
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(400))
                                viewModel.clearInvalid(pieceID: piece.id)
                            }
                        } else if !viewModel.isSolved {
                            SoundService.shared.play(.place)
                            HapticService.shared.impact(.rigid)
                            registerCombo()
                        }
                    }
                    let anim: Animation? = reduceMotion ? nil
                        : .spring(response: 0.35, dampingFraction: 0.80)
                    withAnimation(anim) {
                        draggingPiece = nil
                        snapCoord     = nil
                        dragTilt      = 0
                    }

                case .undecided:
                    break
                }
            }
    }

    // MARK: — Re-drag gesture (placed-piece → relift → drop or rollback)

    private func reliftGesture(for piece: Piece) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named("gameLayout"))
            .onChanged { value in
                if draggingPiece == nil {
                    // Note: do NOT lift (remove placement) here — that would
                    // destroy this gesture's host view mid-drag and onEnded
                    // would never fire (frozen overlay bug). The piece is
                    // hidden via GridView's draggingPieceID; the actual lift
                    // happens in onEnded once the gesture has settled.
                    draggingPiece = piece
                    dragPosition  = value.location   // seed
                    dragTilt      = 0
                    HapticService.shared.prepareImpact()
                    HapticService.shared.impact(.light)
                    SoundService.shared.play(.click)
                }
                setDragPosition(value.location)
                updateSnap(for: piece, at: value.location)
            }
            .onEnded { _ in
                // Lift now (remove + snapshot) so re-placement validity ignores
                // the piece's own original cells; safe here because the gesture
                // has already ended.
                viewModel.liftPiece(pieceID: piece.id)
                if let coord = snapCoord {
                    let dropAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
                    withAnimation(dropAnimation) {
                        viewModel.tryPlace(pieceID: piece.id, at: coord)
                    }
                    if viewModel.invalidPieceIDs.contains(piece.id) {
                        // Invalid drop: restore piece to original board position
                        triggerInvalidFeedback()
                        let rollbackAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
                        withAnimation(rollbackAnimation) {
                            viewModel.rollbackLift()
                            viewModel.clearInvalid(pieceID: piece.id)
                        }
                    } else if !viewModel.isSolved {
                        viewModel.commitLift()
                        SoundService.shared.play(.place)
                        HapticService.shared.impact(.rigid)
                    } else {
                        viewModel.commitLift()
                    }
                } else {
                    // Released outside grid: rollback to original position
                    let rollbackAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.80)
                    withAnimation(rollbackAnimation) {
                        viewModel.rollbackLift()
                    }
                    triggerInvalidFeedback()
                }
                let resetAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.80)
                withAnimation(resetAnimation) {
                    draggingPiece = nil
                    snapCoord     = nil
                    dragTilt      = 0
                }
            }
    }

    // MARK: — Timer

    // MARK: — Countdown helpers

    /// Endless = a procedurally-generated, never-ending relaxed run.
    private var isEndless: Bool { levelId.hasPrefix("endless") }
    /// Tower = ticket-gated, one-mistake climb.
    private var isTower: Bool { levelId.hasPrefix("tower") }
    /// Resume only applies to deterministic levels (campaign + daily). Endless/Tower
    /// roll a fresh random seed each load, so a saved board wouldn't match.
    private var isResumable: Bool { !isEndless && !isTower }
    private var towerFloor: Int { Int(levelId.split(separator: "-").last ?? "1") ?? 1 }
    /// Relaxed = no timer/fail (Zen mode OR Endless). Tower is NOT relaxed: it has
    /// a real countdown and you're eliminated if it runs out (wrong placements are
    /// harmless — only the clock ends the climb).
    private var relaxed: Bool { zenMode || isEndless }

    /// Time allowed per level. Campaign: ~5 s/cell (min 90). Tower: tighter
    /// (~3 s/cell) and shrinks as you climb → escalating time pressure.
    private var timeLimitSeconds: Int {
        let cells = viewModel.level.width * viewModel.level.height
        if isTower {
            return max(25, cells * 3 - (towerFloor - 1) * 3)
        }
        return max(90, cells * 5)
    }

    private var remainingSeconds: Int {
        max(0, timeLimitSeconds - elapsedSeconds)
    }

    private var timerIsUrgent: Bool { !relaxed && remainingSeconds > 0 && remainingSeconds <= 30 }

    /// Persist (or drop) the in-progress board for resume. No-op for non-resumable
    /// modes (Endless/Tower) and once the level is solved.
    private func saveSession() {
        guard isResumable, !viewModel.isSolved else { return }
        if viewModel.placements.isEmpty {
            GameSessionStore.shared.clear(levelID: levelId)
        } else {
            GameSessionStore.shared.save(viewModel.makeSession(elapsedSeconds: elapsedSeconds))
        }
    }

    // MARK: — Level-complete cover

    @ViewBuilder
    private var levelCompleteCover: some View {
        LevelCompleteSheet(
            stars: 3,
            elapsedSeconds: elapsedSeconds,
            hintsUsed: viewModel.hintsUsed,
            moveCount: viewModel.moveCount,
            bestTimeSeconds: ProgressStore.shared.levelProgress[viewModel.level.id]?.bestTime.map { Int($0) },
            isNewBest: viewModel.newBestTime,
            earnedReward: earnedReward,
            isDaily: dailyIndex != nil,
            dailyIndex: dailyIndex,
            dailyTotal: ProgressStore.dailyLevelCount,
            nextBlockedByEnergy: nextBlockedByEnergy,
            onNext: { goToNextLevel(fireInterstitial: true) },
            onReplay: {
                GameSessionStore.shared.clear(levelID: levelId)   // fresh attempt
                viewModel = GameViewModel.makeFromPackProvider(levelId: levelId)
                elapsedSeconds = 0
                rewardGranted = false
                earnedReward = [:]
                startTimer()
            },
            onNeedEnergy: { resolveNextEnergy() }
        )
        .environment(router)
        // Milestone surprise — shown right inside the level-complete screen (over it)
        // when this clear earned a Nook scene piece. The player can jump straight to
        // the Nook to drag it in, or save it for later.
        .overlay {
            if let reveal = NookRevealCenter.shared.pending {
                NookPieceRevealOverlay(
                    reveal: reveal,
                    onPlace: {
                        NookRevealCenter.shared.dismiss()
                        // Advance the finished level BEHIND the Nook so returning from
                        // it continues the game instead of stranding the player on the
                        // solved board (the "back → stuck" bug). The Nook then
                        // auto-returns here once the piece is placed.
                        showComplete = false
                        advanceBehindNook()
                        NookRevealCenter.shared.autoReturnOnPlace = true
                        router.push(.nook)
                    },
                    onDismiss: { NookRevealCenter.shared.dismiss() }
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: — Next-level navigation

    /// True when advancing to the next level would cost energy the player doesn't
    /// have (campaign / non-last daily, not Endless, not Premium). Drives the
    /// level-complete "Next" button into its out-of-energy state.
    private var nextBlockedByEnergy: Bool {
        if isEndless { return false }                       // Endless is free
        if let idx = dailyIndex {                           // daily: last one → Home, never blocked
            guard idx + 1 < ProgressStore.dailyLevelCount else { return false }
            return !EnergyStore.shared.canStartGame
        }
        guard let nextId = PackProvider.nextLevelId(after: levelId), nextId != levelId
        else { return false }                               // no next level → Next pops, no charge
        return !EnergyStore.shared.canStartGame
    }

    /// Deferred between-level interstitial — presents cleanly OVER the next screen
    /// instead of being torn down by the level-complete cover (the ~0.5s ad flash).
    private func scheduleInterstitial() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            AdsManager.shared.onLevelCompleted()
        }
    }

    /// Advance to the next level (called only when affordable — the button blocks
    /// the out-of-energy case). Endless → next generated; Daily → next daily or Home;
    /// Campaign → next pack level or pop back when there's none.
    private func goToNextLevel(fireInterstitial: Bool) {
        showComplete = false
        if fireInterstitial { scheduleInterstitial() }
        if isEndless {
            let n = (Int(levelId.split(separator: "-").last ?? "1") ?? 1) + 1
            router.replaceTop(with: .game(levelID: "endless-\(n)"))
            return
        }
        if let idx = dailyIndex {
            let next = idx + 1
            if next < ProgressStore.dailyLevelCount {
                router.replaceTop(with: .game(levelID: "daily-\(next)"))
            } else {
                router.popToRoot()
            }
            return
        }
        // v1.1.4: only navigate to a genuinely different next level; re-pushing the
        // same id is a no-op that leaves the solved board on screen. None → pop back.
        guard let nextId = PackProvider.nextLevelId(after: levelId), nextId != levelId else {
            router.pop()
            return
        }
        router.replaceTop(with: .game(levelID: nextId))
    }

    /// Out-of-energy path for the "Next" button: a rewarded ad tops up energy and
    /// continues; with no ad available we send the player Home and offer Premium —
    /// never leaving them stranded on the solved board.
    private func resolveNextEnergy() {
        if AdsManager.shared.rewardedReady {
            AdsManager.shared.showRewarded {
                EnergyStore.shared.addEnergy(10)
                RewardCenter.shared.showEnergy(10)
                goToNextLevel(fireInterstitial: false)   // now affordable → advances
            }
        } else {
            showComplete = false
            router.popToRoot()
            router.showPaywall = true
        }
    }

    /// Continue the game behind the Nook after placing a milestone piece. Advances
    /// to the next level when affordable, otherwise returns Home — so popping out of
    /// the Nook never lands on the finished board.
    private func advanceBehindNook() {
        if isEndless {
            let n = (Int(levelId.split(separator: "-").last ?? "1") ?? 1) + 1
            router.replaceTop(with: .game(levelID: "endless-\(n)"))
            return
        }
        if let idx = dailyIndex {
            let next = idx + 1
            if next < ProgressStore.dailyLevelCount, EnergyStore.shared.canStartGame {
                router.replaceTop(with: .game(levelID: "daily-\(next)"))
            } else {
                router.popToRoot()
            }
            return
        }
        if let nextId = PackProvider.nextLevelId(after: levelId), nextId != levelId,
           EnergyStore.shared.canStartGame {
            router.replaceTop(with: .game(levelID: nextId))
        } else {
            router.popToRoot()
        }
    }

    private func startTimer() {
        // Faz I-2: skip timer in XCUITest runs — constant accessibility tree updates
        // from the 1-second tick cause XCUITest snapshot queries to time out.
        guard !UserDefaults.standard.bool(forKey: "snuglo.uitestmode") else { return }
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                elapsedSeconds += 1
                // Countdown hit zero. Never in Zen/Endless (no fail). Tower → the
                // climb ends (eliminated); campaign/daily → the fail sheet.
                if !relaxed, elapsedSeconds >= timeLimitSeconds, !viewModel.isSolved,
                   !showWaveAnimation, !showComplete {
                    timerTask?.cancel()
                    HapticService.shared.notify(.error)
                    if isTower {
                        viewModel.failTower()       // out of time → eliminated
                    } else {
                        ProgressStore.shared.breakChain()   // time ran out → chain broken
                        showFail = true
                    }
                    break
                }
            }
        }
    }

    /// Endless only: discard the current generated puzzle, load the next one.
    private func skipEndless() {
        HapticService.shared.impact(.light)
        SoundService.shared.play(.click)
        let n = (Int(levelId.split(separator: "-").last ?? "1") ?? 1) + 1
        router.replaceTop(with: .game(levelID: "endless-\(n)"))
    }

    private func pauseGame() {
        timerTask?.cancel()
        showPause = true
    }

    /// Rebuild the level for a fresh attempt (board cleared, clock zeroed, chain
    /// broken). Safe to call any time — it (re)starts the timer itself.
    private func restartLevel() {
        GameSessionStore.shared.clear(levelID: levelId)
        viewModel = GameViewModel.makeFromPackProvider(levelId: levelId)
        elapsedSeconds = 0
        showFail = false
        rewardGranted = false
        earnedReward = [:]
        ProgressStore.shared.breakChain()   // restart mid-play → chain broken
        // onAppear won't run again, so surface the "−5 ⚡" spend flourish here.
        let spent = EnergyStore.shared.consumeSpendAnimation()
        if spent > 0 { energySpendAmount = spent }
        startTimer()
    }

    /// Pause → Restart. A restart is a NEW paid attempt, so it costs energy (unless
    /// the mode is free or the player is Premium). Out of energy → a rewarded ad tops
    /// up and restarts; with no ad available, offer Premium and keep the current board
    /// (the pause sheet's dismissal resumes its timer).
    private func restartFromPause() {
        let free = relaxed || isTower
        if free || EnergyStore.shared.chargeRestart(levelID: levelId) {
            restartLevel()
        } else if AdsManager.shared.rewardedReady {
            AdsManager.shared.showRewarded {
                EnergyStore.shared.addEnergy(10)
                RewardCenter.shared.showEnergy(10)
                _ = EnergyStore.shared.chargeRestart(levelID: levelId)
                restartLevel()
            }
        } else {
            router.showPaywall = true
        }
    }

    private func presentQuitConfirmation() {
        HapticService.shared.impact(.light)
        showQuitConfirmation = true
    }

    private func dismissQuitConfirmation() {
        showQuitConfirmation = false
    }

    // MARK: — Helpers

    private var formattedTimer: String {
        // Zen: count UP (elapsed) — no pressure. Otherwise: countdown remaining.
        let t = relaxed ? elapsedSeconds : remainingSeconds
        let m = t / 60
        let s = t % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// 0-based index of the current daily level, or nil for pack levels.
    private var dailyIndex: Int? {
        levelId.hasPrefix("daily") ? PackProvider.dailyIndex(from: levelId) : nil
    }

    /// HUD title. Daily shows "Günün Bulmacası N/5" so the player always sees
    /// which daily level they're on; pack levels show "Level N".
    private var levelDisplayName: String {
        if let idx = dailyIndex {
            let base = NSLocalizedString("game.title.daily", comment: "")
            return "\(base) \(idx + 1)/\(ProgressStore.dailyLevelCount)"
        }
        let parts = levelId.split(separator: "-")
        let n = parts.last.flatMap { Int($0) } ?? 0
        if isEndless { return "Endless \(n)" }
        return "Level \(n)"
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        GameView(levelId: "cozy-beginnings-1")
    }
    .environment(AppRouter())
}
