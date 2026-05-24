import SwiftUI
import SnugloEngine

// MARK: — GameView
// Main game screen — loads level_5x5, shows grid + tray, handles drag-drop + snap.
//
// Faz B palette (Nordic Hearth):
//   Background:  AppColors.background    (#FDF8FB warm off-white)
//   Tray area:   AppColors.surfaceContainerHigh
//   HUD text:    AppColors.onSurface / onSurfaceVariant
//   Solved CTA:  AppColors.primary (lavender)

struct GameView: View {

    // MARK: — ViewModel

    @State private var viewModel: GameViewModel = GameViewModel.makeOrFallback()

    // MARK: — Drag state

    @State private var draggingPiece: Piece? = nil
    @State private var dragPosition: CGPoint = .zero
    @State private var snapCoord: Coord? = nil
    @State private var gridFrame: CGRect = .zero

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
    }

    // MARK: — Main layout

    private var mainLayout: some View {
        VStack(spacing: AppSpacing.md) {
            levelHeader

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

    // MARK: — Sub-views

    private var levelHeader: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Snuglo")
                .font(AppTypography.headlineLarge)
                .foregroundStyle(AppColors.onSurface)
            Text(viewModel.level.id)
                .font(AppTypography.labelSmall)
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }

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

}

// MARK: — Preview

#Preview {
    GameView()
}
