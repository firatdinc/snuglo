import Foundation
import Observation

// MARK: — DailyCalendarStore
// A 30-day login-reward calendar — escalating daily rewards build a daily-open
// habit. Self-contained (own UserDefaults key). A missed day resets the cycle.

@Observable
final class DailyCalendarStore {

    static let shared = DailyCalendarStore()
    static let cycleLength = 30

    private(set) var claimedCycleDay: Int   // highest day claimed in this cycle (0 = none)
    private(set) var lastClaimedDayNumber: Int

    private let defaults: UserDefaults
    private let key = "snuglo.dailycal.v1"
    private struct P: Codable { var claimedCycleDay: Int; var lastClaimedDayNumber: Int }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let d = defaults.data(forKey: key), let p = try? JSONDecoder().decode(P.self, from: d) {
            claimedCycleDay = p.claimedCycleDay
            lastClaimedDayNumber = p.lastClaimedDayNumber
        } else {
            claimedCycleDay = 0
            lastClaimedDayNumber = -1
        }
    }

    var canClaim: Bool { lastClaimedDayNumber != DailyCalendarStore.currentDay() }

    /// The cycle-day that the player is on (the next claimable, or today's if claimed).
    var currentDayInCycle: Int {
        guard canClaim else { return max(1, claimedCycleDay) }
        if lastClaimedDayNumber == DailyCalendarStore.currentDay() - 1 {
            return (claimedCycleDay % DailyCalendarStore.cycleLength) + 1
        }
        return 1   // missed a day (or first ever) → cycle restarts
    }

    /// Escalating reward for a given cycle day (1…30).
    static func reward(forDay d: Int) -> (coins: Int, gems: Int) {
        let coins = 40 + d * 15
        let gems = d % 7 == 0 ? max(1, d / 7) : 0
        return (coins, gems)
    }

    @MainActor
    @discardableResult
    func claim(wallet: WalletStore = .shared) -> (day: Int, coins: Int, gems: Int)? {
        guard canClaim else { return nil }
        let day = currentDayInCycle
        let r = DailyCalendarStore.reward(forDay: day)
        wallet.earn(.coin, amount: r.coins)
        if r.gems > 0 { wallet.earn(.gem, amount: r.gems) }
        claimedCycleDay = day
        lastClaimedDayNumber = DailyCalendarStore.currentDay()
        persist()
        return (day, r.coins, r.gems)
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(P(claimedCycleDay: claimedCycleDay, lastClaimedDayNumber: lastClaimedDayNumber)) {
            defaults.set(d, forKey: key)
        }
    }

    private static func currentDay() -> Int { Int(Date().timeIntervalSince1970 / 86_400) }
}
