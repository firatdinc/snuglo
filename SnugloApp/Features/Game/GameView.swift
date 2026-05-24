// GameView.swift — v0.2 Ana oyun ekranı
//
// Sorumluluklar:
//   • Ekran layout (coral arka plan, grid merkez, tray alt)
//   • Drag-drop orchestration (DragGesture .global → grid hücresi)
//   • Floating piece overlay (sürükleme sırasında)
//   • Solved overlay
//
// iOS 17+ @Observable pattern: GameViewModel @State olarak tutulur.

import SwiftUI
import SnugloEngine

struct GameView: View {

    // MARK: - State

    @State private var viewModel = GameViewModel()

    /// GridView'ın ekrandaki global çerçevesi (drop hesaplaması için)
    @State private var gridFrame: CGRect = .zero

    /// Şu an sürüklenen parça ID'si
    @State private var draggingPieceId: String? = nil

    /// Sürükleme sırasında parmak konumu (global)
    @State private var dragPosition: CGPoint = .zero

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let cSize = computedCellSize(screenSize: geo.size)

            ZStack {
                // Arka plan
                SnugloColors.coral
                    .ignoresSafeArea()

                // Ana layout
                VStack(spacing: 0) {
                    // Başlık
                    headerView
                        .padding(.top, SnugloSpacing.lg)
                        .padding(.horizontal, SnugloSpacing.lg)

                    Spacer()

                    // Grid
                    if viewModel.level != nil {
                        GridView(viewModel: viewModel, cellSize: cSize)
                            .overlay(gridFrameCapture)   // global frame'i yakala
                            .padding(.horizontal, SnugloSpacing.lg)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.placedPieces.count)
                    }

                    Spacer()

                    // Tray
                    trayView(cellSize: cSize)
                        .padding(.horizontal, SnugloSpacing.lg)
                        .padding(.bottom, SnugloSpacing.xl)
                }

