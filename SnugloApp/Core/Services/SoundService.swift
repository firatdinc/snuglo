import AVFoundation
import Foundation

// MARK: — SoundService (Faz F)
//
// Plays short sound effects using AVAudioPlayer.
// Audio session category: .ambient + .mixWithOthers — user music keeps playing.
// Preloads all 5 sounds on init; missing assets are logged, never crash.
// Gate: UserDefaults("sfxEnabled") checked on every play() call.

@MainActor
final class SoundService: NSObject {

    // MARK: — Singleton
    static let shared = SoundService()

    // MARK: — Sound catalogue
    enum Sound: String, CaseIterable {
        case click
        case place
        case snap
        case solve
        case error
    }

    // MARK: — Private state
    private var players: [Sound: AVAudioPlayer] = [:]

    // MARK: — Init (private — use .shared)
    private override init() {
        super.init()
        configureSession()
        preload()
    }

    // MARK: — AVAudioSession
    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance()
                .setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[SoundService] Session config error: \(error)")
        }
    }

    // MARK: — Preload
    private func preload() {
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "caf") else {
                print("[SoundService] Missing asset: \(sound.rawValue).caf")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[sound] = player
            } catch {
                print("[SoundService] Failed to load \(sound.rawValue): \(error)")
            }
        }
    }

    // MARK: — Public API

    /// Play a sound effect.
    /// No-op when `sfxEnabled` is false or the player is unavailable.
    func play(_ sound: Sound) {
        guard sfxEnabled else { return }
        guard let player = players[sound] else { return }
        // Restart if already playing (quick repeat taps)
        if player.isPlaying { player.currentTime = 0 }
        player.play()
    }

    // MARK: — Private helpers

    private var sfxEnabled: Bool {
        // Default true if key never set.
        UserDefaults.standard.object(forKey: "sfxEnabled") as? Bool ?? true
    }
}
