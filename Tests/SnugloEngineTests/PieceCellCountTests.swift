import XCTest
@testable import SnugloEngine

// MARK: — Faz B: Piece.cellCount property tests
// Verifies the UI-convenience computed property added in Faz B (B2).

final class PieceCellCountTests: XCTestCase {

    func test_cellCount_singleCell() {
        let piece = Piece(id: "p1", cells: [Coord(x: 0, y: 0)])
        XCTAssertEqual(piece.cellCount, 1)
    }

    func test_cellCount_horizontal2x1() {
        let piece = Piece(id: "p2", cells: [Coord(x: 0, y: 0), Coord(x: 1, y: 0)])
        XCTAssertEqual(piece.cellCount, 2)
    }

    func test_cellCount_2x2square() {
        let piece = Piece(id: "p3", cells: [
            Coord(x: 0, y: 0), Coord(x: 1, y: 0),
            Coord(x: 0, y: 1), Coord(x: 1, y: 1)
        ])
        XCTAssertEqual(piece.cellCount, 4)
    }

    func test_cellCount_matchesCellsCount() {
        let cells: [Coord] = [
            Coord(x: 0, y: 0), Coord(x: 1, y: 0), Coord(x: 2, y: 0),
            Coord(x: 0, y: 1), Coord(x: 1, y: 1)
        ]
        let piece = Piece(id: "p4", cells: cells)
        XCTAssertEqual(piece.cellCount, cells.count)
    }
}
