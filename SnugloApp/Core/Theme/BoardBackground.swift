import SwiftUI

// MARK: — BoardBackground
// Selectable cozy backdrops painted behind the puzzle grid. Strictly AppColors
// tokens (single-palette). Read live from UserDefaults so the board reflects the
// player's choice.

enum BoardBackground: String, CaseIterable, Identifiable {
    case parchment, dawn, forest, night, dusk, rose, meadow
    // ── Premium (gem-only) ──
    case twilight, ember

    var id: String { rawValue }
    var nameKey: String { "board.\(rawValue)" }

    /// Top → bottom gradient stops.
    var colors: [Color] {
        switch self {
        case .parchment: return [AppColors.surfaceContainerLowest, AppColors.surfaceContainerLowest]
        case .dawn:      return [AppColors.blushAccent, AppColors.surfaceContainerLowest]
        case .forest:    return [AppColors.blockSage.opacity(0.35), AppColors.surfaceContainerLowest]
        case .night:     return [AppColors.blockLavender.opacity(0.30), AppColors.surfaceContainer]
        case .dusk:      return [AppColors.blockLavender.opacity(0.22), AppColors.blockBlush.opacity(0.12)]
        case .rose:      return [AppColors.blockBlush.opacity(0.28), AppColors.surfaceContainerLowest]
        case .meadow:    return [AppColors.blockSage.opacity(0.25), AppColors.blushAccent]
        case .twilight:  return [AppColors.blockLavender.opacity(0.5), AppColors.blockBlush.opacity(0.25)]
        case .ember:     return [AppColors.blockPeach.opacity(0.5), AppColors.blockBlush.opacity(0.22)]
        }
    }

    /// Gem price for premium boards; `nil` = free (level/default boards).
    var gemCost: Int? {
        switch self {
        case .twilight, .ember: return 250
        default:                return nil
        }
    }

    static var active: BoardBackground {
        BoardBackground(rawValue: UserDefaults.standard.string(forKey: "boardBackground") ?? "parchment") ?? .parchment
    }
}
