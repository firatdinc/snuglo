import AVFoundation
import Foundation

// MARK: — MusicService
//
// Looping background music with two themes: `bgm` (normal) and `bgm_zen`
// (Zen Mode). Shares the app's .ambient + .mixWithOthers session (configured by
// SoundService) and RESPECTS the user's own audio — if Music/Podcasts are
// playing we stay silent (Apple HIG). Players load off-main; volume crossfades
// so theme switches and start/stop feel calm, never jarring.
//
// Gate: UserDefaults("musicEnabled"). Drop-in assets: `bgm.caf` / `bgm_zen.caf`.

@MainActor
final class MusicService {

    // MARK: — Singleton
    static let shared = MusicService()
    private init() {}

    // MARK: — State
    private var player: AVAudioPlayer?
    private var currentName: String?
    private var foreground = true

    /// Zen Mode read LIVE from UserDefaults (not a cached flag) so the correct
    /// track is chosen no matter when refresh() runs — the RootView .id rebuild
    /// on zenMode can swallow onChange/onAppear timing, which previously left the
    /// calm track playing in Zen.
    private var zenActive: Bool { UserDefaults.standard.bool(forKey: "zenMode") }

    /// Headroom so music sits under SFX; the user slider scales within this.
    private let maxVolume: Float = 0.6
    private let fade: TimeInterval = 0.8

    /// User-controlled music level (0…1), default 0.6. Scaled by `maxVolume`.
    private var userVolume: Float {
        Float(UserDefaults.standard.object(forKey: "musicVolume") as? Double ?? 0.6)
    }
    /// Actual player volume = user level × headroom.
    private var targetVolume: Float { userVolume * maxVolume }

    // MARK: — Public API

    /// Re-evaluate what should be playing (Zen state is read live in `desiredTrack`).
    func update(zen: Bool = false) {
        refresh()
    }

    /// Foreground/background transitions from the scene phase.
    func setForeground(_ active: Bool) {
        foreground = active
        refresh()
    }

    /// Apply the user's music-volume slider to the currently-playing track live.
    func applyVolume() {
        player?.setVolume(targetVolume, fadeDuration: 0.2)
    }

    /// Re-evaluate desired playback against all gates. Idempotent.
    func refresh() {
        guard foreground, musicEnabled, !AVAudioSession.sharedInstance().isOtherAudioPlaying else {
            stop()
            return
        }
        let desired = desiredTrack
        if desired == currentName, player?.isPlaying == true { return }
        start(desired)
    }

    /// User track preference: "auto" (default — Zen track in Zen, else calm),
    /// "calm" (always bgm), "zen" (always bgm_zen).
    private var trackPreference: String {
        UserDefaults.standard.string(forKey: "musicTrack") ?? "auto"
    }
    /// The track that SHOULD play right now given preference + Zen state.
    private var desiredTrack: String {
        switch trackPreference {
        case "calm": return "bgm"
        case "zen":  return "bgm_zen"
        default:     return zenActive ? "bgm_zen" : "bgm"
        }
    }

    // MARK: — Private

    private func start(_ name: String) {
        let target = name
        let vol = targetVolume
        Task.detached(priority: .utility) {
            guard let url = Bundle.main.url(forResource: target, withExtension: "caf"),
                  let p = try? AVAudioPlayer(contentsOf: url) else {
                print("[MusicService] Missing asset: \(target).caf")
                return
            }
            p.numberOfLoops = -1   // seamless infinite loop
            p.volume = 0
            p.prepareToPlay()
            await self.install(p, name: target, volume: vol)
        }
    }

    private func install(_ p: AVAudioPlayer, name: String, volume: Float) {
        // Conditions may have changed while loading off-main — re-validate.
        guard foreground, musicEnabled,
              !AVAudioSession.sharedInstance().isOtherAudioPlaying,
              desiredTrack == name else { return }
        // Fade the outgoing track out, then drop it.
        if let old = player {
            old.setVolume(0, fadeDuration: fade)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(fade))
                old.stop()
            }
        }
        player = p
        currentName = name
        p.play()
        p.setVolume(volume, fadeDuration: fade)
    }

    private func stop() {
        guard let p = player else { return }
        player = nil
        currentName = nil
        p.setVolume(0, fadeDuration: fade)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(fade))
            p.stop()
        }
    }

    private var musicEnabled: Bool {
        UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true
    }
}
