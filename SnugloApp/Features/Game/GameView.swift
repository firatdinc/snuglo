import SwiftUI
import SnugloEngine

// MARK: — GameView
// Ref: Designs/html/06-game-play.html
// Active level screen — loads puzzle by levelId, HUD with back/pause/timer,
// drag-drop tray at bottom, pause sheet, level-complete cover.
//
// Faz B palette (Nordic Hearth) preserved. Faz C adds: levelId param, HUD buttons,
// pause sheet integration, level-complete cover.
// Faz F adds: AudioManager + HapticsManager hooks on drag events.

struct GameView: View {

    // MARK: — Dependencies

    @Environment(AppRouter.self) private var router
    /// Level identifier passed from navigation. "daily" → daily puzzle.
    var levelId: String = "level_5x5"

    // MARK: — ViewModel
    // Faz D-2: PackProvider → engine Level → GameViewModel.
    // "daily" levelId → DailyPuzzle; "packId-index" → PackProvider.loadLevel.

    @State private var viewModel: GameViewModel = GameViewModel.makeOrFallback()

    // MARK: — Drag state

    @State private var draggingPiece: Piece?    = nil
    @State private var dragPosition: CGPoint    = .zero
    @State private var snapCoord: Coord?        = nil
    @State private var gridFrame: CGRect        = .zero

    // MARK: — UI state

    @State private var showPause         = false
    @State private var showComplete      = false
    @State private var elapsedSeconds    = 0
    @State private var timerTask: Task<Void, Never>? = nil

    private var cellSize: CGFloat {
        guard gridFrame.width > 0 else { return 56 }
        return gridFrame.width / CGFloat(viewModel.level.width)
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
            }
        }
        .coordinateSpace(.named("gameLayout"))
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showPause) {
            PauseSheet(
                onResume: { startTimer() },
                onRestart: {
                    viewModel = GameViewModel.makeFromPackProvider(levelId: levelId)
                    elapsedSeconds = 0
                    startTimer()
                },
                onQuit: { router.pop() },
                elapsedSeconds: elapsedSeconds
            )
            .environment(router)
        }
        .fullScreenCover(isPresented: $showComplete) {
            LevelCompleteSheet(
                stars: 3,
                elapsedSeconds: elapsedSeconds,
                hintsUsed: 0,
                onNext: { router.pop() },
                onReplay: {
                    viewModel = GameViewModel.makeFromPackProvider(levelId: levelId)
                    elapsedSeconds = 0
                    startTimer()
                }
            )
            .environment(router)
        }
        .onAppear {
            // Faz D-2: Gerçek engine level'ı yükle (lazy init — body çağrılmadan önce
            // @State init edilemez, bu yüzden onAppear'da swap yapıyoruz).
            let engineVM = GameViewModel.makeFromPackProvider(levelId: levelId)
            viewModel = engineVM
            startTimer()
        }
        .onDisappear { timerTask?.cancel() }
        .onChange(of: viewModel.isSolved) { _, solved in
            if solved {
                timerTask?.cancel()
                // Faz F: Solve audio + haptic via SoundService / HapticService
                SoundService.shared.play(.solve)
                HapticService.shared.notify(.success)
                // Faz G-2: Frequency-cap interstitial trigger (fires before sheet)
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
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("gameLayout"))
            } action: { frame in
                gridFrame = frame
            }

            Spacer(minLength: 0)
            trayView
        }
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: — HUD

    private var gameHUD: some View {
        HStack {
            // Back
            Button { router.pop() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surfaceContainerLow, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Level title
            VStack(spacing: 2) {
                Text(levelDisplayName)
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(AppColors.onSurface)
                Text(formattedTimer)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

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
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Tray

    private var trayView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.md) {
                ForEach(viewModel.unplacedPieces, id: \.id) { piece in
                    BlockView(
                        piece: piece,
                        cellSize: cellSize,
                        isInvalid: viewModel.invalidPieceIDs.contains(piece.id),
                        isDragging: false
                    )
                    .opacity(draggingPiece?.id == piece.id ? 0.0 : 1.0)
                    .gesture(dragGesture(for: piece))
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .shadowL1()
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Drag gesture
    // Faz F audio+haptic hooks:
    //   pickup  → first onChanged frame (draggingPiece was nil)
    //   drop    → onEnded with no snap target
    //   snap    → onEnded with valid placement (not yet solved)
    //   error   → onEnded with invalid placement
    //   levelComplete → onChange(of: isSolved) above

    private func dragGesture(for piece: Piece) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("gameLayout"))
            .onChanged { value in
                if draggingPiece == nil {
                    draggingPiece = piece
                    // Pickup: pre-warm taptic engine for low-latency snap feedback
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
                // BLOCKER-6 (1): fire snap feedback the first time snapCoord becomes non-nil
                if newSnap != nil && snapCoord == nil {
                    HapticService.shared.impact(.medium)
                    SoundService.shared.play(.snap)
                }
                snapCoord = newSnap
            }
            .onEnded { _ in
                if let coord = snapCoord {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        viewModel.tryPlace(pieceID: piece.id, at: coord)
                    }
                    if viewModel.invalidPieceIDs.contains(piece.id) {
                        // BLOCKER-6 (3): invalid placement
                        SoundService.shared.play(.error)
                        HapticService.shared.notify(.error)
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(400))
                            viewModel.clearInvalid(pieceID: piece.id)
                        }
                    } else if !viewModel.isSolved {
                        // BLOCKER-6 (2): valid partial placement
                        // (solved path fires through onChange(of: isSolved))
                        SoundService.shared.play(.place)
                        HapticService.shared.impact(.light)
                    }
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    draggingPiece = nil
                    snapCoord     = nil
                }
            }
    }

    // MARK: — Timer

    private func startTimer() {
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

    private var levelDisplayName: String {
        if levelId == "daily" { return "Daily Puzzle" }
        let parts = levelId.split(separator: "-")
        return parts.last.map(String.init) ?? levelId
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        GameView(levelId: "cozy-beginnings-1")
    }
    .environment(AppRouter())
}
