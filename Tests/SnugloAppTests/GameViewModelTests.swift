import XCTest
import SnugloEngine
@testable import SnugloApp

/// GameViewModel unit tests — 4 original + 3 IOS-57 liftPiece tests + 2 IOS-58 hint tests.
@MainActor
final class GameViewModelTests: XCTestCase {

    // MARK: - Helpers

    /// Minimal 2×1 level: two single-cell pieces side by side.
    ///  Solution: p1 at (0,0), p2 at (1,0)
    private func makeSimpleLevel() -> Level {
        Level(
            id: "test_2x1",
            width: 2,
            height: 1,
            pieces: [
                Piece(id: "p1", cells: [Coord(x: 0, y: 0)]),
                Piece(id: "p2", cells: [Coord(x: 0, y: 0)])
            ],
            solution: [
                Placement(pieceId: "p1", origin: Coord(x: 0, y: 0)),
                Placement(pieceId: "p2", origin: Coord(x: 1, y: 0))
            ]
        )
    }

    // MARK: - Test 1: init → level loaded

    func test_init_levelIsSet() {
        let level = makeSimpleLevel()
        let vm = GameViewModel(level: level)

        XCTAssertEqual(vm.level.id, "test_2x1")
        XCTAssertEqual(vm.level.width, 2)
        XCTAssertEqual(vm.level.height, 1)
        XCTAssertEqual(vm.level.pieces.count, 2)
        XCTAssertTrue(vm.placements.isEmpty)
        XCTAssertTrue(vm.invalidPieceIDs.isEmpty)
        XCTAssertFalse(vm.isSolved)
    }

    // MARK: - Test 2: tryPlace valid coord → enters placements, invalidPieceIDs empty

    func test_tryPlace_validCoord_acceptedAndNoInvalid() {
        let vm = GameViewModel(level: makeSimpleLevel())

        vm.tryPlace(pieceID: "p1", at: Coord(x: 0, y: 0))

        XCTAssertNotNil(vm.placements["p1"],
                        "Valid placement should be stored in placements")
        XCTAssertEqual(vm.placements["p1"]?.origin.x, 0)
        XCTAssertEqual(vm.placements["p1"]?.origin.y, 0)
        XCTAssertFalse(vm.invalidPieceIDs.contains("p1"),
                       "Valid piece should NOT be in invalidPieceIDs")
        XCTAssertFalse(vm.isSolved, "Only one of two pieces placed — should not be solved")
    }

    // MARK: - Test 3: tryPlace overlap → invalidPieceIDs contains rejected piece, placement refused

    func test_tryPlace_overlap_addedToInvalidAndRejected() {
        let vm = GameViewModel(level: makeSimpleLevel())

        // Place p1 at (0,0) — valid
        vm.tryPlace(pieceID: "p1", at: Coord(x: 0, y: 0))
        XCTAssertNotNil(vm.placements["p1"])

        // Try to place p2 at (0,0) — overlaps p1
        vm.tryPlace(pieceID: "p2", at: Coord(x: 0, y: 0))

        XCTAssertTrue(vm.invalidPieceIDs.contains("p2"),
                      "Overlapping piece should be in invalidPieceIDs")
        XCTAssertNil(vm.placements["p2"],
                     "Overlapping piece should NOT be added to placements")
    }

    // MARK: - Test 4: all pieces placed → isSolved == true

    func test_allPiecesPlaced_isSolvedTrue() {
        let vm = GameViewModel(level: makeSimpleLevel())

        // Place p1 at (0,0)
        vm.tryPlace(pieceID: "p1", at: Coord(x: 0, y: 0))
        XCTAssertFalse(vm.isSolved, "Should not be solved after placing only p1")

        // Place p2 at (1,0) — completes the 2×1 grid
        vm.tryPlace(pieceID: "p2", at: Coord(x: 1, y: 0))

        XCTAssertTrue(vm.isSolved,
                      "After placing all pieces correctly, isSolved should be true")
        XCTAssertTrue(vm.invalidPieceIDs.isEmpty,
                      "No pieces should be invalid in solved state")
    }

