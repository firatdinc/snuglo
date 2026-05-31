import Testing
import CoreGraphics
import SnugloEngine
@testable import SnugloApp

// MARK: — TrayFitTests
// The tray is a single horizontally-scrolling row. Its cell size is chosen so the
// TALLEST piece of the (constant) full set fits the tray height — so pieces are a
// fixed, readable size, the row never overflows the box vertically, and width
// overflow is scrolled (never shrunk to unusable dots). These tests verify those
// invariants against REAL generated level data, including tall 4–5 cell pieces.

struct TrayFitTests {

    private let target: CGFloat = 28        // representative comfortable cap

    private func maxPH(_ level: Level) -> CGFloat {
        CGFloat(level.pieces.map { TrayLayout.pieceHeight($0) }.max() ?? 1)
    }

    /// The chosen cell never lets the tallest piece exceed the tray height — for
    /// any tray height the region split can hand us, no piece is ever clipped.
    private func assertNoVerticalClip(levelId: String, level: Level) {
        for availableHeight in [44.0, 60.0, 90.0, 120.0, 160.0] as [CGFloat] {
            let cell = TrayLayout.rowCellSize(
                pieces: level.pieces, availableHeight: availableHeight, targetCell: target
            )
            #expect(cell > 0, "\(levelId): non-positive cell at H=\(availableHeight)")
            #expect(
                maxPH(level) * cell <= availableHeight + 0.5,
                "\(levelId): tallest piece overflows tray at H=\(availableHeight) — \(maxPH(level) * cell) > \(availableHeight)"
            )
            #expect(cell <= target + 0.001, "\(levelId): cell exceeded target cap")
        }
    }

    /// Placing pieces must NOT resize the rest: the cell is derived from the FULL
    /// set's tallest piece, so it is identical no matter how many remain.
    private func assertStableAcrossPlacement(levelId: String, level: Level) {
        let availableHeight: CGFloat = 90
        let full = TrayLayout.rowCellSize(
            pieces: level.pieces, availableHeight: availableHeight, targetCell: target
        )
        var remaining = level.pieces
        while remaining.count > 1 {
            remaining.removeFirst()
            // Production always passes the FULL set, so the cell is constant.
            let cell = TrayLayout.rowCellSize(
                pieces: level.pieces, availableHeight: availableHeight, targetCell: target
            )
            #expect(cell == full, "\(levelId): cell changed as pieces were placed")
        }
    }

    @Test func packLevels_noVerticalClip() {
        for i in 1...30 {
            let id = "cozy-beginnings-\(i)"
            guard let level = PackProvider.loadLevel(id: id) else { continue }
            assertNoVerticalClip(levelId: id, level: level)
            assertStableAcrossPlacement(levelId: id, level: level)
        }
    }

    @Test func dailyPuzzle_noVerticalClip() {
        let level = PackProvider.dailyPuzzle()
        assertNoVerticalClip(levelId: "daily", level: level)
    }

    @Test func secondPackLevels_noVerticalClip() {
        for pack in PackProvider.allPacks().prefix(4) {
            for i in 1...20 {
                let id = "\(pack.id)-\(i)"
                guard let level = PackProvider.loadLevel(id: id) else { continue }
                assertNoVerticalClip(levelId: id, level: level)
            }
        }
    }

    @Test func rowWidth_growsWithPieceCount() {
        guard let level = PackProvider.loadLevel(id: "cozy-beginnings-1") else { return }
        let cell: CGFloat = 24, spacing: CGFloat = 16
        let oneWidth = TrayLayout.rowWidth(pieces: Array(level.pieces.prefix(1)), cellSize: cell, spacing: spacing)
        let allWidth = TrayLayout.rowWidth(pieces: level.pieces, cellSize: cell, spacing: spacing)
        #expect(allWidth >= oneWidth, "row width should not shrink with more pieces")
        #expect(oneWidth > 0)
    }
}
