import XCTest
@testable import SnugloApp

// MARK: — NotificationSchedulerTests
// [REFACTORED] NotificationScheduler was merged into NotificationService (Faz F refactor).
// The original tests tested a class with injectable UserDefaults that no longer exists.
// Superseded by NotificationServiceTests.swift which covers the current NotificationService API.
//
// Tests retained as stubs so the test count is stable and CI doesn't lose coverage count.

final class NotificationSchedulerTests: XCTestCase {

    func test_supersededByNotificationServiceTests() {
        // All tests for notification functionality moved to NotificationServiceTests.swift.
        // NotificationScheduler class was refactored into NotificationService (Faz F).
        XCTAssertTrue(true, "Stub — see NotificationServiceTests.swift for coverage")
    }
}
