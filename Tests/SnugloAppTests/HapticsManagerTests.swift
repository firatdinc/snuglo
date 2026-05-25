import XCTest
@testable import SnugloApp

// MARK: — HapticsManagerTests
// Faz F: HapticsManager persistence + no-op guard tests.
// UIImpactFeedbackGenerator / UINotificationFeedbackGenerator are tested only
// for no-crash behaviour — physical taptic engine is not available in test runner.

final class HapticsManagerTests: XCTestCase {

    // MARK: - Factory

    private func makeManager() -> HapticsManager {
        let suite = "test.haptics.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        return HapticsManager(defaults: ud)
    }

    // MARK: - testHapticsEnabledDefaultIsTrue

    func testHapticsEnabledDefaultIsTrue() {
        let manager = makeManager()
        XCTAssertTrue(manager.enabled, "Haptics should be enabled by default")
    }

    // MARK: - testHapticsEnabledTogglePersists

    func testHapticsEnabledTogglePersists() {
        let suite = "test.haptics.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!

        let m1 = HapticsManager(defaults: ud)
        XCTAssertTrue(m1.enabled)

        m1.enabled = false

        // New instance reads from same suite
        let m2 = HapticsManager(defaults: ud)
        XCTAssertFalse(m2.enabled, "enabled=false should persist to UserDefaults")
    }

    // MARK: - testPlayNoopWhenDisabled

    func testPlayNoopWhenDisabled() {
        let manager = makeManager()
        manager.enabled = false

        // All feedback types must be no-ops and must not crash
        let allFeedback: [HapticsManager.Feedback] = [
            .light, .medium, .heavy, .success, .warning, .error, .selection
        ]
        for fb in allFeedback {
            manager.play(fb)   // must not crash
        }

        XCTAssertFalse(manager.enabled)
    }

    // MARK: - testPlayDoesNotCrashWhenEnabled

    func testPlayDoesNotCrashWhenEnabled() {
        let manager = makeManager()
        manager.enabled = true

        // Generators may silently fail on simulator (no taptic engine) but must not crash.
        let allFeedback: [HapticsManager.Feedback] = [
            .light, .medium, .heavy, .success, .warning, .error, .selection
        ]
        for fb in allFeedback {
            manager.play(fb)
        }

        // Reaching here = no crash = pass
    }
}
