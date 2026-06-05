import SwiftUI

// MARK: — AchievementCategory

enum AchievementCategory: String, CaseIterable {
    case levels, streak, skill

    var displayNameKey: LocalizedStringKey {
        // Build the key as a String first — interpolating inside
        // LocalizedStringKey("…\(x)…") turns x into a format arg and breaks lookup.
        let key = "achievement.category.\(rawValue)"
        return LocalizedStringKey(key)
    }
}

// MARK: — Achievement

// swiftlint:disable inclusive_language
enum Achievement: String, CaseIterable, Codable, Identifiable {
    case firstSteps
    case levelHunter10
    case levelMaster50
    case levelLegend100
    case packFinisher
    case perfectionist1
    case perfectionistPro10
    case perfectionistMaster25
    case streak3
    case streak7
    case streak30
    case dedicated7
    case comboChampion
    case noHints10
    case speedSolver
    case speedDemon

    var id: String { rawValue }

    /// App Store Connect achievement identifier — must match the ID configured in
    /// ASC. Reported to Game Center when the achievement unlocks.
    var gcID: String { "snuglo.achievement.\(rawValue)" }

    var displayNameKey: LocalizedStringKey {
        let key = "achievement.\(rawValue).title"
        return LocalizedStringKey(key)
    }

    var descriptionKey: LocalizedStringKey {
        let key = "achievement.\(rawValue).description"
        return LocalizedStringKey(key)
    }

    var sfSymbol: String {
        switch self {
        case .firstSteps:            return "flag.fill"
        case .levelHunter10:         return "10.circle.fill"
        case .levelMaster50:         return "rosette"
        case .levelLegend100:        return "crown.fill"
        case .packFinisher:          return "checkmark.seal.fill"
        case .perfectionist1:        return "star.circle.fill"
        case .perfectionistPro10:    return "sparkles"
        case .perfectionistMaster25: return "star.square.on.square.fill"
        case .streak3:               return "flame"
        case .streak7:               return "flame.fill"
        case .streak30:              return "flame.fill"
        case .dedicated7:            return "calendar.badge.clock"
        case .comboChampion:         return "bolt.heart.fill"
        case .noHints10:             return "brain.fill"
        case .speedSolver:           return "bolt.fill"
        case .speedDemon:            return "hare.fill"
        }
    }

    var reward: [Currency: Int] {
        switch self {
        case .firstSteps:            return [.coin: 50]
        case .levelHunter10:         return [.coin: 100]
        case .levelMaster50:         return [.coin: 500, .cup: 1]
        case .levelLegend100:        return [.coin: 1000, .gem: 5, .cup: 1]
        case .packFinisher:          return [.coin: 300, .gem: 2]
        case .perfectionist1:        return [.coin: 50]
        case .perfectionistPro10:    return [.coin: 200, .gem: 1]
        case .perfectionistMaster25: return [.coin: 600, .gem: 3]
        case .streak3:               return [.coin: 100]
        case .streak7:               return [.coin: 200, .gem: 2]
        case .streak30:              return [.coin: 500, .gem: 5, .cup: 1]
        case .dedicated7:            return [.coin: 250, .gem: 2]
        case .comboChampion:         return [.coin: 200, .gem: 1]
        case .noHints10:             return [.gem: 1]
        case .speedSolver:           return [.coin: 100]
        case .speedDemon:            return [.coin: 250, .gem: 2]
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstSteps, .levelHunter10, .levelMaster50, .levelLegend100, .packFinisher:
            return .levels
        case .perfectionist1, .perfectionistPro10, .perfectionistMaster25,
             .comboChampion, .noHints10, .speedSolver, .speedDemon:
            return .skill
        case .streak3, .streak7, .streak30, .dedicated7:
            return .streak
        }
    }
}
// swiftlint:enable inclusive_language
