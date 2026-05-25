import SwiftUI
import SnugloEngine

// MARK: — BlockView
// Renders a single puzzle piece (in tray or as dragging overlay).
//
// Design spec (Nordic Hearth):
//   Fill:    pastel block fill selected deterministically by piece.id hash (6 pastels)
//   Radius:  AppRadius.block = 10 pt per cell
//   Shadow:  L1 (idle)  → shadowAmbient 0.06 opacity, 12 pt radius, 4 pt y-offset
//            L2 (drag)  → shadowAmbient 0.12 opacity, 16 pt radius, 8 pt y-offset
//   Scale:   1.0 idle / 1.10 picked-up (spec: "Picked-up block: scale 1.10×")
//   Bevel:   L2 only — 0.5 pt white-50% horizontal line on top edge of each cell
//   Label:   piece.cellCount centered on bounding box — always shown (accessibility)
//            Font: AppTypography.numericLabel (SF Mono 20pt medium)
//            Color: AppColors.onSurface (deep cocoa, not semi-transparent)
// H-2: Reduce Motion — scale/spring animation skipped when reduceMotion is enabled.
//       VoiceOver label + hint added for drag-drop interaction.

struct BlockView: View {
    let piece: Piece
    let cellSize: CGFloat
    let isInvalid: Bool
    let isDragging: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: — Layout geometry

    private var pieceWidth: Int { (piece.cells.map(\.x).max() ?? 0) + 1 }
    private var pieceHeight: Int { (piece.cells.map(\.y).max() ?? 0) + 1 }

    // MARK: — Color

    private var fillColor: Color {
        isInvalid
            ? AppColors.error.opacity(0.72)
            : AppColors.blockColor(for: piece.id)
    }

    // MARK: — Body

    var body: some View {
        Canvas { context, _ in
            renderCells(in: context)
            renderCellCountLabel(in: context)
        }
        .frame(
            width: CGFloat(pieceWidth)  * cellSize,
            height: CGFloat(pieceHeight) * cellSize
        )
        // H-2: Reduce Motion — skip scale animation; keep scale value for dragging state
        .scaleEffect(isDragging ? 1.10 : 1.0)
        .shadow(
            color: AppColors.shadowAmbient.opacity(isDragging ? 0.12 : 0.06),
            radius: isDragging ? 16 : 12,
            x: 0,
            y: isDragging ? 8 : 4
        )
        // H-2: only animate when reduceMotion is off
        .animation(reduceMotion ? nil : .spring(response: 0.20, dampingFraction: 0.70), value: isDragging)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.65), value: isInvalid)
        // H-2: VoiceOver — block identity + drag hint
        .accessibilityLabel("\(piece.cellCount)-cell block")
        .accessibilityHint("Double tap to select, then drag to place on the grid")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: — Canvas rendering helpers

    /// Draws all cells: fill + optional invalid stroke + L2 inner-top bevel.
    private func renderCells(in context: GraphicsContext) {
        for cell in piece.cells {
            let x = CGFloat(cell.x) * cellSize
            let y = CGFloat(cell.y) * cellSize
            let rect = CGRect(
                x: x + 1, y: y + 1,
                width: cellSize - 2, height: cellSize - 2
            )
            let path = Path(roundedRect: rect, cornerRadius: AppRadius.block)

            context.fill(path, with: .color(fillColor))

            if isInvalid {
                context.stroke(path, with: .color(AppColors.error), lineWidth: 2)
            }

            // L2 inner-top bevel — skip when reduceMotion (dragging state is muted)
            if isDragging && !isInvalid {
                let bevelY   = y + 1 + AppRadius.block * 0.5
                let bevelX0  = x + 1 + AppRadius.block * 0.6
                let bevelX1  = x + cellSize - 1 - AppRadius.block * 0.6
                guard bevelX1 > bevelX0 else { continue }
                var bevel = Path()
                bevel.move(to: CGPoint(x: bevelX0, y: bevelY))
                bevel.addLine(to: CGPoint(x: bevelX1, y: bevelY))
                context.stroke(bevel, with: .color(.white.opacity(0.50)), lineWidth: 0.5)
            }
        }
    }

    /// Draws the cell-count label centered on the piece's bounding box.
    private func renderCellCountLabel(in context: GraphicsContext) {
        let midX = CGFloat(pieceWidth)  * cellSize / 2
        let midY = CGFloat(pieceHeight) * cellSize / 2

        let label = context.resolve(
            Text("\(piece.cellCount)")
                .font(AppTypography.numericLabel)
                .foregroundStyle(AppColors.onSurface)
        )
        let labelSize = label.measure(in: CGSize(
            width: CGFloat(pieceWidth)  * cellSize,
            height: CGFloat(pieceHeight) * cellSize
        ))
        context.draw(
            label,
            at: CGPoint(x: midX - labelSize.width  / 2,
                        y: midY - labelSize.height / 2),
            anchor: .topLeading
        )
    }
}

// MARK: — Preview

#Preview("Idle 2×3") {
    let piece = Piece(id: "preview", cells: [
        Coord(x: 0, y: 0), Coord(x: 1, y: 0),
        Coord(x: 0, y: 1), Coord(x: 1, y: 1),
        Coord(x: 0, y: 2), Coord(x: 1, y: 2)
    ])
    return VStack(spacing: 24) {
        BlockView(piece: piece, cellSize: 56, isInvalid: false, isDragging: false)
        BlockView(piece: piece, cellSize: 56, isInvalid: false, isDragging: true)
        BlockView(piece: piece, cellSize: 56, isInvalid: true, isDragging: false)
    }
    .padding(32)
    .background(AppColors.background)
}
