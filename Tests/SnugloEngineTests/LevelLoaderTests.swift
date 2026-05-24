import XCTest
@testable import SnugloEngine

final class LevelLoaderTests: XCTestCase {

    // MARK: - Bireysel yükleme testleri

    func testLoadsLevel5x5() throws {
        let level = try LevelLoader().loadLevel(named: "level_5x5")
        XCTAssertEqual(level.id, "level_5x5")
        XCTAssertEqual(level.width, 5)
        XCTAssertEqual(level.height, 5)
        XCTAssertFalse(level.pieces.isEmpty)
        XCTAssertFalse(level.solution.isEmpty)
        XCTAssertEqual(level.pieces.count, 5)
        XCTAssertEqual(level.solution.count, 5)
    }

    func testLoadsLevel6x6() throws {
        let level = try LevelLoader().loadLevel(named: "level_6x6")
        XCTAssertEqual(level.id, "level_6x6")
        XCTAssertEqual(level.width, 6)
        XCTAssertEqual(level.height, 6)
        XCTAssertEqual(level.pieces.count, 6)
        XCTAssertEqual(level.solution.count, 6)
    }

    func testLoadsLevel7x7() throws {
        let level = try LevelLoader().loadLevel(named: "level_7x7")
        XCTAssertEqual(level.id, "level_7x7")
        XCTAssertEqual(level.width, 7)
        XCTAssertEqual(level.height, 7)
        XCTAssertEqual(level.pieces.count, 7)
        XCTAssertEqual(level.solution.count, 7)
    }

    // MARK: - Solution geçerlilik testleri

    func testEachShippedLevelHasValidSolution() throws {
        let names = ["level_5x5", "level_6x6", "level_7x7"]
        let checker = SolutionChecker()
        for name in names {
            let level = try LevelLoader().loadLevel(named: name)
            let result = checker.check(level: level, placements: level.solution)
            XCTAssertEqual(result, .valid, "\(name) solution must be .valid")
        }
    }

    // MARK: - Hata testi

    func testThrowsOnMissingLevel() {
        XCTAssertThrowsError(try LevelLoader().loadLevel(named: "nonexistent")) { error in
            guard let loaderError = error as? LevelLoader.LoaderError else {
                XCTFail("Expected LevelLoader.LoaderError, got \(type(of: error))")
                return
            }
            XCTAssertEqual(loaderError, .notFound("nonexistent"))
        }
    }
}
