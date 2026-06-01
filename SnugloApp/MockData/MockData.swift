import SwiftUI

// MARK: — MockData
// Faz C scaffold — 4 packs × 60 levels each = 240 total.
// Replace with real persistence in Faz D/E.

struct Pack: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let gridSize: Int       // 5, 6, 7, 8
    let levelCount: Int     // 60
    let completedCount: Int
    let isLocked: Bool
    let accentColor: Color
    let iconName: String

    /// Alias for iconName — used by views that reference pack.iconSymbol.
    var iconSymbol: String { iconName }
    /// Alias for subtitle — displayed as a grid-size badge, e.g. "5×5 grid".
    var gridLabel: String { subtitle }
    /// Completed fraction 0.0–1.0 for progress bars.
    var progressFraction: CGFloat {
        levelCount > 0 ? CGFloat(completedCount) / CGFloat(levelCount) : 0
    }

    // MARK: — H-1 Localization keys (used by ShopView)

    /// Raw String key for NSLocalizedString calls (a11y labels).
    /// e.g. "pack.cozy_beginnings.title"
    var rawTitleKey: String {
        "pack.\(id.replacingOccurrences(of: "-", with: "_")).title"
    }
    /// LocalizedStringKey variant — used in SwiftUI Text(pack.titleKey).
    var titleKey: LocalizedStringKey { LocalizedStringKey(rawTitleKey) }
    /// Plain localized String — for nav titles, a11y labels, alert interpolation.
    var localizedTitle: String { NSLocalizedString(rawTitleKey, comment: "") }
    /// LocalizedStringKey for the grid-size badge, e.g. "pack.grid_label.5".
    var gridLabelKey: LocalizedStringKey {
        LocalizedStringKey("pack.grid_label.\(gridSize)")
    }
}

struct LevelItem: Identifiable, Hashable {
    let id: String
    let index: Int          // 1..60 in pack
    let isCompleted: Bool
    let isLocked: Bool
    let stars: Int          // 0..3

    /// Alias for index — used by views that reference level.number.
    var number: Int { index }
}

enum MockData {

    static let allPacks: [Pack] = [
        Pack(
            id: "cozy-beginnings",
            title: "Cozy Beginnings",
            subtitle: "5×5 grid",
            gridSize: 5,
            levelCount: 60,
            completedCount: 12,
            isLocked: false,
            accentColor: AppColors.blockLavender,
            iconName: "leaf.fill"
        ),
        Pack(
            id: "spice-route",
            title: "Spice Route",
            subtitle: "6×6 grid",
            gridSize: 6,
            levelCount: 60,
            completedCount: 4,
            isLocked: false,
            accentColor: AppColors.blockPeach,
            iconName: "cup.and.saucer.fill"
        ),
        Pack(
            id: "mambo-nights",
            title: "Mambo Nights",
            subtitle: "7×7 grid",
            gridSize: 7,
            levelCount: 60,
            completedCount: 0,
            isLocked: true,
            accentColor: AppColors.blockBlush,
            iconName: "moon.stars.fill"
        ),
        Pack(
            id: "woodland-retreat",
            title: "Woodland Retreat",
            subtitle: "8×8 grid",
            gridSize: 8,
            levelCount: 60,
            completedCount: 0,
            isLocked: true,
            accentColor: AppColors.blockSage,
            iconName: "tree.fill"
        )
    ]

    // MARK: — Continue helpers (used by MainMenuView)

    /// First unlocked pack that has at least one completed level.
    static var continuePack: Pack? {
        allPacks.first { !$0.isLocked && $0.completedCount > 0 }
    }

    /// The next unplayed level in continuePack.
    static var continueLevel: LevelItem? {
        guard let pack = continuePack else { return nil }
        let nextIndex = pack.completedCount + 1
        return LevelItem(
            id: "\(pack.id)-\(nextIndex)",
            index: nextIndex,
            isCompleted: false,
            isLocked: false,
            stars: 0
        )
    }

    static func levels(in packId: String) -> [LevelItem] {
        let completedUpTo: Int
        switch packId {
        case "cozy-beginnings": completedUpTo = 12
        case "spice-route":     completedUpTo = 4
        default:                completedUpTo = 0
        }
        return (1...60).map { i in
            let done   = i <= completedUpTo
            let locked = !done && i > completedUpTo + 1
            return LevelItem(
                id: "\(packId)-\(i)",
                index: i,
                isCompleted: done,
                isLocked: locked,
                stars: done ? [1, 2, 3][abs("\(packId)-\(i)".hashValue) % 3] : 0
            )
        }
    }
}
