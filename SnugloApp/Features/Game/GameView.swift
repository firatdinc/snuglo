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

    private func overlayOffset(for piece: Piece) -> CGPoint {
        let halfW = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1) * cellSize / 2
        let halfH = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1) * cellSize / 2
        return CGPoint(x: dragPosition.x - halfW, y: dragPosition.y - halfH)
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
                    .offset(x: off.x, y: off.y)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true) // overlay duplicate; original already labelled
                }
            }
            .frame(width: rootGeo.size.width, height: rootGeo.size.height, alignment: .top)
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
                    // startTimer() is called via onDismiss after sheet dismisses
                },
                onQuit: { router.pop() },
                elapsedSeconds: elapsedSeconds
            )
            .environment(router)
        })
        .fullScreenCover(isPresented: $showComplete) {
            LevelCompleteSheet(
                stars: 3,
                elapsedSeconds: elapsedSeconds,
                hintsUsed: viewModel.hintsUsed,
                moveCount: viewModel.moveCount,
                bestTimeSeconds: ProgressStore.shared.levelProgress[viewModel.level.id]?.bestTime.map { Int($0) },
                earnedReward: earnedReward,
                // v1.1.3: Next Level resolution
                //   • Pack levels  → next index in the same pack
                //   • Daily puzzle → user's current continue level (so
                //     "Sonraki seviye" always leads to *something* to play)
                //   • Pack end / no continue → pop back to PackDetail/MainMenu
                onNext: {
                    showComplete = false
                    let resolvedNextId: String?
                    if levelId == "daily" {
                        resolvedNextId = PackProvider.continueLevel()?.id
                    } else {
                        resolvedNextId = PackProvider.nextLevelId(after: levelId)
                    }
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
        // v1.1.3: confirmation before quitting — preserves in-progress puzzle
        .confirmationDialog(
            "game.quitConfirm.title",
            isPresented: $showQuitConfirmation,
            titleVisibility: .visible
        ) {
            Button("game.quitConfirm.confirm", role: .destructive) {
                router.pop()
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("game.quitConfirm.message")
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
                showComplete = true
            }
        }
    }

    // MARK: — Main layout

    private var mainLayout: some View {
        VStack(spacing: AppSpacing.md) {
            gameHUD
            progressRow

            // Faz 3: Power-up bar between HUD and puzzle grid
            PowerUpBar(viewModel: viewModel) {
                showInsufficientGemBanner = true
            }

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

            mascotBadge

            // Board + tray share ONE measured region and are split
            // proportionally (board ≥ ~58%, tray ≤ ~42%). No chrome-height
            // estimate, so it can't starve the board on tall-piece levels, and
            // the tray pieces shrink-to-fit their share (never clipped).
            boardAndTrayRegion
        }
        .padding(.vertical, AppSpacing.lg)
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
                    .frame(maxWidth: .infinity, alignment: .center)
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

    /// Pure split math (testable shape): board square + tray content height that
    /// together fit the region, with the board favoured and the tray capped.
    private func regionSplit(width regionW: CGFloat, height regionH: CGFloat) -> RegionSplit {
        let w = CGFloat(viewModel.level.width)
        let h = CGFloat(viewModel.level.height)
        let spacing = AppSpacing.md
        let trayHeaderH: CGFloat = 30          // header label + xs gap
        let boardMaxW = max(0, regionW - AppSpacing.lg * 2)

        // Comfortable tray content needed for ALL pieces at a board-relative cell
        // (constant per level → stable).
        let approxCell = boardMaxW / max(1, w)
        let innerTrayW = max(0, regionW - AppSpacing.lg * 4)
        let neededContent = TrayLayout.compute(
            pieces: viewModel.level.pieces,
            availableWidth: innerTrayW,
            preferredCellSize: approxCell * 0.6,
            itemSpacing: spacing
        ).contentHeight + AppSpacing.sm * 2

        let vBudget = max(0, regionH - spacing - trayHeaderH)
        // Tray gets what it needs but never more than ~42% of the budget — the
        // board keeps the majority. Shrink-to-fit handles the capped case.
        let trayContentH = max(0, min(neededContent, vBudget * 0.42))
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
            GridView(
                level: viewModel.level,
                placements: viewModel.placements,
                invalidPieceIDs: viewModel.invalidPieceIDs,
                snapCoord: snapCoord,
                snapIsInvalid: snapIsInvalid,
                draggingPieceID: draggingPiece?.id
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
            Button { showQuitConfirmation = true } label: {
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

            // Pack name + "Level N" subtitle
            VStack(spacing: 2) {
                Text(verbatim: packDisplayName)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                    .lineLimit(1)
                Text(levelDisplayNameKey)
                    .font(AppTypography.labelSmall)
                    .tracking(0.4)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            .accessibilityHidden(true)

            Spacer()

            HStack(spacing: AppSpacing.sm) {
                // Timer — blue capsule pill with clock icon
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                    Text(formattedTimer)
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, AppSpacing.sm + 2)
                .padding(.vertical, AppSpacing.xs + 2)
                .background(AppColors.primary, in: Capsule())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(levelDisplayName), elapsed time \(formattedTimer)")
                // Faz I-2: UITest identifier for timer display
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
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("pack.progress")
                    .font(AppTypography.labelSmall)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                Spacer()
                Text("\(Int(placedFraction * 100))%")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.surfaceContainerHigh)
                        .frame(height: 8)
                    if placedFraction > 0 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * placedFraction, height: 8)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityHidden(true)
    }

    // MARK: — Tray

    /// Tray with a caller-provided content height (from the region split). Pieces
    /// are shrink-to-fit into that height (and width) so they're never clipped,
    /// for any level or piece shape, with no scrolling.
    private func trayBody(contentHeight: CGFloat, cell: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            trayHeader

            VStack(spacing: 0) {
                GeometryReader { geo in
                    let innerWidth = max(0, geo.size.width - AppSpacing.lg * 2)
                    let innerHeight = max(0, geo.size.height - AppSpacing.sm * 2)
                    // Fit cell computed against the FULL (constant) piece set so
                    // the piece size stays stable all game long; render only the
                    // unplaced subset, which is therefore guaranteed to fit too.
                    let fitCell = trayFitCell(
                        pieces: viewModel.level.pieces,
                        availableWidth: innerWidth,
                        availableHeight: innerHeight,
                        cap: cell * 0.6
                    )
                    let layout = TrayLayout.compute(
                        pieces: viewModel.unplacedPieces,
                        availableWidth: innerWidth,
                        preferredCellSize: fitCell,
                        itemSpacing: AppSpacing.md
                    )
                    VStack(alignment: .center, spacing: AppSpacing.md) {
                        ForEach(Array(layout.rows.enumerated()), id: \.offset) { _, row in
                            HStack(alignment: .center, spacing: AppSpacing.md) {
                                ForEach(row, id: \.id) { piece in
                                    BlockView(
                                        piece: piece,
                                        cellSize: layout.cellSize,
                                        isInvalid: viewModel.invalidPieceIDs.contains(piece.id),
                                        isDragging: false
                                    )
                                    .opacity(draggingPiece?.id == piece.id ? 0.0 : 1.0)
                                    .gesture(dragGesture(for: piece))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(height: max(44, contentHeight))
            .background(AppColors.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .shadowL1()
        }
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Piece tray. \(viewModel.unplacedPieces.count) pieces remaining.")
    }

    /// Largest cell size (≤ `cap`) at which ALL `pieces` fit inside the fixed
    /// tray — both across its width (TrayLayout wraps to rows) and within its
    /// height (`contentHeight ≤ availableHeight`). Binary search: content height
    /// is monotonic in cell size (smaller cell ⇒ more pieces per row ⇒ fewer,
    /// shorter rows), so this converges to the exact largest fitting cell and
    /// GUARANTEES no piece is ever clipped, for any level or piece shape.
    private func trayFitCell(
        pieces: [Piece],
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        cap: CGFloat
    ) -> CGFloat {
        guard !pieces.isEmpty, availableWidth > 0, availableHeight > 0 else { return cap }
        func contentHeight(_ c: CGFloat) -> CGFloat {
            TrayLayout.compute(
                pieces: pieces,
                availableWidth: availableWidth,
                preferredCellSize: c,
                itemSpacing: AppSpacing.md
            ).contentHeight
        }
        if contentHeight(cap) <= availableHeight { return cap }
        var lo: CGFloat = 4   // floor — any real piece fits a tray at 4pt cells
        var hi = cap
        for _ in 0..<24 {
            let mid = (lo + hi) / 2
            if contentHeight(mid) <= availableHeight { lo = mid } else { hi = mid }
        }
        return lo
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
            .gesture(reliftGesture(for: piece))
    }

    // MARK: — Tray drag gesture
    // H-2: Reduce Motion — replace .spring with .none for all placement animations.

    private func dragGesture(for piece: Piece) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("gameLayout"))
            .onChanged { value in
                if draggingPiece == nil {
                    draggingPiece = piece
                    HapticService.shared.prepareImpact()
                    SoundService.shared.play(.click)
                }
                dragPosition = value.location
                let newSnap = SnapCalculator.snap(
                    at: value.location,
                    piece: piece,
                    gridFrame: gridFrame,
                    cellSize: cellSize,
                    gridSize: (width: viewModel.level.width, height: viewModel.level.height)
                )
                if newSnap != nil && snapCoord == nil {
                    HapticService.shared.impact(.medium)
                    SoundService.shared.play(.snap)
                }
                snapCoord = newSnap
            }
            .onEnded { _ in
                if let coord = snapCoord {
                    let animation: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
                    withAnimation(animation) {
                        viewModel.tryPlace(pieceID: piece.id, at: coord)
                    }
                    if viewModel.invalidPieceIDs.contains(piece.id) {
                        SoundService.shared.play(.error)
                        HapticService.shared.notify(.error)
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(400))
                            viewModel.clearInvalid(pieceID: piece.id)
                        }
                    } else if !viewModel.isSolved {
                        SoundService.shared.play(.place)
                        HapticService.shared.impact(.light)
                    }
                }
                let resetAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.80)
                withAnimation(resetAnimation) {
                    draggingPiece = nil
                    snapCoord     = nil
                }
            }
    }

    // MARK: — Re-drag gesture (placed-piece → relift → drop or rollback)

    private func reliftGesture(for piece: Piece) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("gameLayout"))
            .onChanged { value in
                if draggingPiece == nil {
                    // Note: do NOT lift (remove placement) here — that would
                    // destroy this gesture's host view mid-drag and onEnded
                    // would never fire (frozen overlay bug). The piece is
                    // hidden via GridView's draggingPieceID; the actual lift
                    // happens in onEnded once the gesture has settled.
                    draggingPiece = piece
                    HapticService.shared.prepareImpact()
                    SoundService.shared.play(.click)
                }
                dragPosition = value.location
                let newSnap = SnapCalculator.snap(
                    at: value.location,
                    piece: piece,
                    gridFrame: gridFrame,
                    cellSize: cellSize,
                    gridSize: (width: viewModel.level.width, height: viewModel.level.height)
                )
                if newSnap != nil && snapCoord == nil {
                    HapticService.shared.impact(.medium)
                    SoundService.shared.play(.snap)
                }
                snapCoord = newSnap
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
                        SoundService.shared.play(.error)
                        HapticService.shared.notify(.error)
                        let rollbackAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
                        withAnimation(rollbackAnimation) {
                            viewModel.rollbackLift()
                            viewModel.clearInvalid(pieceID: piece.id)
                        }
                    } else if !viewModel.isSolved {
                        viewModel.commitLift()
                        SoundService.shared.play(.place)
                        HapticService.shared.impact(.light)
                    } else {
                        viewModel.commitLift()
                    }
                } else {
                    // Released outside grid: rollback to original position
                    let rollbackAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.80)
                    withAnimation(rollbackAnimation) {
                        viewModel.rollbackLift()
                    }
                    HapticService.shared.notify(.error)
                    SoundService.shared.play(.error)
                }
                let resetAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.80)
                withAnimation(resetAnimation) {
                    draggingPiece = nil
                    snapCoord     = nil
                }
            }
    }

    // MARK: — Timer

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
            }
        }
    }

    private func pauseGame() {
        timerTask?.cancel()
        showPause = true
    }

    // MARK: — Helpers

    private var formattedTimer: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// v1.1.3: localized display name for the HUD title. Daily puzzle gets
    /// its own localization key; pack levels show "Level N" formatted from
    /// the trailing integer in the id.
    private var levelDisplayNameKey: LocalizedStringKey {
        if levelId == "daily" { return "game.title.daily" }
        let parts = levelId.split(separator: "-")
        let n = parts.last.flatMap { Int($0) } ?? 0
        return LocalizedStringKey("Level \(n)")
    }

    /// Plain-string fallback for accessibility labels and analytics.
    private var levelDisplayName: String {
        if levelId == "daily" { return NSLocalizedString("game.title.daily", comment: "") }
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
