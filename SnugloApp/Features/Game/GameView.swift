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
    /// v1.1.3 UX fix: back button now asks for confirmation before quitting
    /// so the player doesn't lose timer state accidentally.
    @State private var showQuitConfirmation = false

    /// v1.1.1 critical fix: cellSize used to read live `gridFrame`, but
    /// `trayView` also rendered BlockViews using that value. As gridFrame
    /// changed, tray heights changed, which changed available height for
    /// the grid, which changed gridFrame — infinite layout loop (>30k
    /// body renders/sec → navigation push could never visually complete).
    ///
    /// Stable estimate: derive grid width from the SCREEN width minus the
    /// horizontal padding the grid actually has. This value never reads
    /// `gridFrame`, so updating it doesn't trigger more layouts.
    private var cellSize: CGFloat {
        let screenW = UIScreen.main.bounds.width
        let estimatedGridWidth = max(0, screenW - AppSpacing.lg * 2)
        return estimatedGridWidth / CGFloat(viewModel.level.width)
    }

    /// True when the current snap position would result in overlap or OOB.
    /// Drives snap ghost colour in GridView — computed from viewModel, no extra state.
    private var snapIsInvalid: Bool {
        guard let coord = snapCoord, let piece = draggingPiece else { return false }
        return viewModel.wouldOverlapOrOOB(pieceID: piece.id, at: coord)
    }

    /// Dynamic tray content height based on the tallest row at the computed cell size.
    /// Uses a screen-width estimate (same stable approach as cellSize) to avoid layout loops.
    private var trayContentHeight: CGFloat {
        let pieces = viewModel.unplacedPieces
        guard !pieces.isEmpty else { return AppSpacing.sm * 2 + 44 }
        let screenW = UIScreen.main.bounds.width
        // screen margin (lg × 2) + tray horizontal padding (lg × 2)
        let availableW = max(0, screenW - AppSpacing.lg * 4)
        let layout = TrayLayout.compute(
            pieces: pieces,
            availableWidth: availableW,
            preferredCellSize: cellSize * 0.6,
            itemSpacing: AppSpacing.md
        )
        return layout.contentHeight + AppSpacing.sm * 2
    }

    private func overlayOffset(for piece: Piece) -> CGPoint {
        let halfW = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1) * cellSize / 2
        let halfH = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1) * cellSize / 2
        return CGPoint(x: dragPosition.x - halfW, y: dragPosition.y - halfH)
    }

    // MARK: — Body

    var body: some View {
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
        .coordinateSpace(.named("gameLayout"))
        .background(AppColors.background.ignoresSafeArea())
        // iOS 17+ replacement for deprecated .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
                    if let nextId = resolvedNextId {
                        // Atomic path mutation: replace the top entry so the
                        // back button still returns to PackDetail/MainMenu,
                        // not the prior level. Done in one assignment to avoid
                        // a transient empty-stack frame during the animation.
                        var newPath = router.path
                        if !newPath.isEmpty { newPath.removeLast() }
                        newPath.append(.game(levelID: nextId))
                        router.path = newPath
                    } else {
                        router.pop()
                    }
                },
                onReplay: {
                    viewModel = GameViewModel.makeFromPackProvider(levelId: levelId)
                    elapsedSeconds = 0
                    startTimer()
                }
            )
            .environment(router)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear { timerTask?.cancel() }
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
                showComplete = true
            }
        }
    }

    // MARK: — Main layout

    private var mainLayout: some View {
        VStack(spacing: AppSpacing.md) {
            gameHUD

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
                // Faz I-2: UITest identifier for the puzzle grid container.
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("game.grid")

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
            .padding(.horizontal, AppSpacing.lg)

            Spacer(minLength: 0)
            trayView
        }
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: — HUD

    private var gameHUD: some View {
        HStack {
            // Back (v1.1.3: asks for confirmation to prevent accidental quit)
            Button { showQuitConfirmation = true } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surfaceContainerLow, in: Circle())
                    .shadowL1()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityHint("Returns to the previous screen")
            .accessibilityIdentifier("game.back")

            Spacer()

            // Level title + timer (v1.1: timer uses numericLabel = Space Grotesk)
            VStack(spacing: AppSpacing.xs) {
                Text(levelDisplayNameKey)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text(formattedTimer)
                    .font(AppTypography.numericLabel)
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(levelDisplayName), elapsed time \(formattedTimer)")
            // Faz I-2: UITest identifier for timer display
            .accessibilityIdentifier("game.timer")

            Spacer()

            // Hint + Pause group
            HStack(spacing: AppSpacing.sm) {
                // Hint
                let hintCount = ProgressStore.shared.hintCount
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)) {
                        _ = viewModel.applyHint()
                    }
                    SoundService.shared.play(.place)
                    HapticService.shared.impact(.light)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .frame(width: 40, height: 40)
                            .background(AppColors.surfaceContainerLow, in: Circle())
                            .shadowL1()
                        if hintCount > 0 {
                            Text("\(hintCount)")
                                .font(AppTypography.labelSmall)
                                .foregroundStyle(AppColors.onPrimary)
                                .padding(.horizontal, 4)
                                .background(AppColors.primary, in: Capsule())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(hintCount == 0)
                .opacity(hintCount == 0 ? 0.4 : 1.0)
                .accessibilityLabel(LocalizedStringKey("game.hint"))
                .accessibilityIdentifier("button.game.hint")

                // Pause
                Button { pauseGame() } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .frame(width: 40, height: 40)
                        .background(AppColors.surfaceContainerLow, in: Circle())
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

    // MARK: — Tray

    /// IOS-57: trayView now uses TrayLayout for accurate cell-size computation that
    /// accounts for BOTH piece width AND height. Tray height is dynamic so tall pieces
    /// (e.g. 3-row shapes) are never clipped. Multi-row flow layout activates when
    /// pieces can't fit at minCellSize in a single row.
    private var trayView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            trayHeader

            GeometryReader { geo in
                let innerWidth = max(0, geo.size.width - AppSpacing.lg * 2)
                let layout = TrayLayout.compute(
                    pieces: viewModel.unplacedPieces,
                    availableWidth: innerWidth,
                    preferredCellSize: cellSize * 0.6,
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
            .frame(height: trayContentHeight)
            .background(AppColors.surfaceContainerHigh)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .shadowL1()
        }
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Piece tray. \(viewModel.unplacedPieces.count) pieces remaining.")
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
