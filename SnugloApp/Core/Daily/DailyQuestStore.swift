import Foundation
import Observation

// MARK: — DailyQuestStore
// 3 rotating daily quests with progress + rewards. Retention staple (daily
// objectives raise return-rate). Self-contained: its own UserDefaults key, so it
// never touches ProgressStore's snapshot. Quests are deterministic from the day
// number and reset automatically at the day rollover.

struct DailyQuest: Identifiable {
    enum Kind { case solveLevels, solveUnder, noHintSolves, perfectSolve }
    let id: Int
    let kind: Kind
    let goal: Int
    let param: Int          // seconds threshold for `.solveUnder`
    let rewardCoins: Int
    let rewardGems: Int

    var icon: String {
        switch kind {
        case .solveLevels:  return "checkmark.circle.fill"
        case .solveUnder:   return "bolt.fill"
        case .noHintSolves: return "eye.slash.fill"
        case .perfectSolve: return "star.fill"
        }
    }
}

@Observable
final class DailyQuestStore {

    static let shared = DailyQuestStore()

    private(set) var day: Int
    private(set) var progress: [Int]
    private(set) var claimed: [Bool]

    private let defaults: UserDefaults
    private let key = "snuglo.dailyquests.v1"

    private struct Persisted: Codable { var day: Int; var progress: [Int]; var claimed: [Bool] }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let today = DailyQuestStore.currentDay()
        if let data = defaults.data(forKey: key),
           let p = try? JSONDecoder().decode(Persisted.self, from: data),
           p.day == today, p.progress.count == 3, p.claimed.count == 3 {
            day = p.day; progress = p.progress; claimed = p.claimed
        } else {
            day = today; progress = [0, 0, 0]; claimed = [false, false, false]
            persist()
        }
    }

    // MARK: - Today's quests

    var quests: [DailyQuest] { DailyQuestStore.generate(for: day) }

    static func generate(for day: Int) -> [DailyQuest] {
        // Quest 0: core "solve N levels" — goal varies across a 4-day cycle.
        let solveGoal = [3, 4, 5, 4][day % 4]
        // Quest 1: a timed solve — threshold varies.
        let underSecs = [45, 60, 75, 50][day % 4]
        // Quest 2: rotating skill challenge — no-hint OR perfect (3-star) solves.
        let skillKinds: [DailyQuest.Kind] = [.noHintSolves, .perfectSolve, .noHintSolves, .perfectSolve]
        let skillKind = skillKinds[day % 4]
        let skillGoal = [2, 2, 3, 3][day % 4]
        return [
            DailyQuest(id: 0, kind: .solveLevels, goal: solveGoal, param: 0, rewardCoins: 60, rewardGems: 0),
            DailyQuest(id: 1, kind: .solveUnder, goal: 1, param: underSecs, rewardCoins: 80, rewardGems: 0),
            DailyQuest(id: 2, kind: skillKind, goal: skillGoal, param: 0, rewardCoins: 0, rewardGems: 1)
        ]
    }

    // MARK: - Events

    /// Call on every level solve. Advances any matching, unclaimed quest.
    func recordSolve(seconds: Int, hintsUsed: Int, stars: Int = 3) {
        rolloverIfNeeded()
        let qs = quests
        for i in 0..<3 where !claimed[i] && progress[i] < qs[i].goal {
            switch qs[i].kind {
            case .solveLevels:  progress[i] += 1
            case .solveUnder:   if seconds <= qs[i].param { progress[i] += 1 }
            case .noHintSolves: if hintsUsed == 0 { progress[i] += 1 }
            case .perfectSolve: if stars >= 3 { progress[i] += 1 }
            }
            progress[i] = min(progress[i], qs[i].goal)
        }
        persist()
    }

    func isComplete(_ i: Int) -> Bool { progress[i] >= quests[i].goal }
    func canClaim(_ i: Int) -> Bool { isComplete(i) && !claimed[i] }

    /// Grants the reward for quest `i` once. Returns (coins, gems) granted, or nil.
    @discardableResult
    @MainActor
    func claim(_ i: Int, wallet: WalletStore = .shared) -> (coins: Int, gems: Int)? {
        rolloverIfNeeded()
        guard canClaim(i) else { return nil }
        let q = quests[i]
        if q.rewardCoins > 0 { wallet.earn(.coin, amount: q.rewardCoins) }
        if q.rewardGems > 0 { wallet.earn(.gem, amount: q.rewardGems) }
        claimed[i] = true
        persist()
        return (q.rewardCoins, q.rewardGems)
    }

    func refresh() { rolloverIfNeeded() }

    // MARK: - Private

    private func rolloverIfNeeded() {
        let today = DailyQuestStore.currentDay()
        guard today != day else { return }
        day = today; progress = [0, 0, 0]; claimed = [false, false, false]
        persist()
    }

    private func persist() {
        let p = Persisted(day: day, progress: progress, claimed: claimed)
        if let data = try? JSONEncoder().encode(p) { defaults.set(data, forKey: key) }
    }

    private static func currentDay() -> Int {
        Int(Date().timeIntervalSince1970 / 86_400)
    }
}
