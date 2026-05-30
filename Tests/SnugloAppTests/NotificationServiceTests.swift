import XCTest
import UserNotifications
@testable import SnugloApp

// MARK: — NotificationServiceTests (Faz F)
// Tests focus on the pure, testable parts of NotificationService:
//   • makeComponents(from:) — pure Date → DateComponents extraction
//   • reschedule(enabled:at:) — does not crash, handles both paths
//   • identifier constant — must be "snuglo.daily.reminder"
//   • requestAuthorization — silent fail path (permission denied in tests → still no crash)
//
// UNUserNotificationCenter cannot be swapped in simulator tests without an entitlement,
// so scheduling calls are smoke-tested (no crash / silent fail).

@MainActor
final class NotificationServiceTests: XCTestCase {

    // MARK: - Helpers

    /// Build a Date from explicit hour + minute in the current Calendar.
    private func makeTime(hour: Int, minute: Int) -> Date {
        var comps = DateComponents()
        comps.year   = 2026
        comps.month  = 1
        comps.day    = 1
        comps.hour   = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }

    // MARK: - Test 1: makeComponents produces correct hour

    func test_makeComponents_correctHour() {
        let date   = makeTime(hour: 9, minute: 30)
        let comps  = NotificationService.makeComponents(from: date)
        XCTAssertEqual(comps.hour, 9, "makeComponents must extract hour=9 from 09:30")
    }

    // MARK: - Test 2: makeComponents produces correct minute

    func test_makeComponents_correctMinute() {
        let date   = makeTime(hour: 9, minute: 30)
        let comps  = NotificationService.makeComponents(from: date)
        XCTAssertEqual(comps.minute, 30, "makeComponents must extract minute=30 from 09:30")
    }

    // MARK: - Test 3: midnight (00:00) produces hour=0, minute=0

    func test_makeComponents_midnight() {
        let date   = makeTime(hour: 0, minute: 0)
        let comps  = NotificationService.makeComponents(from: date)
        XCTAssertEqual(comps.hour, 0, "Midnight → hour=0")
        XCTAssertEqual(comps.minute, 0, "Midnight → minute=0")
    }

    // MARK: - Test 4: end-of-day (23:59) is stable

    func test_makeComponents_endOfDay() {
        let date   = makeTime(hour: 23, minute: 59)
        let comps  = NotificationService.makeComponents(from: date)
        XCTAssertEqual(comps.hour, 23, "23:59 → hour=23")
        XCTAssertEqual(comps.minute, 59, "23:59 → minute=59")
    }

    // MARK: - Test 5: makeComponents only extracts hour + minute (no year/day leakage)

    func test_makeComponents_onlyHourAndMinute() {
        let date  = makeTime(hour: 8, minute: 45)
        let comps = NotificationService.makeComponents(from: date)
        XCTAssertNil(comps.year, "makeComponents must not include year")
        XCTAssertNil(comps.month, "makeComponents must not include month")
        XCTAssertNil(comps.day, "makeComponents must not include day")
        XCTAssertNotNil(comps.hour, "makeComponents must include hour")
        XCTAssertNotNil(comps.minute, "makeComponents must include minute")
    }

    // MARK: - Test 6: dailyIdentifier is the correct constant

    func test_dailyIdentifier_isCorrect() {
        XCTAssertEqual(NotificationService.dailyIdentifier, "snuglo.daily.reminder",
                       "Identifier must be exactly \"snuglo.daily.reminder\"")
    }

    // MARK: - Test 7: reschedule(enabled:false) must not crash

    func test_reschedule_disabled_doesNotCrash() {
        NotificationService.shared.reschedule(enabled: false, at: makeTime(hour: 19, minute: 0))
        XCTAssertTrue(true, "reschedule(enabled:false) must not crash")
    }

    // MARK: - Test 8: reschedule(enabled:true) must not crash

    func test_reschedule_enabled_doesNotCrash() {
        NotificationService.shared.reschedule(enabled: true, at: makeTime(hour: 9, minute: 0))
        XCTAssertTrue(true, "reschedule(enabled:true) must not crash (silent fail if denied)")
    }

    // MARK: - Test 9: requestAuthorization must not crash (permission denied path in simulator)

    func test_requestAuthorization_doesNotCrash() async throws {
        // Skip when status is .notDetermined: macOS/Simulator would show a system dialog
        // that blocks headless test runners indefinitely.
        let settings: UNNotificationSettings = await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getNotificationSettings { cont.resume(returning: $0) }
        }
        guard settings.authorizationStatus != .notDetermined else {
            throw XCTSkip("Notification permission not yet determined — skipping to avoid system dialog in CI")
        }
        await NotificationService.shared.requestAuthorization()
        XCTAssertTrue(true, "requestAuthorization must not crash even when denied")
    }

    // MARK: - Test 10: cancelDaily must not crash

    func test_cancelDaily_doesNotCrash() {
        NotificationService.shared.cancelDaily()
        XCTAssertTrue(true, "cancelDaily must not crash (idempotent)")
    }

    // MARK: - Test 11: shared singleton is the same instance

    func test_shared_isSingleton() {
        let a = NotificationService.shared
        let b = NotificationService.shared
        XCTAssertIdentical(a, b, "NotificationService.shared must always return the same instance")
    }
}
