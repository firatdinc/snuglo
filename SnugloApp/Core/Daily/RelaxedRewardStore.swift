import Foundation

// MARK: — RelaxedRewardStore
// Caps the XP & coin a player can earn from RELAXED modes (Zen + Endless) each
// day, and never grants gems there. Relaxed play is for calm — not farming
// currency/progression. Resets at local midnight. Self-contained UserDefaults key.

final class RelaxedRewardStore {

    static let shared = RelaxedRewardStore()

    /// Daily ceilings for relaxed play.
    static let maxXPPerDay   = 50
    static let maxCoinPerDay = 25

    private let defaults: UserDefaults
    private let key = "snuglo.relaxedReward.v1"
    private struct P: Codable { var day: String; var xp: Int; var coin: Int }

    private var day: String
    private var xpToday: Int
    private var coinToday: Int

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let d = defaults.data(forKey: key), let p = try? JSONDecoder().decode(P.self, from: d) {
            day = p.day; xpToday = max(0, p.xp); coinToday = max(0, p.coin)
        } else {
            day = ""; xpToday = 0; coinToday = 0
        }
    }

    private static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: Date())
    }

    private func rolloverIfNeeded() {
        let today = Self.todayKey()
        if day != today {
            day = today; xpToday = 0; coinToday = 0
        }
    }

    /// Grants relaxed XP/coin clamped to the remaining daily allowance. Returns
    /// the amounts actually granted (0…requested). Never grants gems.
    @discardableResult
    func grant(xp: Int = 10, coin: Int = 5) -> (xp: Int, coin: Int) {
        rolloverIfNeeded()
        let gx = max(0, min(xp, Self.maxXPPerDay   - xpToday))
        let gc = max(0, min(coin, Self.maxCoinPerDay - coinToday))
        xpToday += gx
        coinToday += gc
        persist()
        return (gx, gc)
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(P(day: day, xp: xpToday, coin: coinToday)) {
            defaults.set(d, forKey: key)
        }
    }
}