    // MARK: - Test 5 (IOS-57): liftPiece removes from placements and stores snapshot

    func test_liftPiece_removesFromPlacementsAndStoresSnapshot() {
        let vm = GameViewModel(level: makeSimpleLevel())
        vm.tryPlace(pieceID: "p1", at: Coord(x: 0, y: 0))
        XCTAssertNotNil(vm.placements["p1"])

        vm.liftPiece(pieceID: "p1")

        XCTAssertNil(vm.placements["p1"],
                     "liftPiece should remove the piece from placements")
        XCTAssertNotNil(vm.liftSnapshot,
                        "liftPiece should store a snapshot for rollback")
        XCTAssertEqual(vm.liftSnapshot?.pieceID, "p1")
        XCTAssertEqual(vm.liftSnapshot?.placement.origin.x, 0)
        XCTAssertFalse(vm.isSolved,
                       "isSolved must be false after lifting a piece")
    }

    // MARK: - Test 6 (IOS-57): rollbackLift restores original placement

    func test_rollbackLift_restoresPlacement() {
        let vm = GameViewModel(level: makeSimpleLevel())
        vm.tryPlace(pieceID: "p1", at: Coord(x: 0, y: 0))
        vm.liftPiece(pieceID: "p1")
        XCTAssertNil(vm.placements["p1"], "precondition: piece is off the board")

        vm.rollbackLift()

        XCTAssertNotNil(vm.placements["p1"],
                        "rollbackLift should restore piece to original position")
        XCTAssertEqual(vm.placements["p1"]?.origin.x, 0)
        XCTAssertNil(vm.liftSnapshot,
                     "rollbackLift should clear the snapshot")
    }

    // MARK: - Test 7 (IOS-57): commitLift clears snapshot after successful re-placement

    func test_commitLift_clearsSnapshot() {
        let vm = GameViewModel(level: makeSimpleLevel())
        vm.tryPlace(pieceID: "p1", at: Coord(x: 0, y: 0))
        vm.liftPiece(pieceID: "p1")
        XCTAssertNotNil(vm.liftSnapshot, "precondition: snapshot exists after lift")

        vm.commitLift()

        XCTAssertNil(vm.liftSnapshot,
                     "commitLift should clear the snapshot")
    }

    // MARK: - Test 8 (IOS-58): applyHint places piece at solution coord and increments counter

    func test_applyHint_placesPieceAtSolutionOriginAndIncrementsCounter() {
        let vm = GameViewModel(level: makeSimpleLevel())
        let suite = "test.hint.apply.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        let store = ProgressStore(defaults: ud, key: suite)
        store.addHints(1)

        let result = vm.applyHint(store: store)

        XCTAssertTrue(result, "applyHint should return true when a hint is available")
        XCTAssertEqual(vm.hintsUsed, 1, "hintsUsed should increment by 1")
        XCTAssertNotNil(vm.placements["p1"],
                        "First unplaced piece should be placed after hint")
        XCTAssertEqual(vm.placements["p1"]?.origin.x, 0,
                       "Piece should be placed at its solution x origin")
        XCTAssertEqual(vm.placements["p1"]?.origin.y, 0,
                       "Piece should be placed at its solution y origin")
    }

    // MARK: - Test 9 (IOS-58): applyHint returns false and places nothing when hintCount == 0

    func test_applyHint_returnsFalseWhenNoHints() {
        let vm = GameViewModel(level: makeSimpleLevel())
        let suite = "test.hint.empty.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        let store = ProgressStore(defaults: ud, key: suite)
        // store.hintCount == 0 by default

        let result = vm.applyHint(store: store)

        XCTAssertFalse(result, "applyHint should return false when no hints remain")
        XCTAssertEqual(vm.hintsUsed, 0, "hintsUsed must stay 0 when no hint was consumed")
        XCTAssertTrue(vm.placements.isEmpty, "No piece should be placed when hint is unavailable")
    }
}
