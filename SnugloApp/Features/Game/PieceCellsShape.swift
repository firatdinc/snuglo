import SwiftUI
import SnugloEngine

// MARK: — PieceCellsShape
// A Shape that traces ONLY the filled cells of a piece (not its bounding box).
//
// Used two ways:
//   1. `.contentShape(PieceCellsShape(piece:))` on a tray block → taps on the
//      empty cells of an L/T/Z piece no longer grab it. This is the core fix for
//      "the drag picks the wrong piece": adjacent pieces' bounding boxes overlap
//      visual gaps, so hit-testing must follow the actual shape.
//   2. As a pulsing target outline for the snap ghost (juicy placement feedback).
//
// The shape derives the cell size from the proposed `rect` (rect.width / columns),
// so it always matches the BlockView frame it is applied to — no cellSize plumbing.

struct PieceCellsShape: Shape {
    let piece: Piece
    /// Fraction of a cell to inset each cell rect (0 = full cell).
    var insetRatio: CGFloat = 0
    /// Corner radius as a fraction of cell size.
    var cornerRatio: CGFloat = 0.18

    func path(in rect: CGRect) -> Path {
        let cols = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1)
        guard cols > 0, rect.width > 0 else { return Path() }
        let cs = rect.width / cols
        let inset = cs * insetRatio
        let radius = cs * cornerRatio

        var path = Path()
        for cell in piece.cells {
            let r = CGRect(
                x: CGFloat(cell.x) * cs + inset,
                y: CGFloat(cell.y) * cs + inset,
                width: cs - inset * 2,
                height: cs - inset * 2
            )
            path.addRoundedRect(in: r, cornerSize: CGSize(width: radius, height: radius))
        }
        return path
    }
}
