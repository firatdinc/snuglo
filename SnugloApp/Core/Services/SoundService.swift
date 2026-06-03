import AVFoundation
import Foundation

// MARK: — SoundPack
// Reshapes the SAME SFX samples into different tactile "feels" via playback
// params (volume + rate/pitch). Self-contained — no new assets. Real ASMR
// samples can be swapped in later without touching call sites.
enum SoundPack: String, CaseIterable, Identifiable {
    case classic, soft, crisp
    var id: String { rawValue }
    var nameKey: String { "soundpack.\(rawValue)" }
    var volume: Float { self == .soft ? 0.6 : 1.0 }
    var rate: Float {
        switch self {
        case .classic: return 1.0
        case .soft:    return 0.9
        case .crisp:   return 1.12
        }
    }
    static var active: SoundPack {
        SoundPack(rawValue: UserDefaults.standard.string(forKey: "soundPack") ?? "classic") ?? .classic
    }
}

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
    //
    // Drop a `<event>.caf` into the app bundle for any case below and it plays
    // automatically. Optional per-pack variants `<event>_soft.caf` /
    // `<event>_crisp.caf` override the base for that pack (played at native
    // rate, no pitch-shift). Cases with a `fallback` (reward/levelUp/combo)
    // gracefully reuse an existing base sound until a dedicated file is added.
    enum Sound: String, CaseIterable {
        case click
        case place
        case snap
        case solve
        case error
        // Dedicated event sounds — optional; fall back when the asset is absent.
        case reward     // chest / spin / streak / calendar reward reveal
        case levelUp    // player level-up celebration
        case combo      // rapid-place combo pop

        /// Base sound to reuse when this event has no dedicated asset loaded.
        var fallback: Sound? {
            switch self {
            case .reward, .levelUp: return .solve
            case .combo:            return .snap
            default:                return nil
            }
        }
    }

    // MARK: — Private state
    // Each asset gets a small POOL of players (keyed by base name, e.g. "place",
    // "place_soft"). Rapid/overlapping triggers round-robin across the pool so a
    // new tap never cuts off the previous one mid-sample — fixing "sounds
    // sometimes don't play fully".
    private var pools: [String: [AVAudioPlayer]] = [:]
    private var nextIndex: [String: Int] = [:]
    nonisolated private static let poolSize = 4

    /// Suffix used to look up a pack's dedicated sample (classic = base file).
    nonisolated private static func suffix(for pack: SoundPack) -> String {
        pack == .classic ? "" : "_\(pack.rawValue)"
    }

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

    private func store(players: [String: [AVAudioPlayer]]) {
        self.pools = players
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
    // Loads every present `<event>.caf` plus optional per-pack `<event>_soft`
    // / `<event>_crisp` variants. Absent files are skipped silently — play()
    // resolves a sensible fallback at call time. The single hard requirement
    // is at least one base sound; everything else is incremental.
    nonisolated private static func buildPlayers() -> [String: [AVAudioPlayer]] {
        var result: [String: [AVAudioPlayer]] = [:]
        for sound in Sound.allCases {
            for pack in SoundPack.allCases {
                let key = sound.rawValue + suffix(for: pack)
                guard let url = Bundle.main.url(forResource: key, withExtension: "caf") else {
                    continue
                }
                var pool: [AVAudioPlayer] = []
                for _ in 0..<poolSize {
                    if let player = try? AVAudioPlayer(contentsOf: url) {
                        player.enableRate = true   // base samples reshape via rate/pitch
                        player.prepareToPlay()
                        pool.append(player)
                    }
                }
                if !pool.isEmpty { result[key] = pool }
            }
        }
        return result
    }

    // MARK: — Public API

    /// Play a sound effect.
    /// Resolution order (first hit wins):
    ///   1. Pack-specific sample `<event>_<pack>.caf` → played at native rate.
    ///   2. Base sample `<event>.caf` → reshaped by the active pack (volume/rate).
    ///   3. Fallback event's base sample (reward→solve, combo→snap …), reshaped.
    /// No-op when `sfxEnabled` is false or nothing resolves.
    func play(_ sound: Sound) {
        guard sfxEnabled else { return }
        let pack = SoundPack.active

        // 1. Dedicated per-pack sample — honor it as-authored.
        let packKey = sound.rawValue + Self.suffix(for: pack)
        if pack != .classic, pools[packKey] != nil {
            firePool(packKey, volume: 1.0, rate: 1.0)
            return
        }
        // 2. Base sample for this event — reshape into the pack's feel.
        if pools[sound.rawValue] != nil {
            firePool(sound.rawValue, volume: pack.volume, rate: pack.rate)
            return
        }
        // 3. Graceful fallback to a mapped base event (also reshaped).
        if let fb = sound.fallback {
            let fbPackKey = fb.rawValue + Self.suffix(for: pack)
            if pack != .classic, pools[fbPackKey] != nil {
                firePool(fbPackKey, volume: 1.0, rate: 1.0)
                return
            }
            if pools[fb.rawValue] != nil {
                firePool(fb.rawValue, volume: pack.volume, rate: pack.rate)
            }
        }
    }

    /// Round-robin across the key's pool so overlapping/rapid triggers each get a
    /// fresh player and finish their sample without cutting one another off.
    private func firePool(_ key: String, volume: Float, rate: Float) {
        guard let pool = pools[key], !pool.isEmpty else { return }
        let idx = (nextIndex[key] ?? 0) % pool.count
        nextIndex[key] = idx + 1
        let player = pool[idx]
        player.volume = volume * sfxVolume
        player.rate = rate
        player.currentTime = 0
        player.play()
    }

    /// User-controlled SFX level (0…1), multiplied onto every effect. Default 1.
    private var sfxVolume: Float {
        Float(UserDefaults.standard.object(forKey: "sfxVolume") as? Double ?? 1.0)
    }

    // MARK: — Private helpers

    private var sfxEnabled: Bool {
        // Default true if key never set.
        UserDefaults.standard.object(forKey: "sfxEnabled") as? Bool ?? true
    }
}
