import XCTest
@testable import SnugloApp
import SnugloEngine

/// Unit tests for `SnapCalculator` — verifies the finger-position → grid-Coord algebra.
///
/// ## Grid setup used across tests
/// - `gridFrame`: `CGRect(x: 20, y: 100, width: 60, height: 60)`
/// - Level: 5 × 5 cells → `cellSize = 60 / 5 = 12 pt`
/// - `snapBuffer`: 15 pt (default)
///
/// ## Coordinate math cheat-sheet
/// ```
/// localX = fingerX − pieceCols·cellSize/2 − gridFrame.minX
/// localY = fingerY − pieceRows·cellSize/2 − gridFrame.minY
/// col = round(localX / cellSize)   (clamped to 0 … width−pieceCols)
/// row = round(localY / cellSize)   (clamped to 0 … height−pieceRows)
/// ```
final class SnapCalculatorTests: XCTestCase {

    // MARK: - Fixtures

    /// gridFrame: origin (20,100), 60×60 pt → cellSize = 12 pt for a 5×5 level
    private let gridFrame = CGRect(x: 20, y: 100, width: 60, height: 60)
    private let levelW = 5, levelH = 5   // 5×5

    private func makeSingleCell(id: String = "dot") -> Piece {
        Piece(id: id, cells: [Coord(x: 0, y: 0)])
    }

    private func makeHorizontal2(id: String = "h2") -> Piece {
        Piece(id: id, cells: [Coord(x: 0, y: 0), Coord(x: 1, y: 0)])
    }

    private func makeCalc(buffer: CGFloat = 15) -> SnapCalculator {
        SnapCalculator(
            gridFrame: gridFrame,
            levelWidth: levelW,
            levelHeight: levelH,
            snapBuffer: buffer
        )
    }

    // MARK: - Single-cell piece (pieceCols=1, pieceRows=1, cellSize=12)

    /// Finger at exact grid center → snap to Coord(2,2).
    ///
    /// Grid center (gameLayout): x = 20+30 = 50, y = 100+30 = 130
    /// localX = 50 − 1·12/2 − 20 = 24  → col = round(24/12) = 2
    /// localY = 130 − 1·12/2 − 100 = 24 → row = round(24/12) = 2
    func test_singleCell_fingerAtGridCenter_snapsToCenter() {
        let finger = CGPoint(x: 50, y: 130)   // grid center in gameLayout
        let result = makeCalc().snap(fingerAt: finger, piece: makeSingleCell())
        XCTAssertEqual(result, Coord(x: 2, y: 2), "Center finger should snap to (2,2)")
    }

    /// Finger at grid top-left corner → snap to Coord(0,0).
    ///
    /// Top-left of grid (gameLayout): x=20, y=100
    /// Piece center should be at x = 20 + 12/2 = 26, y = 100 + 12/2 = 106
    /// localX = 26 − 6 − 20 = 0  → col = 0
    /// localY = 106 − 6 − 100 = 0 → row = 0
    func test_singleCell_fingerAtTopLeft_snapsToOrigin() {
        let finger = CGPoint(x: 26, y: 106)   // piece center when origin at (0,0)
        let result = makeCalc().snap(fingerAt: finger, piece: makeSingleCell())
        XCTAssertEqual(result, Coord(x: 0, y: 0), "Top-left finger should snap to (0,0)")
    }

    /// Finger at bottom-right cell center → snap to Coord(4,4).
    ///
    /// Cell (4,4) top-left in gameLayout: x = 20 + 4·12 = 68, y = 100 + 4·12 = 148
    /// Piece center: x = 68 + 6 = 74, y = 148 + 6 = 154
    /// localX = 74 − 6 − 20 = 48 → col = round(48/12) = 4
    /// localY = 154 − 6 − 100 = 48 → row = round(48/12) = 4
    func test_singleCell_fingerAtBottomRight_snapsToLastCell() {
        let finger = CGPoint(x: 74, y: 154)
        let result = makeCalc().snap(fingerAt: finger, piece: makeSingleCell())
        XCTAssertEqual(result, Coord(x: 4, y: 4), "Bottom-right finger should snap to (4,4)")
    }

    // MARK: - Horizontal 2-cell piece (pieceCols=2, pieceRows=1)

    /// Finger positioned to snap 2-wide piece to origin (0,0).
    ///
    /// Piece width = 2·cellSize = 24; center-x offset = 12.
    /// To place at col 0: localX must round to 0 → localX = 0
    /// fingerX = 0 + 2·12/2 + 20 = 12 + 20 = 32; fingerY = 0 + 1·12/2 + 100 = 6 + 100 = 106
    func test_horizontal2_fingerSnapsToOrigin() {
        let finger = CGPoint(x: 32, y: 106)
        let result = makeCalc().snap(fingerAt: finger, piece: makeHorizontal2())
        XCTAssertEqual(result, Coord(x: 0, y: 0))
    }

    /// Finger positioned to snap 2-wide piece to column 3 (rightmost valid col = 5−2 = 3).
    ///
    /// localX for col 3: 3·12 = 36 → fingerX = 36 + 12 + 20 = 68
    /// fingerY: same as origin row → 106
    func test_horizontal2_fingerSnapsToLastValidColumn() {
        let finger = CGPoint(x: 68, y: 106)
        let result = makeCalc().snap(fingerAt: finger, piece: makeHorizontal2())
        XCTAssertEqual(result, Coord(x: 3, y: 0),
                       "Col 3 is the last valid column for a 2-wide piece in a 5-wide grid")
    }

    // MARK: - Out-of-bounds / nil cases

    /// Finger far outside grid (right side) → nil.
    func test_fingerFarRight_returnsNil() {
        let finger = CGPoint(x: 300, y: 130)
        let result = makeCalc().snap(fingerAt: finger, piece: makeSingleCell())
        XCTAssertNil(result, "Far-right finger should return nil")
    }

    /// Finger far above grid → nil.
    func test_fingerFarAbove_returnsNil() {
        let finger = CGPoint(x: 50, y: 0)
        let result = makeCalc().snap(fingerAt: finger, piece: makeSingleCell())
        XCTAssertNil(result, "Far-above finger should return nil")
    }

    /// gridFrame.width == 0 (grid not laid out yet) → nil.
    func test_zeroWidthGrid_returnsNil() {
        let calc = SnapCalculator(
            gridFrame: CGRect(x: 0, y: 0, width: 0, height: 0),
            levelWidth: 5, levelHeight: 5
        )
        let result = calc.snap(fingerAt: CGPoint(x: 10, y: 10), piece: makeSingleCell())
        XCTAssertNil(result, "Zero-width grid should always return nil")
    }

    // MARK: - Buffer edge: finger just within buffer → non-nil

    /// Finger at exactly `gridFrame.minX - buffer + ε` on X (single-cell) → should NOT be nil.
    ///
    /// For single-cell: localX = fingerX − 6 − 20
    /// To be at -buffer: localX = -15 → fingerX = -15 + 6 + 20 = 11
    /// At fingerX = 11: localX = 11 − 6 − 20 = -15 → exactly on boundary → guard passes (>=)
    /// col = round(-15/12) = round(-1.25) = -1 → clamped to 0
    func test_fingerJustAtBufferBoundary_returnsClampedCoord() {
        let finger = CGPoint(x: 11, y: 106)  // localX = -15 exactly (on boundary)
        let result = makeCalc().snap(fingerAt: finger, piece: makeSingleCell())
        XCTAssertNotNil(result, "Finger exactly at buffer edge should return a coord (clamped)")
        XCTAssertEqual(result?.x, 0, "Clamped to column 0")
    }
}
