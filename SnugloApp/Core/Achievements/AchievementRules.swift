import Foundation

// MARK: — AchievementRules
// Pure stateless evaluator — no side effects, no store references.

struct AchievementRules {

    /// Progress toward an achievement as (current, target) counts. Time-based
    /// achievements are binary (0/1). Used to draw a progress bar on locked cells.
    static func progress(_ achievement: Achievement, stats: AchievementStats) -> (current: Int, target: Int) {
        func clamp(_ v: Int, _ t: Int) -> (Int, Int) { (min(max(v, 0), t), t) }
        switch achievement {
        case .firstSteps:            return clamp(stats.completedLevels, 1)
        case .levelHunter10:         return clamp(stats.completedLevels, 10)
        case .levelMaster50:         return clamp(stats.completedLevels, 50)
        case .levelLegend100:        return clamp(stats.completedLevels, 100)
        case .packFinisher:          return clamp(stats.packsCompleted, 1)
        case .perfectionist1:        return clamp(stats.perfectSolves, 1)
        case .perfectionistPro10:    return clamp(stats.perfectSolves, 10)
        case .perfectionistMaster25: return clamp(stats.perfectSolves, 25)
        case .streak3:               return clamp(stats.currentStreak, 3)
        case .streak7:               return clamp(stats.currentStreak, 7)
        case .streak30:              return clamp(stats.currentStreak, 30)
        case .dedicated7:            return clamp(stats.longestPlayStreak, 7)
        case .comboChampion:         return clamp(stats.bestWinChain, 5)
        case .noHints10:             return clamp(stats.hintFreeSolves, 10)
        case .speedSolver:           return ((stats.fastestSolveSeconds ?? .max) < 30 ? 1 : 0, 1)
        case .speedDemon:            return ((stats.fastestSolveSeconds ?? .max) < 15 ? 1 : 0, 1)
        }
    }

    static func isApplicable(_ achievement: Achievement, stats: AchievementStats) -> Bool {
        switch achievement {
        case .firstSteps:
            return stats.completedLevels >= 1
        case .levelHunter10:
            return stats.completedLevels >= 10
        case .levelMaster50:
            return stats.completedLevels >= 50
        case .levelLegend100:
            return stats.completedLevels >= 100
        case .packFinisher:
            return stats.packsCompleted >= 1
        case .perfectionist1:
            return stats.perfectSolves >= 1
        case .perfectionistPro10:
            return stats.perfectSolves >= 10
        case .perfectionistMaster25:
            return stats.perfectSolves >= 25
        case .streak3:
            return stats.currentStreak >= 3
        case .streak7:
            return stats.currentStreak >= 7
        case .streak30:
            return stats.currentStreak >= 30
        case .dedicated7:
            return stats.longestPlayStreak >= 7
        case .comboChampion:
            return stats.bestWinChain >= 5
        case .noHints10:
            return stats.hintFreeSolves >= 10
        case .speedSolver:
            return (stats.fastestSolveSeconds ?? Int.max) < 30
        case .speedDemon:
            return (stats.fastestSolveSeconds ?? Int.max) < 15
        }
    }
}
