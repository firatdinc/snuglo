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
    // Levels (completed levels + packs)
    case firstSteps
    case levelHunter10
    case levelHunter25
    case levelMaster50
    case levelLegend100
    case levelVoyager250
    case levelSage500
    case completionist1000
    case packFinisher
    case packCollector3
    case packMaster10
    // Skill (perfect solves, win chains, no-hint, speed)
    case perfectionist1
    case perfectionistPro10
    case perfectionistMaster25
    case perfectionistGrand50
    case perfectionistLegend100
    case comboChampion
    case chainMaster10
    case chainLegend20
    case noHints10
    case noHints25
    case noHints50
    case speedSolver
    case speedDemon
    case speedLightning
    case speedBlitz
    // Streak (daily streak + play streak)
    case streak3
    case streak7
    case streak14
    case streak30
    case streak60
    case streak100
    case dedicated7
    case dedicated14
    case dedicated30

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
        case .levelHunter25:         return "25.circle.fill"
        case .levelMaster50:         return "rosette"
        case .levelLegend100:        return "crown.fill"
        case .levelVoyager250:       return "map.fill"
        case .levelSage500:          return "books.vertical.fill"
        case .completionist1000:     return "trophy.fill"
        case .packFinisher:          return "checkmark.seal.fill"
        case .packCollector3:        return "square.stack.3d.up.fill"
        case .packMaster10:          return "shippingbox.fill"
        case .perfectionist1:        return "star.circle.fill"
        case .perfectionistPro10:    return "sparkles"
        case .perfectionistMaster25: return "star.square.on.square.fill"
        case .perfectionistGrand50:  return "wand.and.stars"
        case .perfectionistLegend100: return "star.fill"
        case .comboChampion:         return "bolt.heart.fill"
        case .chainMaster10:         return "link.circle.fill"
        case .chainLegend20:         return "infinity.circle.fill"
        case .noHints10:             return "brain.fill"
        case .noHints25:             return "brain.head.profile"
        case .noHints50:             return "graduationcap.fill"
        case .speedSolver:           return "bolt.fill"
        case .speedDemon:            return "hare.fill"
        case .speedLightning:        return "bolt.badge.clock.fill"
        case .speedBlitz:            return "flame.circle.fill"
        case .streak3:               return "flame"
        case .streak7:               return "flame.fill"
        case .streak14:              return "calendar.badge.checkmark"
        case .streak30:              return "flame.fill"
        case .streak60:              return "calendar.circle.fill"
        case .streak100:             return "crown.fill"
        case .dedicated7:            return "calendar.badge.clock"
        case .dedicated14:           return "clock.badge.checkmark.fill"
        case .dedicated30:           return "heart.circle.fill"
        }
    }

    var reward: [Currency: Int] {
        switch self {
        case .firstSteps:             return [.coin: 50]
        case .levelHunter10:          return [.coin: 100]
        case .levelHunter25:          return [.coin: 200]
        case .levelMaster50:          return [.coin: 500, .cup: 1]
        case .levelLegend100:         return [.coin: 1000, .gem: 5, .cup: 1]
        case .levelVoyager250:        return [.coin: 1500, .gem: 5]
        case .levelSage500:           return [.coin: 2500, .gem: 10, .cup: 1]
        case .completionist1000:      return [.coin: 5000, .gem: 25, .cup: 1]
        case .packFinisher:           return [.coin: 300, .gem: 2]
        case .packCollector3:         return [.coin: 600, .gem: 3]
        case .packMaster10:           return [.coin: 1500, .gem: 8, .cup: 1]
        case .perfectionist1:         return [.coin: 50]
        case .perfectionistPro10:     return [.coin: 200, .gem: 1]
        case .perfectionistMaster25:  return [.coin: 600, .gem: 3]
        case .perfectionistGrand50:   return [.coin: 1200, .gem: 6]
        case .perfectionistLegend100: return [.coin: 2500, .gem: 12, .cup: 1]
        case .comboChampion:          return [.coin: 200, .gem: 1]
        case .chainMaster10:          return [.coin: 500, .gem: 3]
        case .chainLegend20:          return [.coin: 1000, .gem: 6]
        case .noHints10:              return [.gem: 1]
        case .noHints25:              return [.coin: 300, .gem: 2]
        case .noHints50:              return [.coin: 700, .gem: 5]
        case .speedSolver:            return [.coin: 100]
        case .speedDemon:             return [.coin: 250, .gem: 2]
        case .speedLightning:         return [.coin: 500, .gem: 3]
        case .speedBlitz:             return [.coin: 1000, .gem: 6]
        case .streak3:                return [.coin: 100]
        case .streak7:                return [.coin: 200, .gem: 2]
        case .streak14:               return [.coin: 350, .gem: 3]
        case .streak30:               return [.coin: 500, .gem: 5, .cup: 1]
        case .streak60:               return [.coin: 1000, .gem: 8]
        case .streak100:              return [.coin: 2000, .gem: 15, .cup: 1]
        case .dedicated7:             return [.coin: 250, .gem: 2]
        case .dedicated14:            return [.coin: 500, .gem: 4]
        case .dedicated30:            return [.coin: 1000, .gem: 8, .cup: 1]
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstSteps, .levelHunter10, .levelHunter25, .levelMaster50,
             .levelLegend100, .levelVoyager250, .levelSage500, .completionist1000,
             .packFinisher, .packCollector3, .packMaster10:
            return .levels
        case .perfectionist1, .perfectionistPro10, .perfectionistMaster25,
             .perfectionistGrand50, .perfectionistLegend100,
             .comboChampion, .chainMaster10, .chainLegend20,
             .noHints10, .noHints25, .noHints50,
             .speedSolver, .speedDemon, .speedLightning, .speedBlitz:
            return .skill
        case .streak3, .streak7, .streak14, .streak30, .streak60, .streak100,
             .dedicated7, .dedicated14, .dedicated30:
            return .streak
        }
    }
}
// swiftlint:enable inclusive_language
