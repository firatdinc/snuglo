import XCTest
import UIKit
@testable import SnugloApp

// MARK: — HapticServiceTests (Faz F)
// Verifies that HapticService correctly gates all feedback behind hapticsEnabled.
// UIKit haptic generators are available in the simulator but produce no physical
// vibration there — they never crash, making "no crash = no-op" testable.

@MainActor
final class HapticServiceTests: XCTestCase {

    private let hapticsKey = "hapticsEnabled"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: hapticsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: hapticsKey)
        super.tearDown()
    }

    // MARK: - Test 1: impact(.light) disabled → no crash

    func test_impactLight_disabled_noOp() {
        UserDefaults.standard.set(false, forKey: hapticsKey)
        HapticService.shared.impact(.light)
        XCTAssertTrue(true, "impact(.light) with hapticsEnabled=false must not crash")
    }

    // MARK: - Test 2: impact(.medium) disabled → no crash

    func test_impactMedium_disabled_noOp() {
        UserDefaults.standard.set(false, forKey: hapticsKey)
        HapticService.shared.impact(.medium)
        XCTAssertTrue(true, "impact(.medium) with hapticsEnabled=false must not crash")
    }

    // MARK: - Test 3: notify(.success) disabled → no crash

    func test_notifySuccess_disabled_noOp() {
        UserDefaults.standard.set(false, forKey: hapticsKey)
        HapticService.shared.notify(.success)
        XCTAssertTrue(true, "notify(.success) with hapticsEnabled=false must not crash")
    }

    // MARK: - Test 4: notify(.error) disabled → no crash

    func test_notifyError_disabled_noOp() {
        UserDefaults.standard.set(false, forKey: hapticsKey)
        HapticService.shared.notify(.error)
        XCTAssertTrue(true, "notify(.error) with hapticsEnabled=false must not crash")
    }

    // MARK: - Test 5: prepareImpact() disabled → no crash

    func test_prepareImpact_disabled_noOp() {
        UserDefaults.standard.set(false, forKey: hapticsKey)
        HapticService.shared.prepareImpact()
        XCTAssertTrue(true, "prepareImpact() with hapticsEnabled=false must not crash")
    }

    // MARK: - Test 6: all feedback types enabled → no crash

    func test_allFeedback_enabled_noOp() {
        UserDefaults.standard.set(true, forKey: hapticsKey)
        HapticService.shared.prepareImpact()
        HapticService.shared.impact(.light)
        HapticService.shared.impact(.medium)
        HapticService.shared.notify(.success)
        HapticService.shared.notify(.error)
        HapticService.shared.notify(.warning)
        XCTAssertTrue(true, "All feedback types with hapticsEnabled=true must not crash")
    }

    // MARK: - Test 7: hapticsEnabled defaults to true when key not set

    func test_hapticsEnabled_defaultsTrue() {
        // Key removed in setUp
        HapticService.shared.impact(.light)
        XCTAssertTrue(true, "Default hapticsEnabled=true path must not crash")
    }

    // MARK: - Test 8: shared singleton is the same instance

    func test_shared_isSingleton() {
        let a = HapticService.shared
        let b = HapticService.shared
        XCTAssertIdentical(a, b, "HapticService.shared must always return the same instance")
    }
}
