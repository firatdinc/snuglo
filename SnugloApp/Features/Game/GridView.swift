import SwiftUI
import SnugloEngine

/// Renders the puzzle grid using SwiftUI Canvas for high performance.
/// Draws: background, grid lines, placed pieces, snap ghost.
struct GridView: View {
    let level: Level
    let placements: [PieceID: Placement]
    let invalidPieceIDs: Set<PieceID>
    /// The grid cell that the currently-dragged piece would snap to.
    let snapCoord: Coord?
    /// ID of the piece being dragged (to draw ghost).
    let draggingPieceID: PieceID?

    var body: some View {
        GeometryReader { geo in
            let cs = geo.size.width / CGFloat(level.width)
            Canvas { context, size in
                drawBackground(context: context, size: size)
                drawGridLines(context: context, size: size, cs: cs)
                drawPlacements(context: context, cs: cs)
                drawSnapGhost(context: context, cs: cs)
            }
        }
        .aspectRatio(CGFloat(level.width) / CGFloat(level.height), contentMode: .fit)
        .background(AppColors.gridBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardRadius))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
    }

    // MARK: - Drawing helpers

    private func drawBackground(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(roundedRect: rect, cornerRadius: AppSpacing.cardRadius),
            with: .color(AppColors.gridBackground)
        )
    }

    private func drawGridLines(context: GraphicsContext, size: CGSize, cs: CGFloat) {
        let lineColor = AppColors.gridLines
        // Vertical
        for col in 0...level.width {
            let x = CGFloat(col) * cs
            var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(p, with: .color(lineColor), lineWidth: 1)
        }
        // Horizontal
        for row in 0...level.height {
            let y = CGFloat(row) * cs
            var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(p, with: .color(lineColor), lineWidth: 1)
        }
    }

    private func drawPlacements(context: GraphicsContext, cs: CGFloat) {
        for (pieceID, placement) in placements {
            guard let piece = level.pieces.first(where: { $0.id == pieceID }) else { continue }
            let isInvalid = invalidPieceIDs.contains(pieceID)
            let color = AppColors.blockColor(for: pieceID)
            for cell in piece.cells {
                let ax = CGFloat(cell.x + placement.origin.x)
                let ay = CGFloat(cell.y + placement.origin.y)
                let rect = CGRect(x: ax * cs + 2, y: ay * cs + 2,
                                  width: cs - 4, height: cs - 4)
                let path = Path(roundedRect: rect, cornerRadius: AppSpacing.blockRadius / 2)
                context.fill(path, with: .color(isInvalid ? AppColors.error.opacity(0.5) : color))
                if isInvalid {
                    context.stroke(path, with: .color(AppColors.invalidRed), lineWidth: 2)
                }
            }
        }
    }

    private func drawSnapGhost(context: GraphicsContext, cs: CGFloat) {
        guard let coord = snapCoord,
              let pid = draggingPieceID,
              let piece = level.pieces.first(where: { $0.id == pid }) else { return }
        let color = AppColors.blockColor(for: pid).opacity(0.35)
        for cell in piece.cells {
            let ax = CGFloat(cell.x + coord.x)
            let ay = CGFloat(cell.y + coord.y)
            // Only draw ghost cells that are within bounds
            guard Int(ax) >= 0, Int(ax) < level.width,
                  Int(ay) >= 0, Int(ay) < level.height else { continue }
            let rect = CGRect(x: ax * cs + 2, y: ay * cs + 2,
                              width: cs - 4, height: cs - 4)
            context.fill(
                Path(roundedRect: rect, cornerRadius: AppSpacing.blockRadius / 2),
                with: .color(color)
            )
        }
    }
}
