import SwiftUI
import SnugloEngine

// MARK: — GameView (Screen 06)
// Design reference: Designs/html/06-game-play.html
//
// Active level screen. HUD: back ← / level name / timer ⏱.
// Drag-drop and snap-to-grid preserved from Faz B.
// New in Faz C: levelId param, AppRouter env, PauseSheet, LevelCompleteSheet, timer.
//
// Faz D plug-in point: replace makeOrFallback(levelNamed:) with a real level lookup
// keyed on levelId once LevelLoader supports arbitrary level IDs.

struct GameView: View {

    // MARK: — Init

    let levelId: String

    init(levelId: String = "level_5x5") {
        self.levelId = levelId
        // Extract a loadable level name from the levelId.
        // Faz D: replace with LevelLoader.load(id: levelId)
        let levelName = Self.levelName(from: levelId)
        self._viewModel = State(initialValue: GameViewModel.makeOrFallback(levelNamed: levelName))
    }

    /// Heuristically map a Faz C levelId to a JSON bundle name.
    /// Faz D removes this once the real loader is in place.
    private static func levelName(from levelId: String) -> String {
        if levelId.contains("6x6") { return "level_6x6" }
        if levelId.contains("7x7") { return "level_7x7" }
        return "level_5x5"  // safe fallback
    }

    // MARK: — Environment / State

    @Environment(AppRouter.self) private var router

    @State private var viewModel: GameViewModel
    @State private var draggingPiece: Piece? = nil
    @State private var dragPosition: CGPoint = .zero
    @State private var snapCoord: Coord? = nil
    @State private var gridFrame: CGRect = .zero

    // Timer
    @State private var elapsedSeconds = 0
    @State private var timerActive = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Sheets
    @State private var isPaused = false
    @State private var showLevelComplete = false

    // MARK: — Computed

    private var cellSize: CGFloat {
        guard gridFrame.width > 0 else { return 56 }
        return gridFrame.width / CGFloat(viewModel.level.width)
    }

    private func overlayOffset(for piece: Piece) -> CGPoint {
        let halfW = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1) * cellSize / 2
        let halfH = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1) * cellSize / 2
        return CGPoint(x: dragPosition.x - halfW, y: dragPosition.y - halfH)
    }

    private var levelDisplayName: String {
        // Show the level id as the display title, capitalised
        // Faz D: derive from real level metadata
        let base = levelId
            .components(separatedBy: "-")
            .last ?? levelId
        return base.isEmpty ? viewModel.level.id : base
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
        .onAppear { timerActive = true }
        .onDisappear { timerActive = false }
        .onReceive(timer) { _ in
            guard timerActive && !isPaused && !showLevelComplete else { return }
            elapsedSeconds += 1
        }
        .onChange(of: viewModel.isSolved) { _, solved in
            if solved {
                timerActive = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
                    showLevelComplete = true
                }
            }
        }
        // Pause sheet
        // BLOCKER FIX: swipe-to-dismiss binding'i false yapar ama onResume çağrılmaz →
        // onDismiss ile timer'ı geri aç (zaten çözüldüyse veya level complete açıksa dokunma).
        .sheet(isPresented: $isPaused, onDismiss: {
            if !viewModel.isSolved && !showLevelComplete { timerActive = true }
        }) {
            PauseSheet(
                elapsedSeconds: elapsedSeconds,
                onResume: {
                    isPaused = false
                    timerActive = true
                },
                onRestart: {
                    isPaused = false
                    restartLevel()
                },
                onQuit: {
                    isPaused = false
                    router.path = [.mainMenu]
                }
            )
        }
        // Level complete full-screen cover
        .fullScreenCover(isPresented: $showLevelComplete) {
            LevelCompleteSheet(
                stats: LevelStats(
                    elapsedSeconds: elapsedSeconds,
                    stars: starsEarned,
                    hintsUsed: 0  // Faz E: real hint tracking
                ),
                onNextLevel: {
                    showLevelComplete = false
                    // Faz D: advance to next level ID
                    router.pop()
                },
                onReplay: {
                    showLevelComplete = false
                    restartLevel()
                },
                onHome: {
                    showLevelComplete = false
                    router.path = [.mainMenu]
                }
            )
        }
    }

    // MARK: — Main layout

    private var mainLayout: some View {
        VStack(spacing: AppSpacing.md) {
            hudBar

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

            solvedBanner
            Spacer(minLength: 0)
            trayView
        }
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: — HUD bar

    private var hudBar: some View {
        HStack {
            // Back / close button
            Button {
                router.pop()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Level name
            Text(levelDisplayName.capitalized)
                .font(AppTypography.headlineSmall)
                .foregroundStyle(AppColors.onSurface)
                .lineLimit(1)

            Spacer()

            // Timer + pause
            HStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                    Text(formatTime(elapsedSeconds))
                        .font(AppTypography.numericLabel)
                        .foregroundStyle(AppColors.onSurface)
                        .monospacedDigit()
                }

                Button {
                    timerActive = false
                    isPaused = true
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: — Solved banner

    @ViewBuilder
    private var solvedBanner: some View {
        if viewModel.isSolved {
            Text("🎉 Solved!")
                .font(AppTypography.headlineMedium)
                .foregroundStyle(AppColors.onPrimary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                .shadowL1()
                .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
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

    private func dragGesture(for piece: Piece) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("gameLayout"))
            .onChanged { value in
                if draggingPiece == nil { draggingPiece = piece }
                dragPosition = value.location
                snapCoord = SnapCalculator.snap(
                    at: value.location,
                    piece: piece,
                    gridFrame: gridFrame,
                    cellSize: cellSize,
                    gridSize: (width: viewModel.level.width, height: viewModel.level.height)
                )
            }
            .onEnded { _ in
                if let coord = snapCoord {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        viewModel.tryPlace(pieceID: piece.id, at: coord)
                    }
                    if viewModel.invalidPieceIDs.contains(piece.id) {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(400))
                            viewModel.clearInvalid(pieceID: piece.id)
                        }
                    }
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    draggingPiece = nil
                    snapCoord    = nil
                }
            }
    }

    // MARK: — Helpers

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var starsEarned: Int {
        // Simple star heuristic: 3 stars < 60s, 2 stars < 180s, 1 star otherwise
        // Faz E: replace with spec-based calculation
        if elapsedSeconds < 60  { return 3 }
        if elapsedSeconds < 180 { return 2 }
        return 1
    }

    private func restartLevel() {
        let levelName = Self.levelName(from: levelId)
        viewModel = GameViewModel.makeOrFallback(levelNamed: levelName)
        elapsedSeconds = 0
        timerActive = true
        draggingPiece = nil
        snapCoord = nil
    }
}

// MARK: — Preview

#Preview {
    NavigationStack {
        GameView()
    }
    .environment(AppRouter())
}
