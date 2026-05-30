import Testing
import CoreGraphics
import SnugloEngine
@testable import SnugloApp

// MARK: — TrayFitTests
// Verifies the tray shrink-to-fit invariant against REAL generated level data
// (including tall 4–5 cell pieces in later levels): for every level, the chosen
// cell size lays the pieces out within the fixed tray height — i.e. no piece is
// ever clipped or pushed off-screen, for any level / piece shape.

struct TrayFitTests {

    /// Mirrors GameView.trayFitCell exactly (binary search) so the invariant is
    /// tested with the production algorithm.
    private func trayFitCell(
        pieces: [Piece],
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        cap: CGFloat,
        itemSpacing: CGFloat
    ) -> CGFloat {
        guard !pieces.isEmpty, availableWidth > 0, availableHeight > 0 else { return cap }
        func contentHeight(_ c: CGFloat) -> CGFloat {
            TrayLayout.compute(
                pieces: pieces, availableWidth: availableWidth,
                preferredCellSize: c, itemSpacing: itemSpacing
            ).contentHeight
        }
        if contentHeight(cap) <= availableHeight { return cap }
        var lo: CGFloat = 4
        var hi = cap
        for _ in 0..<24 {
            let mid = (lo + hi) / 2
            if contentHeight(mid) <= availableHeight { lo = mid } else { hi = mid }
        }
        return lo
    }

    private func assertFits(levelId: String, level: Level, screenW: CGFloat = 393) {
        let itemSpacing: CGFloat = 16          // AppSpacing.md
        let innerWidth = screenW - 24 * 4      // screen margin (lg×2) + tray pad (lg×2)
        let cap: CGFloat = ((screenW - 24 * 2) / CGFloat(level.width)) * 0.6

        // Stress the invariant across a range of tray content heights, including
        // the TIGHT ones the region split (≤42% of the board+tray budget) can
        // produce for tall-piece levels on small devices. trayFitCell must keep
        // every piece inside any of them.
        for trayContentH in [120.0, 160.0, 200.0, 260.0] as [CGFloat] {
            let availableHeight = trayContentH - 8 * 2   // minus inner vertical padding
            let fit = trayFitCell(
                pieces: level.pieces,
                availableWidth: innerWidth,
                availableHeight: availableHeight,
                cap: cap,
                itemSpacing: itemSpacing
            )
            let layout = TrayLayout.compute(
                pieces: level.pieces,
                availableWidth: innerWidth,
                preferredCellSize: fit,
                itemSpacing: itemSpacing
            )
            #expect(
                layout.contentHeight <= availableHeight + 0.5,
                "Tray pieces overflow for \(levelId) at trayH=\(trayContentH): contentHeight=\(layout.contentHeight) > \(availableHeight)"
            )
            #expect(fit >= 4, "fit cell underflow for \(levelId) at trayH=\(trayContentH)")
        }
    }

    @Test func packLevels_allFitTray() {
        // Sweep a range of levels including the tall-piece ones reported (e.g. 14, 16).
        for i in 1...30 {
            let id = "cozy-beginnings-\(i)"
            guard let level = PackProvider.loadLevel(id: id) else { continue }
            assertFits(levelId: id, level: level)
        }
    }

    @Test func dailyPuzzle_fitsTray() {
        let level = PackProvider.dailyPuzzle()
        assertFits(levelId: "daily", level: level)
    }

    @Test func secondPackLevels_fitTray() {
        // Cover other packs too (different grid sizes / piece pools).
        for pack in PackProvider.allPacks().prefix(4) {
            for i in 1...20 {
                let id = "\(pack.id)-\(i)"
                guard let level = PackProvider.loadLevel(id: id) else { continue }
                assertFits(levelId: id, level: level)
            }
        }
    }
}
