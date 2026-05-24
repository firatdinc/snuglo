import SwiftUI
import SnugloEngine

/// Renders a single puzzle piece (tray or dragging overlay).
/// Size = bounding box of the piece in cellSize units.
struct BlockView: View {
    let piece: Piece
    let cellSize: CGFloat
    let isInvalid: Bool
    let isDragging: Bool

    // MARK: - Computed

    private var pieceWidth: Int  { (piece.cells.map(\.x).max() ?? 0) + 1 }
    private var pieceHeight: Int { (piece.cells.map(\.y).max() ?? 0) + 1 }
    private var color: Color { AppColors.blockColor(for: piece.id) }

    // MARK: - Body

    var body: some View {
        Canvas { context, _ in
            let fillColor: Color = isInvalid ? AppColors.error.opacity(0.7) : color
            for cell in piece.cells {
                let x = CGFloat(cell.x) * cellSize
                let y = CGFloat(cell.y) * cellSize
                let rect = CGRect(x: x + 1, y: y + 1,
                                  width: cellSize - 2, height: cellSize - 2)
                let path = Path(roundedRect: rect, cornerRadius: AppSpacing.blockRadius / 2)
                context.fill(path, with: .color(fillColor))
                if isInvalid {
                    context.stroke(path, with: .color(AppColors.invalidRed), lineWidth: 2)
                }
            }
            // Cell count label — centered on bounding box
            let totalCells = piece.cells.count
            if totalCells > 1 {
                let midX = (CGFloat(pieceWidth) * cellSize) / 2
                let midY = (CGFloat(pieceHeight) * cellSize) / 2
                var text = context.resolve(Text("\(totalCells)")
                    .font(AppTypography.blockLabel)
                    .foregroundStyle(AppColors.textPrimary.opacity(0.7)))
                let textSize = text.measure(in: CGSize(width: cellSize, height: cellSize))
                context.draw(text, at: CGPoint(x: midX - textSize.width / 2,
                                               y: midY - textSize.height / 2),
                             anchor: .topLeading)
            }
        }
        .frame(width: CGFloat(pieceWidth) * cellSize,
               height: CGFloat(pieceHeight) * cellSize)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .shadow(
            color: .black.opacity(isDragging ? 0.25 : 0.10),
            radius: isDragging ? 8 : 3,
            x: 0, y: isDragging ? 4 : 2
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isInvalid)
    }
}
