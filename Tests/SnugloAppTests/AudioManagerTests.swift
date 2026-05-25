import XCTest
@testable import SnugloApp

// MARK: — AudioManagerTests
// Faz F: AudioManager persistence + no-op guard tests.
// Uses isolated UserDefaults suite to avoid polluting real data.
// NOTE: AVAudioPlayer is NOT tested (requires audio hardware / system).
//       We test only the manager state + persistence logic.

final class AudioManagerTests: XCTestCase {

    // MARK: - Factory

    private func makeManager() -> AudioManager {
        let suite = "test.audio.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        return AudioManager(defaults: ud)
    }

    // MARK: - testSoundEnabledDefaultIsTrue

    func testSoundEnabledDefaultIsTrue() {
        let manager = makeManager()
        XCTAssertTrue(manager.soundEnabled, "Sound should be enabled by default")
    }

    // MARK: - testMusicEnabledDefaultIsFalse

    func testMusicEnabledDefaultIsFalse() {
        let manager = makeManager()
        XCTAssertFalse(manager.musicEnabled, "Music should be disabled by default")
    }

    // MARK: - testSoundEnabledTogglePersists

    func testSoundEnabledTogglePersists() {
        let suite = "test.audio.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!

        let m1 = AudioManager(defaults: ud)
        XCTAssertTrue(m1.soundEnabled)

        m1.soundEnabled = false

        // A new instance reading the same suite should see false
        let m2 = AudioManager(defaults: ud)
        XCTAssertFalse(m2.soundEnabled, "soundEnabled=false should persist to UserDefaults")
    }

    // MARK: - testMusicEnabledTogglePersists

    func testMusicEnabledTogglePersists() {
        let suite = "test.audio.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!

        let m1 = AudioManager(defaults: ud)
        XCTAssertFalse(m1.musicEnabled)

        m1.musicEnabled = true

        let m2 = AudioManager(defaults: ud)
        XCTAssertTrue(m2.musicEnabled, "musicEnabled=true should persist to UserDefaults")
    }

    // MARK: - testPlayNoopWhenDisabled

    func testPlayNoopWhenDisabled() {
        let manager = makeManager()
        manager.soundEnabled = false

        // play() should not crash even when players dict is empty (no audio files in test bundle)
        // and soundEnabled is false. This is the no-op guard test.
        for sfx in AudioManager.Sfx.allCases {
            manager.play(sfx)   // must not throw / crash
        }

        XCTAssertFalse(manager.soundEnabled)
    }

    // MARK: - testPlayNoopWithNoAudioFiles

    func testPlayNoopWithNoAudioFiles() {
        let manager = makeManager()
        manager.soundEnabled = true

        // In the test environment the audio files don't exist in the bundle,
        // so players dict is empty. play() must silently no-op.
        for sfx in AudioManager.Sfx.allCases {
            manager.play(sfx)   // must not crash
        }

        // No assertion needed — reaching here means no crash = pass.
    }

    // MARK: - testSfxCaseCount

    func testSfxCaseCount() {
        // Ensure all 5 expected SFX cases exist in the enum.
        let expected: Set<String> = ["pickup", "drop", "snap", "levelComplete", "error"]
        let actual = Set(AudioManager.Sfx.allCases.map(\.rawValue))
        XCTAssertEqual(actual, expected, "AudioManager.Sfx enum should have exactly 5 cases")
    }
}
