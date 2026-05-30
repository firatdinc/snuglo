import Foundation
import Observation

// MARK: — AchievementsStore
// Persists unlocked achievements in UserDefaults.
// evaluate() is idempotent: already-unlocked achievements are skipped on re-evaluation.

@Observable
@MainActor
final class AchievementsStore {

    static let shared = AchievementsStore()

    private(set) var unlocked: Set<Achievement> = []

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "snuglo.achievements.v1") {
        self.defaults = defaults
        self.key = key
        load()
    }

    // MARK: — Evaluation

    /// Unlocks any newly-applicable achievements, grants wallet rewards, and returns the new unlocks.
    /// Second and subsequent calls with the same or weaker stats are no-ops (idempotent).
    @discardableResult
    func evaluate(stats: AchievementStats, wallet: WalletStore = .shared) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        for achievement in Achievement.allCases {
            guard !unlocked.contains(achievement),
                  AchievementRules.isApplicable(achievement, stats: stats) else { continue }
            unlocked.insert(achievement)
            for (currency, amount) in achievement.reward {
                wallet.earn(currency, amount: amount)
            }
            newlyUnlocked.append(achievement)
        }
        if !newlyUnlocked.isEmpty { save() }
        return newlyUnlocked
    }

    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlocked.contains(achievement)
    }

    func overallProgress() -> Double {
        let total = Achievement.allCases.count
        guard total > 0 else { return 0 }
        return Double(unlocked.count) / Double(total)
    }

    // MARK: — Persistence

    private struct Snapshot: Codable {
        var unlocked: [Achievement]
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        unlocked = Set(snap.unlocked)
    }

    private func save() {
        let snap = Snapshot(unlocked: Array(unlocked))
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: — Reset

    func reset() {
        unlocked = []
        save()
    }
}
