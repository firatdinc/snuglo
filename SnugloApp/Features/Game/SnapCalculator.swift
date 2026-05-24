import CoreGraphics
import SnugloEngine

/// Pure, testable snap-to-grid calculator.
///
/// Converts a finger drag position (the floating piece's **center** in the named
/// coordinate space) into a grid `Coord` for the top-left anchor of the piece.
///
/// Extracted from `GameView.calculateSnap` so the coordinate algebra can be unit-tested
/// without needing a live SwiftUI view hierarchy.
///
/// ## Coordinate model
/// ```
///  ┌────────────────────────────────────┐  ← gameLayout (named coord space)
///  │            │ gridFrame.minY         │
///  │ ─── ─── ──┼──────────────────────  │
///  │            │  Grid (col×row cells)  │
///  │ gridFrame  │  cellSize = W / cols   │
///  │ .minX ─── ┤                        │
///  └────────────────────────────────────┘
/// ```
/// - `pos` is the finger (= piece center in gameLayout space).
/// - Subtracting half the piece's bounding-box converts center → top-left.
/// - Subtracting `gridFrame.origin` converts gameLayout → grid-local.
/// - `round(localX / cellSize)` snaps to the nearest column.
/// - Clamping keeps the whole piece inside the grid.
struct SnapCalculator {

    // MARK: - Configuration

    let gridFrame: CGRect
    let cellSize: CGFloat
    let levelWidth: Int
    let levelHeight: Int
    /// Allowable over-shoot distance (pt) beyond grid edges before returning nil.
    let snapBuffer: CGFloat

    // MARK: - Init

    init(
        gridFrame: CGRect,
        levelWidth: Int,
        levelHeight: Int,
        snapBuffer: CGFloat = 15
    ) {
        self.gridFrame = gridFrame
        self.levelWidth = levelWidth
        self.levelHeight = levelHeight
        self.snapBuffer = snapBuffer
        self.cellSize = gridFrame.width > 0
            ? gridFrame.width / CGFloat(levelWidth)
            : 56
    }

    // MARK: - Public

    /// Convert a finger position to a grid `Coord`, or `nil` when outside the grid + buffer.
    ///
    /// - Parameter fingerPos: drag location in the `gameLayout` coordinate space (= piece center).
    /// - Parameter piece: the piece being dragged (used to compute bounding-box dimensions).
    func snap(fingerAt fingerPos: CGPoint, piece: Piece) -> Coord? {
        guard gridFrame.width > 0 else { return nil }

        let pieceCols = CGFloat((piece.cells.map(\.x).max() ?? 0) + 1)
        let pieceRows = CGFloat((piece.cells.map(\.y).max() ?? 0) + 1)

        // Center → top-left in grid-local coordinates
        let localX = fingerPos.x - pieceCols * cellSize / 2 - gridFrame.minX
        let localY = fingerPos.y - pieceRows * cellSize / 2 - gridFrame.minY

        guard
            localX >= -snapBuffer,
            localY >= -snapBuffer,
            localX < gridFrame.width  + snapBuffer,
            localY < gridFrame.height + snapBuffer
        else { return nil }

        let col = Int(round(localX / cellSize))
        let row = Int(round(localY / cellSize))

        // Clamp so the entire piece stays inside the grid
        let clampedCol = max(0, min(col, levelWidth  - Int(pieceCols)))
        let clampedRow = max(0, min(row, levelHeight - Int(pieceRows)))

        return Coord(x: clampedCol, y: clampedRow)
    }
}
