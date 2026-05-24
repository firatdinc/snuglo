// BlockView.swift — Tek bir Piece parçasının görsel temsili
// Hem tray'de hem grid üzerinde kullanılır.

import SwiftUI
import SnugloEngine

struct BlockView: View {

    let piece: Piece
    let colorKey: String
    let cellSize: CGFloat
    let isInvalid: Bool
    let isDragging: Bool

    // MARK: - Boyut hesaplama

    private var pieceGridWidth: Int {
        (piece.cells.map(\.x).max() ?? 0) + 1
    }
    private var pieceGridHeight: Int {
        (piece.cells.map(\.y).max() ?? 0) + 1
    }
    private var blockColor: Color {
        SnugloColors.block(forKey: colorKey)
    }
    private var totalWidth:  CGFloat { CGFloat(pieceGridWidth)  * cellSize }
    private var totalHeight: CGFloat { CGFloat(pieceGridHeight) * cellSize }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Her hücre için ayrı dikdörtgen
            ForEach(Array(piece.cells.enumerated()), id: \.offset) { _, cell in
                cellShape(at: cell)
            }

            // Hücre sayısı etiketi (sol üst köşe)
            if piece.cells.count > 1 {
                Text("\(piece.cells.count)")
                    .font(SnugloTypography.blockNumber())
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: cellSize - 4, height: cellSize - 4)
                    .offset(x: 2, y: 2)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: totalWidth, height: totalHeight)
        // Geçersiz: kırmızı kenarlık
        .overlay {
            if isInvalid {
                RoundedRectangle(cornerRadius: SnugloSpacing.blockRadius)
                    .strokeBorder(SnugloColors.error, lineWidth: 2)
            }
        }
        // Sürükleme: ölçek + gölge artışı
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .shadow(
            color: .black.opacity(isDragging ? 0.28 : 0.15),
            radius: isDragging ? 10 : 4,
            x: 0,
            y: isDragging ? 5 : 2
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
        .animation(.easeInOut(duration: 0.18), value: isInvalid)
    }

    // MARK: - Yardımcı

    @ViewBuilder
    private func cellShape(at cell: Coord) -> some View {
        let inset: CGFloat = 2
        RoundedRectangle(cornerRadius: SnugloSpacing.cellRadius)
            .fill(blockColor)
            .frame(width: cellSize - inset * 2, height: cellSize - inset * 2)
            .offset(
                x: CGFloat(cell.x) * cellSize + inset,
                y: CGFloat(cell.y) * cellSize + inset
            )
    }
}
