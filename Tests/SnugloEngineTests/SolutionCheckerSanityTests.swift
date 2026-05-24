import XCTest
@testable import SnugloEngine

final class SolutionCheckerSanityTests: XCTestCase {

    // MARK: - emptyGrid

    func testEmptyGridReturnsEmptyGrid() {
        let level = Level(id: "empty", width: 0, height: 0, pieces: [], solution: [])
        let result = SolutionChecker().check(level: level, placements: [])
        XCTAssertEqual(result, .emptyGrid)
    }
}
