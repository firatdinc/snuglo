import Foundation

// MARK: — AchievementRules
// Pure stateless evaluator — no side effects, no store references.

struct AchievementRules {
    static func isApplicable(_ achievement: Achievement, stats: AchievementStats) -> Bool {
        switch achievement {
        case .firstSteps:
            return stats.completedLevels >= 1
        case .levelHunter10:
            return stats.completedLevels >= 10
        case .levelMaster50:
            return stats.completedLevels >= 50
        case .perfectionist1:
            return stats.perfectSolves >= 1
        case .perfectionistPro10:
            return stats.perfectSolves >= 10
        case .streak3:
            return stats.currentStreak >= 3
        case .streak7:
            return stats.currentStreak >= 7
        case .streak30:
            return stats.currentStreak >= 30
        case .noHints10:
            return stats.hintFreeSolves >= 10
        case .speedSolver:
            return (stats.fastestSolveSeconds ?? Int.max) < 30
        }
    }
}
