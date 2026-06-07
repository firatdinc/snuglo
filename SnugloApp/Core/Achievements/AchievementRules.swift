import Foundation

// MARK: — AchievementRules
// Pure stateless evaluator — no side effects, no store references.

struct AchievementRules {

    /// Progress toward an achievement as (current, target) counts. Time-based
    /// achievements are binary (0/1). Used to draw a progress bar on locked cells.
    static func progress(_ achievement: Achievement, stats: AchievementStats) -> (current: Int, target: Int) {
        func clamp(_ v: Int, _ t: Int) -> (Int, Int) { (min(max(v, 0), t), t) }
        func faster(than s: Int) -> (Int, Int) { ((stats.fastestSolveSeconds ?? .max) < s ? 1 : 0, 1) }
        switch achievement {
        // Levels
        case .firstSteps:             return clamp(stats.completedLevels, 1)
        case .levelHunter10:          return clamp(stats.completedLevels, 10)
        case .levelHunter25:          return clamp(stats.completedLevels, 25)
        case .levelMaster50:          return clamp(stats.completedLevels, 50)
        case .levelLegend100:         return clamp(stats.completedLevels, 100)
        case .levelVoyager250:        return clamp(stats.completedLevels, 250)
        case .levelSage500:           return clamp(stats.completedLevels, 500)
        case .completionist1000:      return clamp(stats.completedLevels, 1000)
        case .packFinisher:           return clamp(stats.packsCompleted, 1)
        case .packCollector3:         return clamp(stats.packsCompleted, 3)
        case .packMaster10:           return clamp(stats.packsCompleted, 10)
        // Skill
        case .perfectionist1:         return clamp(stats.perfectSolves, 1)
        case .perfectionistPro10:     return clamp(stats.perfectSolves, 10)
        case .perfectionistMaster25:  return clamp(stats.perfectSolves, 25)
        case .perfectionistGrand50:   return clamp(stats.perfectSolves, 50)
        case .perfectionistLegend100: return clamp(stats.perfectSolves, 100)
        case .comboChampion:          return clamp(stats.bestWinChain, 5)
        case .chainMaster10:          return clamp(stats.bestWinChain, 10)
        case .chainLegend20:          return clamp(stats.bestWinChain, 20)
        case .noHints10:              return clamp(stats.hintFreeSolves, 10)
        case .noHints25:              return clamp(stats.hintFreeSolves, 25)
        case .noHints50:              return clamp(stats.hintFreeSolves, 50)
        case .speedSolver:            return faster(than: 30)
        case .speedDemon:             return faster(than: 15)
        case .speedLightning:         return faster(than: 10)
        case .speedBlitz:             return faster(than: 5)
        // Streak
        case .streak3:                return clamp(stats.currentStreak, 3)
        case .streak7:                return clamp(stats.currentStreak, 7)
        case .streak14:               return clamp(stats.currentStreak, 14)
        case .streak30:               return clamp(stats.currentStreak, 30)
        case .streak60:               return clamp(stats.currentStreak, 60)
        case .streak100:              return clamp(stats.currentStreak, 100)
        case .dedicated7:             return clamp(stats.longestPlayStreak, 7)
        case .dedicated14:            return clamp(stats.longestPlayStreak, 14)
        case .dedicated30:            return clamp(stats.longestPlayStreak, 30)
        }
    }

    static func isApplicable(_ achievement: Achievement, stats: AchievementStats) -> Bool {
        let p = progress(achievement, stats: stats)
        return p.current >= p.target
    }
}
