import CoreGraphics
import SnugloEngine

/// Pure layout helper for the piece tray.
/// CoreGraphics + SnugloEngine only — no SwiftUI; unit-testable.
enum TrayLayout {

    /// Cell size below which single-row layout wraps to multi-row.
    static let minCellSize: CGFloat = 20

    struct Result {
        /// Pieces arranged into rows. Single-row: `[[all pieces]]`.
        let rows: [[Piece]]
        /// Uniform cell size for all rows.
        let cellSize: CGFloat
        /// Total content height: sum of row heights + inter-row spacing. Excludes vertical padding.
        let contentHeight: CGFloat
    }

    /// Compute rows, cell size, and content height for the tray.
    ///
    /// - Parameters:
    ///   - pieces:            Pieces to lay out (typically `unplacedPieces`).
    ///   - availableWidth:    Inner tray width minus horizontal padding.
    ///   - preferredCellSize: Maximum cell size cap (grid cellSize × 0.6 suggested).
    ///   - itemSpacing:       Gap between pieces in a row, and between rows.
    static func compute(
        pieces: [Piece],
        availableWidth: CGFloat,
        preferredCellSize: CGFloat,
        itemSpacing: CGFloat
    ) -> Result {
        guard !pieces.isEmpty, availableWidth > 0 else {
            return Result(rows: [], cellSize: preferredCellSize, contentHeight: 0)
        }

        let singleCS = fitCellSize(
            for: pieces, inWidth: availableWidth,
            itemSpacing: itemSpacing, maxCellSize: preferredCellSize
        )

        if singleCS >= minCellSize {
            let maxPH = pieces.map { pieceHeight($0) }.max() ?? 1
            return Result(
                rows: [pieces],
                cellSize: singleCS,
                contentHeight: CGFloat(maxPH) * singleCS
            )
        }

        // Greedy multi-row packing: keep adding pieces to current row while cellSize stays above min.
        var rows: [[Piece]] = [[]]
        for piece in pieces {
            let candidate = rows[rows.count - 1] + [piece]
            let cs = fitCellSize(
                for: candidate, inWidth: availableWidth,
                itemSpacing: itemSpacing, maxCellSize: preferredCellSize
            )
            if cs >= minCellSize {
                rows[rows.count - 1] = candidate
            } else {
                rows.append([piece])
            }
        }

        let uniformCS = rows
            .map { fitCellSize(for: $0, inWidth: availableWidth, itemSpacing: itemSpacing, maxCellSize: preferredCellSize) }
            .min() ?? preferredCellSize

        var contentH: CGFloat = 0
        for (idx, row) in rows.enumerated() {
            let maxPH = row.map { pieceHeight($0) }.max() ?? 1
            contentH += CGFloat(maxPH) * uniformCS
            if idx < rows.count - 1 { contentH += itemSpacing }
        }

        return Result(rows: rows, cellSize: uniformCS, contentHeight: contentH)
    }

    // MARK: — Private

    private static func fitCellSize(
        for pieces: [Piece],
        inWidth availableWidth: CGFloat,
        itemSpacing: CGFloat,
        maxCellSize: CGFloat
    ) -> CGFloat {
        guard !pieces.isEmpty else { return maxCellSize }
        let totalCols = pieces.reduce(0) { $0 + pieceWidth($1) }
        let totalSpacing = CGFloat(max(0, pieces.count - 1)) * itemSpacing
        let widthForCells = availableWidth - totalSpacing
        guard totalCols > 0, widthForCells > 0 else { return maxCellSize }
        return min(maxCellSize, widthForCells / CGFloat(totalCols))
    }

    // MARK: — Piece dimension helpers (used externally for overlay sizing)

    static func pieceWidth(_ piece: Piece) -> Int {
        (piece.cells.map(\.x).max() ?? 0) + 1
    }

    static func pieceHeight(_ piece: Piece) -> Int {
        (piece.cells.map(\.y).max() ?? 0) + 1
    }
}
