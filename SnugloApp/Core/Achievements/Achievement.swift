import SwiftUI

// MARK: — AchievementCategory

enum AchievementCategory: String, CaseIterable {
    case levels, streak, skill

    var displayNameKey: LocalizedStringKey {
        LocalizedStringKey("achievement.category.\(rawValue)")
    }
}

// MARK: — Achievement

// swiftlint:disable inclusive_language
enum Achievement: String, CaseIterable, Codable, Identifiable {
    case firstSteps
    case levelHunter10
    case levelMaster50
    case perfectionist1
    case perfectionistPro10
    case streak3
    case streak7
    case streak30
    case noHints10
    case speedSolver

    var id: String { rawValue }

    var displayNameKey: LocalizedStringKey {
        LocalizedStringKey("achievement.\(rawValue).title")
    }

    var descriptionKey: LocalizedStringKey {
        LocalizedStringKey("achievement.\(rawValue).description")
    }

    var sfSymbol: String {
        switch self {
        case .firstSteps:         return "flag.fill"
        case .levelHunter10:      return "10.circle.fill"
        case .levelMaster50:      return "rosette"
        case .perfectionist1:     return "star.circle.fill"
        case .perfectionistPro10: return "sparkles"
        case .streak3:            return "flame"
        case .streak7:            return "flame.fill"
        case .streak30:           return "flame.fill"
        case .noHints10:          return "brain.fill"
        case .speedSolver:        return "bolt.fill"
        }
    }

    var reward: [Currency: Int] {
        switch self {
        case .firstSteps:         return [.coin: 50]
        case .levelHunter10:      return [.coin: 100]
        case .levelMaster50:      return [.coin: 500, .cup: 1]
        case .perfectionist1:     return [.coin: 50]
        case .perfectionistPro10: return [.coin: 200, .gem: 1]
        case .streak3:            return [.coin: 100]
        case .streak7:            return [.coin: 200, .gem: 2]
        case .streak30:           return [.coin: 500, .gem: 5, .cup: 1]
        case .noHints10:          return [.gem: 1]
        case .speedSolver:        return [.coin: 100]
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstSteps, .levelHunter10, .levelMaster50:
            return .levels
        case .perfectionist1, .perfectionistPro10, .noHints10, .speedSolver:
            return .skill
        case .streak3, .streak7, .streak30:
            return .streak
        }
    }
}
// swiftlint:enable inclusive_language
