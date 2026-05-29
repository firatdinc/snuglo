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
                hintsUsed: 0,
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

            GridView(
                level: viewModel.level,
                placements: viewModel.placements,
                invalidPieceIDs: viewModel.invalidPieceIDs,
                snapCoord: snapCoord,
                draggingPieceID: draggingPiece?.id
            )
            .padding(.horizontal, AppSpacing.lg)
            // v1.1.1 critical fix: floating-point oscillation in the geometry
            // value caused 30k+ body re-renders/second → main thread block,
            // navigation push never completed, app appeared frozen.
            // Round to nearest integer pt before triggering @State update,
            // and skip no-op updates entirely.
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
            // .accessibilityElement(children: .contain) is required so Canvas-based
            // GridView is visible as otherElements["game.grid"] in XCUITest.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("game.grid")

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
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityHint("Returns to the previous screen")
            .accessibilityIdentifier("game.back")

            Spacer()

            // Level title + timer (v1.1: timer uses numericLabel = Space Grotesk)
            VStack(spacing: 2) {
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

            // Pause
            Button { pauseGame() } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surfaceContainerLow, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pause")
            .accessibilityHint("Pauses the timer and shows pause options")
            // Faz I-2: updated identifier spec
            .accessibilityIdentifier("button.game.pause")
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Tray

    /// v1.1.3 UX fix: tray cellSize is now computed to FIT all remaining
    /// pieces within the available width — no more horizontal scrolling or
    /// pieces getting cut off at the right edge. Defaults to 60% of grid
    /// cellSize and shrinks if the sum of piece widths + spacing exceeds
    /// what the screen can show.
    private func trayCellSize(for pieces: [Piece], availableWidth: CGFloat) -> CGFloat {
        let defaultCellSize = cellSize * 0.6
        guard !pieces.isEmpty else { return defaultCellSize }

        let totalCellsAcross = pieces.reduce(0) { acc, piece in
            acc + ((piece.cells.map(\.x).max() ?? 0) + 1)
        }
        let totalSpacing = CGFloat(max(0, pieces.count - 1)) * AppSpacing.md
        let widthForCells = availableWidth - totalSpacing
        guard totalCellsAcross > 0, widthForCells > 0 else { return defaultCellSize }
        let maxCellSizeToFit = widthForCells / CGFloat(totalCellsAcross)
        return min(defaultCellSize, maxCellSizeToFit)
    }

    private var trayView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            trayHeader

            GeometryReader { geo in
                let pieces = viewModel.unplacedPieces
                // Available width inside the tray = geo.size.width minus the
                // tray's inner horizontal padding (AppSpacing.lg × 2).
                let innerWidth = max(0, geo.size.width - AppSpacing.lg * 2)
                let cs = trayCellSize(for: pieces, availableWidth: innerWidth)
                HStack(alignment: .center, spacing: AppSpacing.md) {
                    ForEach(pieces, id: \.id) { piece in
                        BlockView(
                            piece: piece,
                            cellSize: cs,
                            isInvalid: viewModel.invalidPieceIDs.contains(piece.id),
                            isDragging: false
                        )
                        .opacity(draggingPiece?.id == piece.id ? 0.0 : 1.0)
                        .gesture(dragGesture(for: piece))
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 120)
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

    // MARK: — Drag gesture
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
                    let animation: Animation? = reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7)
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
                let resetAnimation: Animation? = reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)
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