                // Sürüklenen parça float overlay
                floatingPieceView(cellSize: cSize)
            }
            // Çözüldü overlay
            .overlay {
                if viewModel.isSolved {
                    solvedOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeOut(duration: 0.3), value: viewModel.isSolved)
        }
        .onPreferenceChange(GridFramePreferenceKey.self) { frame in
            gridFrame = frame
        }
        .onAppear {
            viewModel.loadLevel()
        }
    }

    // MARK: - Cell size

    private func computedCellSize(screenSize: CGSize) -> CGFloat {
        let cols  = CGFloat(viewModel.level?.width  ?? 5)
        let rows  = CGFloat(viewModel.level?.height ?? 5)
        let hPad  = 2 * SnugloSpacing.lg
        let fromW = (screenSize.width - hPad) / cols
        // Ekran yüksekliğinin %33'ünü grid'e ver
        let fromH = (screenSize.height * 0.33) / rows
        return min(fromW, fromH)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Snuglo")
                    .font(SnugloTypography.title())
                    .foregroundStyle(SnugloColors.cream)
                if let level = viewModel.level {
                    Text(level.id.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(SnugloTypography.caption())
                        .foregroundStyle(SnugloColors.cream.opacity(0.75))
                }
            }
            Spacer()
            if !viewModel.placements.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        viewModel.reset()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(SnugloColors.cream)
                        .padding(SnugloSpacing.sm)
                        .background(SnugloColors.cream.opacity(0.18), in: Circle())
                }
            }
        }
    }

    // MARK: - Grid frame capture (Preference)

    private var gridFrameCapture: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: GridFramePreferenceKey.self,
                    value: geo.frame(in: .global)
                )
        }
    }

    // MARK: - Tray

    private func trayView(cellSize: CGFloat) -> some View {
        let maxPieceH = CGFloat(
            viewModel.unplacedPieces.map { ($0.cells.map(\.y).max() ?? 0) + 1 }.max() ?? 1
        )
        let trayH = maxPieceH * cellSize + SnugloSpacing.lg

        return Group {
            if viewModel.unplacedPieces.isEmpty {
                // Tüm parçalar grid'de
                Text(viewModel.isSolved ? "🎉 Tümü yerleşti!" : "Tüm parçalar yerleştirildi")
                    .font(SnugloTypography.subtitle())
                    .foregroundStyle(SnugloColors.cream)
                    .frame(height: trayH)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SnugloSpacing.sm) {
                        ForEach(viewModel.unplacedPieces, id: \.id) { piece in
                            trayBlock(piece: piece, cellSize: cellSize)
                        }
                    }
                    .padding(.horizontal, SnugloSpacing.sm)
                    .padding(.vertical, SnugloSpacing.sm)
                }
                .frame(height: trayH)
                .background(
                    SnugloColors.cream.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: SnugloSpacing.cardRadius)
                )
            }
        }
    }

    private func trayBlock(piece: Piece, cellSize: CGFloat) -> some View {
        let isBeingDragged = draggingPieceId == piece.id

        return BlockView(
            piece: piece,
            colorKey: viewModel.colorKey(for: piece.id),
            cellSize: cellSize,
            isInvalid: viewModel.invalidPieceIds.contains(piece.id),
            isDragging: false
        )
        .opacity(isBeingDragged ? 0.28 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isBeingDragged)
        .highPriorityGesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
                .onChanged { value in
                    if draggingPieceId == nil {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            draggingPieceId = piece.id
                        }
                    }
                    dragPosition = value.location
                }
                .onEnded { value in
                    handleDrop(pieceId: piece.id, at: value.location)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        draggingPieceId = nil
                    }
                }
        )
    }

    // MARK: - Floating piece

    @ViewBuilder
    private func floatingPieceView(cellSize: CGFloat) -> some View {
        if let pid = draggingPieceId,
           let level = viewModel.level,
           let piece = level.pieces.first(where: { $0.id == pid }) {
            BlockView(
                piece: piece,
                colorKey: viewModel.colorKey(for: pid),
                cellSize: cellSize,
                isInvalid: false,
                isDragging: true
            )
            .position(dragPosition)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Drop handling

    private func handleDrop(pieceId: String, at globalPoint: CGPoint) {
        guard !gridFrame.isEmpty, let level = viewModel.level else { return }

        let cols  = CGFloat(level.width)
        let cSize = gridFrame.width / cols
        let localX = globalPoint.x - gridFrame.minX
        let localY = globalPoint.y - gridFrame.minY

        // Snap toleransı: ±15pt (spec §2)
        let tolerance: CGFloat = 15
        guard
            localX >= -tolerance, localX < gridFrame.width  + tolerance,
            localY >= -tolerance, localY < gridFrame.height + tolerance
        else { return }

        let col = max(0, min(Int(floor(localX / cSize)), level.width  - 1))
        let row = max(0, min(Int(floor(localY / cSize)), level.height - 1))

        _ = withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            viewModel.place(pieceId: pieceId, at: Coord(x: col, y: row))
        }
    }

    // MARK: - Solved overlay

    private var solvedOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: SnugloSpacing.lg) {
                Text("🎉")
                    .font(.system(size: 64))

                Text("Solved!")
                    .font(SnugloTypography.title())
                    .foregroundStyle(SnugloColors.textPrimary)

                Text("Tüm parçalar yerleşti.")
                    .font(SnugloTypography.body())
                    .foregroundStyle(SnugloColors.textSecondary)

                Button("Tekrar Oyna") {
                    withAnimation(.spring(response: 0.4)) {
                        viewModel.reset()
                    }
                }
                .font(SnugloTypography.subtitle())
                .foregroundStyle(.white)
                .padding(.horizontal, SnugloSpacing.xl)
                .padding(.vertical, SnugloSpacing.sm)
                .background(SnugloColors.coral, in: RoundedRectangle(cornerRadius: SnugloSpacing.buttonRadius))
            }
            .padding(SnugloSpacing.xl)
            .background(SnugloColors.cream, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
        }
    }
}

// MARK: - Preference Key

struct GridFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

// MARK: - Preview

#Preview {
    GameView()
}
