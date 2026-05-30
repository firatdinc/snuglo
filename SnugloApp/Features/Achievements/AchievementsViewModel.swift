import Foundation
import Observation

// MARK: — AchievementsViewModel

@Observable
@MainActor
final class AchievementsViewModel {

    var selectedAchievement: Achievement?

    private let store: AchievementsStore
    private let progress: ProgressStore

    init(store: AchievementsStore = .shared, progress: ProgressStore = .shared) {
        self.store = store
        self.progress = progress
    }

    var stats: AchievementStats { AchievementStats(from: progress) }
    var overallProgress: Double { store.overallProgress() }
    var unlockedCount: Int { store.unlocked.count }
    var totalCount: Int { Achievement.allCases.count }

    func isUnlocked(_ achievement: Achievement) -> Bool {
        store.isUnlocked(achievement)
    }

    func achievements(for category: AchievementCategory) -> [Achievement] {
        Achievement.allCases.filter { $0.category == category }
    }
}
