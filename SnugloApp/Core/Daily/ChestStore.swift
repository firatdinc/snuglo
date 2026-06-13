import Foundation
import Observation

// MARK: — ChestStore
// Variable-ratio reward (loot chests) — the strongest dopamine/retention loop in
// casual games. A chest fills every N solves; opening it grants a RANDOM reward.
// Self-contained: its own UserDefaults key (no ProgressStore snapshot changes).

struct ChestReward: Identifiable {
    enum Tier { case common, rare, epic }
    let id = UUID()
    let coin: Int
    let gem: Int
    let tier: Tier
}

@Observable
final class ChestStore {

    static let shared = ChestStore()
    static let solvesPerChest = 5

    private(set) var progress: Int   // 0 ..< solvesPerChest
    private(set) var pending: Int    // chests ready to open

    private let defaults: UserDefaults
    private let key = "snuglo.chests.v1"
    // `keys` optional for back-compat decode (old saves had no keys field).
    private struct P: Codable { var progress: Int; var pending: Int; var keys: Int? }

    private(set) var keys: Int = 0   // keys owned — needed to OPEN a chest

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let d = defaults.data(forKey: key), let p = try? JSONDecoder().decode(P.self, from: d) {
            progress = max(0, min(p.progress, ChestStore.solvesPerChest))
            pending = max(0, p.pending)
            keys = max(0, p.keys ?? 0)
        } else {
            progress = 0; pending = 0; keys = 0
        }
    }

    var goal: Int { ChestStore.solvesPerChest }
    var hasChest: Bool { pending > 0 }
    /// Openable only when a chest is banked AND you hold a key.
    var canOpen: Bool { pending > 0 && keys > 0 }

    /// Call on every level solve — fills the chest meter, banking a chest at the cap.
    func recordSolve() {
        progress += 1
        if progress >= ChestStore.solvesPerChest {
            progress = 0
            pending += 1
        }
        persist()
    }

    /// Award keys (perfect solves, win-chains, pack completion, …).
    func addKey(_ n: Int = 1) {
        guard n > 0 else { return }
        keys += n
        persist()
    }

    /// Opens one pending chest by spending a key. Returns the reward for the reveal.
    @MainActor
    @discardableResult
    func open(wallet: WalletStore = .shared) -> ChestReward? {
        guard pending > 0, keys > 0 else { return nil }
        pending -= 1
        keys -= 1
        let reward = ChestStore.roll()
        if reward.coin > 0 { wallet.earn(.coin, amount: reward.coin) }
        if reward.gem > 0 { wallet.earn(.gem, amount: reward.gem) }
        persist()
        return reward
    }

    /// Weighted reward table — mostly coins, occasional gems, rare jackpot.
    static func roll() -> ChestReward {
        switch Int.random(in: 0..<100) {
        case 0..<55:  return ChestReward(coin: Int.random(in: 50...100), gem: 0, tier: .common)
        case 55..<80: return ChestReward(coin: Int.random(in: 120...200), gem: 0, tier: .rare)
        case 80..<92: return ChestReward(coin: 0, gem: Int.random(in: 1...2), tier: .epic)
        default:      return ChestReward(coin: 300, gem: 0, tier: .epic)
        }
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(P(progress: progress, pending: pending, keys: keys)) {
            defaults.set(d, forKey: key)
        }
    }
}
