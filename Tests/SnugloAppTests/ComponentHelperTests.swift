import XCTest
@testable import SnugloApp

// MARK: — ComponentHelperTests
// Unit tests for pure (non-view) helpers in the Faz 2 component kit.

final class ComponentHelperTests: XCTestCase {

    // MARK: — ItemBadge.clampedStars

    func testClampedStars_belowRange() {
        XCTAssertEqual(ItemBadge.clampedStars(-5), 0)
        XCTAssertEqual(ItemBadge.clampedStars(-1), 0)
    }

    func testClampedStars_inRange() {
        XCTAssertEqual(ItemBadge.clampedStars(0), 0)
        XCTAssertEqual(ItemBadge.clampedStars(1), 1)
        XCTAssertEqual(ItemBadge.clampedStars(2), 2)
        XCTAssertEqual(ItemBadge.clampedStars(3), 3)
    }

    func testClampedStars_aboveRange() {
        XCTAssertEqual(ItemBadge.clampedStars(4), 3)
        XCTAssertEqual(ItemBadge.clampedStars(100), 3)
    }
}
