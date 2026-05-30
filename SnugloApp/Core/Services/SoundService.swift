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
        // Perf fix: configure the session and build players OFF the main thread.
        // `AVAudioSession.setActive(true)` and `AVAudioPlayer` construction can
        // block for SECONDS on first use, and this singleton is lazily created
        // by the FIRST drag gesture — that main-thread stall was freezing the
        // first drag ("System gesture gate timed out"). play() is a safe no-op
        // until the players have loaded in the background.
        Task.detached(priority: .userInitiated) { [weak self] in
            Self.configureSession()
            let loaded = Self.buildPlayers()
            await self?.store(players: loaded)
        }
    }

    /// Touch `.shared` ahead of the first gesture so the background setup above
    /// has already started. Idempotent — see GameView.onAppear.
    func warmUp() {}

    private func store(players: [Sound: AVAudioPlayer]) {
        self.players = players
    }

    // MARK: — AVAudioSession (runs off-main)
    nonisolated private static func configureSession() {
        do {
            try AVAudioSession.sharedInstance()
                .setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[SoundService] Session config error: \(error)")
        }
    }

    // MARK: — Preload (runs off-main)
    nonisolated private static func buildPlayers() -> [Sound: AVAudioPlayer] {
        var result: [Sound: AVAudioPlayer] = [:]
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "caf") else {
                print("[SoundService] Missing asset: \(sound.rawValue).caf")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                result[sound] = player
            } catch {
                print("[SoundService] Failed to load \(sound.rawValue): \(error)")
            }
        }
        return result
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
