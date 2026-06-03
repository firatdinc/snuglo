import Foundation
import Observation

// MARK: — WeeklyChallengeStore
// A week-long meta-goal (solve N levels this week) with an exclusive reward —
// pulls players back across multiple days. Deterministic from the week number;
// self-contained (own UserDefaults key); resets at the week rollover.

struct WeeklyChallenge {
    let goal: Int
    let rewardCoins: Int
    let rewardGems: Int
}

@Observable
final class WeeklyChallengeStore {

    static let shared = WeeklyChallengeStore()

    private(set) var week: Int
    private(set) var progress: Int
    private(set) var claimed: Bool

    private let defaults: UserDefaults
    private let key = "snuglo.weekly.v1"
    private struct P: Codable { var week: Int; var progress: Int; var claimed: Bool }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let now = WeeklyChallengeStore.currentWeek()
        if let d = defaults.data(forKey: key), let p = try? JSONDecoder().decode(P.self, from: d), p.week == now {
            week = p.week; progress = p.progress; claimed = p.claimed
        } else {
            week = now; progress = 0; claimed = false
            persist()
        }
    }

    var challenge: WeeklyChallenge { WeeklyChallengeStore.generate(week) }

    static func generate(_ week: Int) -> WeeklyChallenge {
        let goal = [15, 20, 25][week % 3]
        return WeeklyChallenge(goal: goal, rewardCoins: 300, rewardGems: 3)
    }

    var isComplete: Bool { progress >= challenge.goal }
    var canClaim: Bool { isComplete && !claimed }

    func recordSolve() {
        rolloverIfNeeded()
        guard !claimed, progress < challenge.goal else { return }
        progress = min(progress + 1, challenge.goal)
        persist()
    }

    @MainActor
    @discardableResult
    func claim(wallet: WalletStore = .shared) -> (coins: Int, gems: Int)? {
        rolloverIfNeeded()
        guard canClaim else { return nil }
        let c = challenge
        wallet.earn(.coin, amount: c.rewardCoins)
        if c.rewardGems > 0 { wallet.earn(.gem, amount: c.rewardGems) }
        claimed = true
        persist()
        return (c.rewardCoins, c.rewardGems)
    }

    func refresh() { rolloverIfNeeded() }

    private func rolloverIfNeeded() {
        let now = WeeklyChallengeStore.currentWeek()
        guard now != week else { return }
        week = now; progress = 0; claimed = false
        persist()
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(P(week: week, progress: progress, claimed: claimed)) {
            defaults.set(d, forKey: key)
        }
    }

    private static func currentWeek() -> Int { Int(Date().timeIntervalSince1970 / 604_800) }
}
