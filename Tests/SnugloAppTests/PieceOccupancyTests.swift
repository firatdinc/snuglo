import XCTest
@testable import SnugloApp
import SnugloEngine

// MARK: — PieceOccupancyTests
// Guards the "grabbed the wrong placed piece" regression: a cell inside an
// L-shaped piece's bounding-box GAP must belong to the neighbour sitting there,
// never to the L. (This is the logic the cell-accurate hit-testing reflects.)

final class PieceOccupancyTests: XCTestCase {

    func testGapCellBelongsToNeighbourNotTheLBoundingBox() {
        // L occupies (0,0),(1,0),(1,1) — its bounding box also covers the gap (0,1).
        let lPiece = Piece(id: "L", cells: [Coord(x: 0, y: 0), Coord(x: 1, y: 0), Coord(x: 1, y: 1)])
        // Neighbour sitting in that gap cell.
        let gapPiece = Piece(id: "P", cells: [Coord(x: 0, y: 0)])
        let pieces = [lPiece, gapPiece]
        let origins: [PieceID: Coord] = ["L": Coord(x: 0, y: 0), "P": Coord(x: 0, y: 1)]

        // The gap cell must resolve to the neighbour, NOT the L bounding box.
        XCTAssertEqual(PieceOccupancy.occupant(at: Coord(x: 0, y: 1), origins: origins, pieces: pieces), "P")
        // A genuinely-filled L cell resolves to L.
        XCTAssertEqual(PieceOccupancy.occupant(at: Coord(x: 1, y: 1), origins: origins, pieces: pieces), "L")
        // An empty cell resolves to nil.
        XCTAssertNil(PieceOccupancy.occupant(at: Coord(x: 4, y: 4), origins: origins, pieces: pieces))
    }
}
