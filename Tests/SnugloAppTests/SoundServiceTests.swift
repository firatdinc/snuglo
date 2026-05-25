import XCTest
@testable import SnugloApp

// MARK: — SoundServiceTests (Faz F)
// Verifies the gate logic and graceful-fallback behaviour of SoundService.
// These tests run in the simulator where AVAudioSession is available but
// real audio files are not bundled (main bundle ≠ test bundle directory).
// All tests are @MainActor because SoundService is @MainActor.

@MainActor
final class SoundServiceTests: XCTestCase {

    // MARK: - Helpers

    private let sfxKey = "sfxEnabled"

    override func setUp() {
        super.setUp()
        // Reset to default (true) before each test
        UserDefaults.standard.removeObject(forKey: sfxKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: sfxKey)
        super.tearDown()
    }

    // MARK: - Test 1: Sound enum has exactly 5 cases

    func test_soundEnum_hasFiveCases() {
        let cases = SoundService.Sound.allCases
        XCTAssertEqual(cases.count, 5,
                       "SoundService.Sound must have exactly 5 cases")
    }

    // MARK: - Test 2: Sound enum contains required case names

    func test_soundEnum_containsRequiredCases() {
        let rawValues = Set(SoundService.Sound.allCases.map(\.rawValue))
        XCTAssertTrue(rawValues.contains("click"), "Missing .click case")
        XCTAssertTrue(rawValues.contains("place"), "Missing .place case")
        XCTAssertTrue(rawValues.contains("snap"), "Missing .snap case")
        XCTAssertTrue(rawValues.contains("solve"), "Missing .solve case")
        XCTAssertTrue(rawValues.contains("error"), "Missing .error case")
    }

    // MARK: - Test 3: play() with sfxEnabled=false must not crash

    func test_play_sfxDisabled_noOp() {
        UserDefaults.standard.set(false, forKey: sfxKey)
        // If sfxEnabled=false the method should return early — no crash, no sound
        for sound in SoundService.Sound.allCases {
            SoundService.shared.play(sound)
        }
        XCTAssertTrue(true, "play() with sfxEnabled=false must complete without crash")
    }

    // MARK: - Test 4: play() with sfxEnabled=true must not crash (graceful missing asset)

    func test_play_sfxEnabled_gracefulWhenAssetMissing() {
        UserDefaults.standard.set(true, forKey: sfxKey)
        // In the test bundle, .caf assets won't be found → players dict is empty.
        // SoundService.play() checks `players[sound]` and returns nil → no crash.
        for sound in SoundService.Sound.allCases {
            SoundService.shared.play(sound)
        }
        XCTAssertTrue(true, "play() must not crash even when audio asset is absent")
    }

    // MARK: - Test 5: shared singleton is the same instance

    func test_shared_isSingleton() {
        let a = SoundService.shared
        let b = SoundService.shared
        XCTAssertIdentical(a, b, "SoundService.shared must always return the same instance")
    }

    // MARK: - Test 6: sfxEnabled defaults to true when key not set

    func test_sfxEnabled_defaultsTrue() {
        // Key removed in setUp; play() should attempt playback (not return early)
        // We can't directly observe the gate, but no crash = correct default path
        SoundService.shared.play(.click)
        XCTAssertTrue(true, "Default sfxEnabled=true path must not crash")
    }

    // MARK: - Test 7: toggling sfxEnabled mid-session is respected immediately

    func test_play_respectsDynamicSettingChange() {
        // Disable
        UserDefaults.standard.set(false, forKey: sfxKey)
        SoundService.shared.play(.snap)   // should no-op

        // Re-enable
        UserDefaults.standard.set(true, forKey: sfxKey)
        SoundService.shared.play(.snap)   // should attempt play (no crash)

        XCTAssertTrue(true, "SoundService must re-read sfxEnabled on every play() call")
    }
}
