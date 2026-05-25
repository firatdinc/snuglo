import AVFoundation
import Observation

// MARK: — AudioManager
// Faz F: SFX + BGM scaffolding.
//
// Real audio files live in SnugloApp/Resources/Audio/.
// If a file is absent, player is nil → play() is a silent no-op.
// Sound-designer delivers wav/mp3 assets in Faz J.
//
// Faz G hook: To unlock premium BGM tracks via StoreKit,
// call `startBGM(track:)` with the unlocked track name instead of
// the default "bgm_cozy". Gate behind ProgressStore.isPremium or
// StoreManager.isPurchased(.premiumMusic).

@Observable
final class AudioManager {

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Sound Effect Types

    enum Sfx: String, CaseIterable {
        case pickup         // piece lifted from tray
        case drop           // piece returned without snap
        case snap           // piece locked into valid position
        case levelComplete  // all pieces placed — level solved
        case error          // invalid placement attempt

        var filename: String { rawValue }
    }

    // MARK: - State (@Observable)

    var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: Keys.sound)
            if !soundEnabled { stopAllSfx() }
        }
    }

    var musicEnabled: Bool {
        didSet {
            defaults.set(musicEnabled, forKey: Keys.music)
            musicEnabled ? startBGM() : stopBGM()
        }
    }

    // MARK: - Private

    private let defaults: UserDefaults
    private var players: [Sfx: AVAudioPlayer] = [:]
    private var bgmPlayer: AVAudioPlayer?

    private enum Keys {
        static let sound = "snuglo.sound.enabled"
        static let music = "snuglo.music.enabled"
    }

    // MARK: - Init

    /// Production singleton init — uses UserDefaults.standard.
    private convenience init() {
        self.init(defaults: .standard)
    }

    /// Testable init — accepts isolated UserDefaults suite.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        self.musicEnabled = defaults.object(forKey: Keys.music) as? Bool ?? false
        preload()
    }

    // MARK: - Preload

    private func preload() {
        configureAudioSession()
        for sfx in Sfx.allCases {
            guard let url = bundleURL(for: sfx.filename) else { continue }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[sfx] = player
            } catch {
                // Silent fallback — file exists but can't be decoded
            }
        }
    }

    private func configureAudioSession() {
        // .ambient → mixes with other apps, respects silent switch.
        // Do NOT use .playback — that would duck Spotify etc.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func bundleURL(for name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "wav")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3")
    }

    // MARK: - SFX

    /// Play a sound effect. No-op if soundEnabled = false or file not found.
    func play(_ sfx: Sfx) {
        guard soundEnabled, let player = players[sfx] else { return }
        if player.isPlaying { player.currentTime = 0 }
        player.play()
    }

    private func stopAllSfx() {
        players.values.forEach { $0.stop() }
    }

    // MARK: - BGM

    /// Start background music. No-op if musicEnabled = false or file not found.
    func startBGM(track: String = "bgm_cozy") {
        guard musicEnabled else { return }
        guard let url = bundleURL(for: track) else { return }
        if bgmPlayer == nil || bgmPlayer?.url != url {
            bgmPlayer = try? AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1  // infinite loop
            bgmPlayer?.volume = 0.4
            bgmPlayer?.prepareToPlay()
        }
        bgmPlayer?.play()
    }

    func stopBGM() {
        bgmPlayer?.stop()
    }

    /// Pause BGM (e.g. when PauseSheet is shown). Call resumeBGM() to continue.
    func pauseBGM() {
        bgmPlayer?.pause()
    }

    func resumeBGM() {
        guard musicEnabled else { return }
        bgmPlayer?.play()
    }
}
