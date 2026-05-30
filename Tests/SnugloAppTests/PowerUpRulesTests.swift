import XCTest
@testable import SnugloApp

// MARK: — PowerUpRulesTests
// Unit tests for pure applicability rules. No stores, no SwiftUI.

final class PowerUpRulesTests: XCTestCase {

    // MARK: — hint

    func testHint_applicable_whenUnplacedPiecesExist() {
        XCTAssertTrue(PowerUpRules.isApplicable(.hint, unplacedCount: 1, moveHistoryCount: 0))
        XCTAssertTrue(PowerUpRules.isApplicable(.hint, unplacedCount: 5, moveHistoryCount: 3))
    }

    func testHint_notApplicable_whenNoUnplacedPieces() {
        XCTAssertFalse(PowerUpRules.isApplicable(.hint, unplacedCount: 0, moveHistoryCount: 5))
    }

    // MARK: — undo

    func testUndo_applicable_whenHistoryIsNotEmpty() {
        XCTAssertTrue(PowerUpRules.isApplicable(.undo, unplacedCount: 0, moveHistoryCount: 1))
        XCTAssertTrue(PowerUpRules.isApplicable(.undo, unplacedCount: 3, moveHistoryCount: 4))
    }

    func testUndo_notApplicable_whenHistoryIsEmpty() {
        XCTAssertFalse(PowerUpRules.isApplicable(.undo, unplacedCount: 5, moveHistoryCount: 0))
    }

    // MARK: — shuffleTray

    func testShuffleTray_applicable_whenTwoPiecesUnplaced() {
        XCTAssertTrue(PowerUpRules.isApplicable(.shuffleTray, unplacedCount: 2, moveHistoryCount: 0))
        XCTAssertTrue(PowerUpRules.isApplicable(.shuffleTray, unplacedCount: 5, moveHistoryCount: 1))
    }

    func testShuffleTray_notApplicable_whenZeroOrOnePieceUnplaced() {
        XCTAssertFalse(PowerUpRules.isApplicable(.shuffleTray, unplacedCount: 0, moveHistoryCount: 3))
        XCTAssertFalse(PowerUpRules.isApplicable(.shuffleTray, unplacedCount: 1, moveHistoryCount: 3))
    }
}
