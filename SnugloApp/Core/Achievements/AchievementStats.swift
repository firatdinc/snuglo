import Foundation

// MARK: — AchievementStats
// Pure value type — derived from ProgressStore at evaluation time.
// Passed to AchievementRules (no store references inside rules).

struct AchievementStats: Equatable {
    let completedLevels: Int
    /// Uses longestStreak so streak achievements survive breaking the active streak.
    let currentStreak: Int
    let perfectSolves: Int
    let hintFreeSolves: Int
    let fastestSolveSeconds: Int?
    /// Number of packs fully completed (every level solved).
    let packsCompleted: Int
    /// Longest play streak (any level on consecutive days).
    let longestPlayStreak: Int
    /// Best win-chain ever (consecutive solves without a fail/quit).
    let bestWinChain: Int
}

extension AchievementStats {
    init(from progress: ProgressStore) {
        completedLevels = progress.totalLevelsCompleted()
        currentStreak   = progress.longestStreak
        perfectSolves   = progress.levelProgress.values
            .filter { $0.isCompleted && $0.stars == 3 }.count
        hintFreeSolves  = progress.levelProgress.values
            .filter { $0.isCompleted && ($0.bestHintsUsed ?? Int.max) == 0 }.count
        let minTime     = progress.levelProgress.values
            .compactMap(\.bestTime).min()
        fastestSolveSeconds = minTime.map { Int($0) }
        packsCompleted = MockData.allPacks.filter {
            progress.packCompletionCount($0.id) >= $0.levelCount
        }.count
        longestPlayStreak = progress.longestPlayStreak
        bestWinChain      = progress.bestWinChain
    }
}
