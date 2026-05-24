import SwiftUI
import SnugloEngine

/// Main game screen — loads level_5x5, shows grid + tray, handles drag-drop + snap.
struct GameView: View {

    // MARK: - ViewModel

    @State private var viewModel: GameViewModel = GameViewModel.makeOrFallback()

    // MARK: - Drag state

    /// Piece currently being dragged.
    @State private var draggingPiece: Piece? = nil
    /// Drag position in "gameLayout" coordinate space.
    @State private var dragPosition: CGPoint = .zero
    /// Snapped grid coord (nil = no snap / outside grid).
    @State private var snapCoord: Coord? = nil
    /// Grid frame in "gameLayout" coordinate space (populated after first render).
    @State private var gridFrame: CGRect = .zero
    /// Cell size derived from grid frame width.
    private var cellSize: CGFloat {
        guard gridFrame.width > 0 else { return 56 }
        return gridFrame.width / CGFloat(viewModel.level.width)
    }
    /// Block overlay offset from top-left of the "gameLayout" container.
    private func overlayOffset(for piece: Piece) -> CGPoint {
        let halfW = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1) * cellSize / 2
        let halfH = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1) * cellSize / 2
        return CGPoint(x: dragPosition.x - halfW, y: dragPosition.y - halfH)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            mainLayout
            // Floating block follows finger
            if let piece = draggingPiece {
                let off = overlayOffset(for: piece)
                BlockView(piece: piece, cellSize: cellSize,
                          isInvalid: viewModel.invalidPieceIDs.contains(piece.id),
                          isDragging: true)
                    .offset(x: off.x, y: off.y)
                    .allowsHitTesting(false)
            }
        }
        .coordinateSpace(.named("gameLayout"))
        .background(AppColors.background.ignoresSafeArea())
    }

    // MARK: - Main layout

    private var mainLayout: some View {
        VStack(spacing: AppSpacing.lg) {
            levelHeader

            // Grid — fills horizontal space; square cells
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
        .padding(.vertical, AppSpacing.xl)
    }

    // MARK: - Sub-views

    private var levelHeader: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Snuglo")
                .font(AppTypography.title)
                .foregroundStyle(.white)
            Text(viewModel.level.id)
                .font(AppTypography.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    @ViewBuilder
    private var solvedBanner: some View {
        if viewModel.isSolved {
            Text("🎉 Solved!")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.success)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.sm)
                .background(.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonRadius))
                .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }

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
        .background(.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardRadius))
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Drag gesture

    private func dragGesture(for piece: Piece) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("gameLayout"))
            .onChanged { value in
                if draggingPiece == nil {
                    draggingPiece = piece
                }
                dragPosition = value.location
                snapCoord = calculateSnap(at: value.location, for: piece)
            }
            .onEnded { _ in
                if let coord = snapCoord {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        viewModel.tryPlace(pieceID: piece.id, at: coord)
                    }
                    // If rejected, clear invalid flag after ease-back delay
                    if viewModel.invalidPieceIDs.contains(piece.id) {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(400))
                            viewModel.clearInvalid(pieceID: piece.id)
                        }
                    }
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    draggingPiece = nil
                    snapCoord = nil
                }
            }
    }

    // MARK: - Snap calculation

    /// Convert drag position (in "gameLayout" space) → grid Coord, or nil if out of range.
    /// Snaps to cell whenever the finger is inside the grid ± 15pt buffer.
    ///
    /// pos is the finger location == floating piece center (see overlayOffset).
    /// We subtract half the piece dimensions to get the top-left origin before
    /// converting to grid coordinates — this keeps visual position and placement in sync.
    private func calculateSnap(at pos: CGPoint, for piece: Piece) -> Coord? {
        guard gridFrame.width > 0 else { return nil }

        let pieceCols = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1)
        let pieceRows = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1)

        // Convert center (finger) → top-left origin in grid-local coords
        let localX = pos.x - pieceCols * cellSize / 2 - gridFrame.minX
        let localY = pos.y - pieceRows * cellSize / 2 - gridFrame.minY
        let buffer: CGFloat = 15

        guard localX >= -buffer, localY >= -buffer,
              localX < gridFrame.width  + buffer,
              localY < gridFrame.height + buffer else {
            return nil
        }

        let col = Int(round(localX / cellSize))
        let row = Int(round(localY / cellSize))
        // Clamp so the entire piece stays within grid bounds
        let clampedCol = max(0, min(col, viewModel.level.width  - Int(pieceCols)))
        let clampedRow = max(0, min(row, viewModel.level.height - Int(pieceRows)))

        return Coord(x: clampedCol, y: clampedRow)
    }
}

// MARK: - Preview

#Preview {
    GameView()
}
