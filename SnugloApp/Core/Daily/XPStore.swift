import Foundation
import Observation

// MARK: — XPStore
// Player XP & level — RPG-style meta-progression that sustains long-term play
// ("just reach the next level"). Self-contained: own UserDefaults key; level-ups
// grant coins via WalletStore and flag a celebration.

@Observable
final class XPStore {

    static let shared = XPStore()

    private(set) var totalXP: Int
    /// Set when a solve crosses into a new level — drives the level-up overlay.
    private(set) var pendingLevelUp: Int?
    private(set) var pendingLevelUpCoins: Int = 0

    private let defaults: UserDefaults
    private let key = "snuglo.xp.v1"
    private struct P: Codable { var totalXP: Int }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let d = defaults.data(forKey: key), let p = try? JSONDecoder().decode(P.self, from: d) {
            totalXP = max(0, p.totalXP)
        } else {
            totalXP = 0
        }
    }

    // MARK: - Curve

    /// XP needed to advance FROM level L to L+1. Gentle ramp: 100, 160, 220, …
    static func need(_ level: Int) -> Int { 100 + (level - 1) * 60 }

    static func levelInfo(totalXP: Int) -> (level: Int, into: Int, need: Int) {
        var level = 1
        var remaining = max(0, totalXP)
        while remaining >= need(level) {
            remaining -= need(level)
            level += 1
        }
        return (level, remaining, need(level))
    }

    var level: Int { XPStore.levelInfo(totalXP: totalXP).level }
    var xpIntoLevel: Int { XPStore.levelInfo(totalXP: totalXP).into }
    var xpForNext: Int { XPStore.levelInfo(totalXP: totalXP).need }
    var progress: Double {
        let n = xpForNext
        return n > 0 ? Double(xpIntoLevel) / Double(n) : 0
    }

    // MARK: - Events

    /// Awards XP for a solve. Grants coins on each level gained and flags a
    /// celebration. Returns the number of levels gained.
    @MainActor
    @discardableResult
    func award(_ xp: Int, wallet: WalletStore = .shared) -> Int {
        guard xp > 0 else { return 0 }
        let before = XPStore.levelInfo(totalXP: totalXP).level
        totalXP += xp
        let after = XPStore.levelInfo(totalXP: totalXP).level
        if after > before {
            let coins = (before + 1 ... after).reduce(0) { $0 + 40 + $1 * 10 }
            wallet.earn(.coin, amount: coins)
            pendingLevelUp = after
            pendingLevelUpCoins = coins
        }
        persist()
        return after - before
    }

    func consumeLevelUp() {
        pendingLevelUp = nil
        pendingLevelUpCoins = 0
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(P(totalXP: totalXP)) {
            defaults.set(d, forKey: key)
        }
    }
}
