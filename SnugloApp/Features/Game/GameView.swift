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
    /// Solve wave: true while the diagonal cell-wave animation plays after solve.
    @State private var showWaveAnimation = false
    /// Shown when the countdown hits zero without solving.
    @State private var showFail = false

    /// Zen / Relax mode (research: the #1 loved feature of the genre). When on,
    /// the timer becomes a calm count-UP and the level can never fail on time.
    @AppStorage("zenMode") private var zenMode = false

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

    /// Invalid drop: error sound + haptic + a quick red wash over the board.
    private func triggerInvalidFeedback() {
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
            }
            .frame(width: rootGeo.size.width, height: rootGeo.size.height, alignment: .top)
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
                onRestart: {
                    viewModel = GameViewModel.makeFromPackProvider(levelId: levelId)
                    elapsedSeconds = 0
                    showFail = false
                    rewardGranted = false
                    // startTimer() is called via onDismiss after sheet dismisses
                },
                onQuit: { router.pop() },
                elapsedSeconds: elapsedSeconds
            )
            .environment(router)
        })
        .overlay {
            if showFail {
                LevelFailSheet(
                    onRetry: {
                        showFail = false
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
        .fullScreenCover(isPresented: $showComplete) {
            LevelCompleteSheet(
                stars: 3,
                elapsedSeconds: elapsedSeconds,
                hintsUsed: viewModel.hintsUsed,
                moveCount: viewModel.moveCount,
                bestTimeSeconds: ProgressStore.shared.levelProgress[viewModel.level.id]?.bestTime.map { Int($0) },
                earnedReward: earnedReward,
                isDaily: dailyIndex != nil,
                dailyIndex: dailyIndex,
                dailyTotal: ProgressStore.dailyLevelCount,
                // Next Level resolution
                //   • Pack levels  → next index in the same pack
                //   • Daily        → next daily level (daily-N+1) until the day's
                //     set is finished, then Home (the card locks until tomorrow).
                //   • Pack end / no continue → pop back to PackDetail/MainMenu
                onNext: {
                    showComplete = false
                    // Daily: advance to the next daily level, or Home if this was
                    // the last one for today.
                    if let idx = dailyIndex {
                        let next = idx + 1
                        if next < ProgressStore.dailyLevelCount {
                            router.replaceTop(with: .game(levelID: "daily-\(next)"))
                        } else {
                            router.popToRoot()
                        }
                        return
                    }
                    let resolvedNextId: String? = PackProvider.nextLevelId(after: levelId)
                    // v1.1.4 bug fix: only navigate when there's a genuinely
                    // DIFFERENT next level. Re-pushing the current levelId is a
                    // no-op path mutation (NavigationStack sees no change), so
                    // the GameView is never recreated and the just-solved board
                    // stays on screen looking like the "next" level finished
                    // instantly. In that case (or no next level) pop back.
                    guard let nextId = resolvedNextId, nextId != levelId else {
                        router.pop()
                        return
                    }
                    // Replace the top of the CURRENT TAB's stack (the game
                    // lives in e.g. playPath, NOT the outer `router.path`).
                    // Mutating the wrong array was a no-op, which left the
                    // just-finished board on screen. Back still returns to
                    // PackDetail / MainMenu.
                    router.replaceTop(with: .game(levelID: nextId))
                },
                onReplay: {
                    viewModel = GameViewModel.makeFromPackProvider(levelId: levelId)
                    elapsedSeconds = 0
                    rewardGranted = false
                    earnedReward = [:]
                    startTimer()
                }
            )
            .environment(router)
        }
        .onAppear {
            router.isGameActive = true
            startTimer()
            // Pre-warm audio + haptics OFF the gesture path so the first piece
            // drag is instant (was freezing 3–5s while AVAudioSession activated
            // on the main thread during the gesture → "gesture gate timed out").
            SoundService.shared.warmUp()
            HapticService.shared.prepareImpact()
        }
        .onDisappear {
            router.isGameActive = false
            timerTask?.cancel()
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
                    AdsManager.shared.showRewarded {
                        let anim: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
                        withAnimation(anim) {
                            viewModel.undoLastMove()
                        }
                        HapticService.shared.impact(.light)
                        SoundService.shared.play(.place)
                    }
                },
                onDismiss: { showUndoRewardedSheet = false }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.isSolved) { _, solved in
            if solved {
                timerTask?.cancel()
                SoundService.shared.play(.solve)
                HapticService.shared.notify(.success)
                AdsManager.shared.onLevelCompleted()
                if !rewardGranted {
                    rewardGranted = true
                    let prevBest = ProgressStore.shared.levelProgress[viewModel.level.id]?.bestTime.map { Int($0) }
                    let reward = CurrencyReward.forLevelComplete(
                        stars: 3,
                        elapsedSeconds: elapsedSeconds,
                        previousBestSeconds: prevBest
                    )
                    earnedReward = reward
                    for (currency, amount) in reward { WalletStore.shared.earn(currency, amount: amount) }
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
                onUndoRewarded:    { showUndoRewardedSheet = true }
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

    /// Sloth badge floating above the puzzle grid.
    private var mascotBadge: some View {
        Image("mascot-sloth")
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
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
                                showComplete = true
                            }
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                        }
                    }
                    // fills remaining vertical space so tray stays at bottom
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
                                    paused: draggingPiece == nil || reduceMotion)) { tl in
                let pulse: CGFloat = (draggingPiece == nil || reduceMotion)
                    ? 0
                    : CGFloat(0.5 + 0.5 * sin(tl.date.timeIntervalSinceReferenceDate * 4.2))
                GridView(
                    level: viewModel.level,
                    placements: viewModel.placements,
                    invalidPieceIDs: viewModel.invalidPieceIDs,
                    snapCoord: snapCoord,
                    snapIsInvalid: snapIsInvalid,
                    draggingPieceID: draggingPiece?.id,
                    snapPulse: pulse
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
        // iOS 26: identifier on the ZStack wrapper — Canvas (GridView) is
        // accessibility-opaque, so the identifier must live on an ancestor
        // with real visual bounds and .ignore semantics.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Puzzle grid")
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
            .accessibilityLabel("Back")
            .accessibilityHint("Returns to the previous screen")
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
                    Image(systemName: zenMode ? "leaf.fill" : (timerIsUrgent ? "exclamationmark.circle.fill" : "clock.fill"))
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
                .accessibilityLabel("\(levelDisplayName), remaining time \(formattedTimer)")
                .accessibilityIdentifier("game.timer")

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
                .accessibilityLabel("Pause")
                .accessibilityHint("Pauses the timer and shows pause options")
                // Faz I-2: updated identifier spec
                .accessibilityIdentifier("button.game.pause")
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Progress bar (piece placement progress)

    private var progressRow: some View {
        HStack(spacing: AppSpacing.sm) {
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
        .accessibilityLabel("Piece tray. \(viewModel.unplacedPieces.count) pieces remaining.")
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
                        .contentShape(PieceCellsShape(piece: piece))
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
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: — Placed-piece drag handle

    /// Transparent hit area placed over a board piece. Initiates relift on drag.
    private func placedPieceHandle(piece: Piece, placement: Placement, cs: CGFloat) -> some View {
        let pw = CGFloat(TrayLayout.pieceWidth(piece))
        let ph = CGFloat(TrayLayout.pieceHeight(piece))
        return Color.clear
            .contentShape(Rectangle())
            .frame(width: pw * cs, height: ph * cs)
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

    /// Time allowed per level: ~5 seconds per cell, minimum 90 s.
    private var timeLimitSeconds: Int {
        max(90, viewModel.level.width * viewModel.level.height * 5)
    }

    private var remainingSeconds: Int {
        max(0, timeLimitSeconds - elapsedSeconds)
    }

    private var timerIsUrgent: Bool { !zenMode && remainingSeconds > 0 && remainingSeconds <= 30 }

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
                // Countdown hit zero — level failed. Never in Zen mode (no fail).
                if !zenMode, elapsedSeconds >= timeLimitSeconds, !viewModel.isSolved {
                    timerTask?.cancel()
                    HapticService.shared.notify(.error)
                    showFail = true
                    break
                }
            }
        }
    }

    private func pauseGame() {
        timerTask?.cancel()
        showPause = true
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
        let t = zenMode ? elapsedSeconds : remainingSeconds
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
