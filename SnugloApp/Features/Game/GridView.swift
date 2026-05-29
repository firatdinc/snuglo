import SwiftUI
import SnugloEngine

// MARK: — GridView
// Renders the puzzle grid using SwiftUI Canvas for high performance.
//
// v1.1 palette (Stitch Nordic Hearth alignment):
//   Board background: AppColors.gameBoardBackground  (#F2EBE0 warm parchment)
//   Grid lines:       AppColors.gridLine             (#E5DCC8, 1.5 pt — Stitch spec)
//   Placed pieces:    AppColors.blockColor(for:)     (deterministic pastel)
//   Snap ghost valid:   block color @ 45% opacity + thin stroke
//   Snap ghost invalid: error color @ 40% opacity + error stroke
//   Invalid fill:     AppColors.error @ 50% opacity + error stroke

struct GridView: View {
    let level: Level
    let placements: [PieceID: Placement]
    let invalidPieceIDs: Set<PieceID>
    let snapCoord: Coord?
    let snapIsInvalid: Bool
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
        .background(AppColors.gameBoardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .shadowL1()
    }

    // MARK: — Drawing helpers

    private func drawBackground(context: GraphicsContext, size: CGSize) {
        context.fill(
            Path(roundedRect: CGRect(origin: .zero, size: size),
                 cornerRadius: AppRadius.card),
            with: .color(AppColors.gameBoardBackground)
        )
    }

    private func drawGridLines(context: GraphicsContext, size: CGSize, cs: CGFloat) {
        // v1.1: Stitch spec — #E5DCC8 at 1.5 pt (was outlineVariant 1 pt)
        let lineColor = AppColors.gridLine
        for col in 0...level.width {
            let x = CGFloat(col) * cs
            var p = Path()
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(p, with: .color(lineColor), lineWidth: 1.5)
        }
        for row in 0...level.height {
            let y = CGFloat(row) * cs
            var p = Path()
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(p, with: .color(lineColor), lineWidth: 1.5)
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
                let path = Path(roundedRect: rect, cornerRadius: AppRadius.block)
                context.fill(path, with: .color(isInvalid ? AppColors.error.opacity(0.50) : color))
                if isInvalid {
                    context.stroke(path, with: .color(AppColors.error), lineWidth: 2)
                }
            }
        }
    }

    private func drawSnapGhost(context: GraphicsContext, cs: CGFloat) {
        guard let coord = snapCoord,
              let pid   = draggingPieceID,
              let piece = level.pieces.first(where: { $0.id == pid }) else { return }

        let ghostFill: Color
        let ghostStroke: Color
        let strokeWidth: CGFloat
        if snapIsInvalid {
            ghostFill   = AppColors.error.opacity(0.35)
            ghostStroke = AppColors.error.opacity(0.75)
            strokeWidth = 1.5
        } else {
            ghostFill   = AppColors.blockColor(for: pid).opacity(0.45)
            ghostStroke = AppColors.blockColor(for: pid).opacity(0.65)
            strokeWidth = 1.0
        }

        for cell in piece.cells {
            let ax = CGFloat(cell.x + coord.x)
            let ay = CGFloat(cell.y + coord.y)
            guard Int(ax) >= 0, Int(ax) < level.width,
                  Int(ay) >= 0, Int(ay) < level.height else { continue }
            let rect = CGRect(x: ax * cs + 2, y: ay * cs + 2,
                              width: cs - 4, height: cs - 4)
            let path = Path(roundedRect: rect, cornerRadius: AppRadius.block)
            context.fill(path, with: .color(ghostFill))
            context.stroke(path, with: .color(ghostStroke), lineWidth: strokeWidth)
        }
    }
}
