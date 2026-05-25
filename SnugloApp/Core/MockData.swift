import SwiftUI

// MARK: — Pack

struct Pack: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    /// SF Symbol name for the pack icon tile.
    let iconSymbol: String
    /// Short grid descriptor shown as a badge, e.g. "5×5 grid".
    let gridLabel: String
    let accentColor: Color
    var completedCount: Int
    let levelCount: Int
    var isLocked: Bool
}

// MARK: — LevelItem

struct LevelItem: Identifiable {
    let id: String          // engine level id, e.g. "level_5x5"
    let index: Int          // 1-based display number within the pack
    let number: Int         // alias of index used in continue-card
    let packId: String
    var isLocked: Bool
    var isCompleted: Bool
    var stars: Int          // 0-3
}

// MARK: — MockData
// Static preview / development data. Replace with persistence in Faz E.

enum MockData {

    // MARK: — Packs

    static let allPacks: [Pack] = [
        Pack(
            id: "cozy",
            title: "Cozy Beginnings",
            subtitle: "The perfect place to start — gentle puzzles, warm vibes.",
            iconSymbol: "house.fill",
            gridLabel: "5×5 grid",
            accentColor: AppColors.blockLavender,
            completedCount: 12,
            levelCount: 60,
            isLocked: false
        ),
        Pack(
            id: "spice",
            title: "Spice Route",
            subtitle: "Turn up the heat with 6×6 challenges.",
            iconSymbol: "flame.fill",
            gridLabel: "6×6 grid",
            accentColor: AppColors.blockPeach,
            completedCount: 0,
            levelCount: 60,
            isLocked: true
        ),
        Pack(
            id: "nordic",
            title: "Nordic Hearth",
            subtitle: "Crisp, clean, and deceptively tricky 7×7 grids.",
            iconSymbol: "snowflake",
            gridLabel: "7×7 grid",
            accentColor: AppColors.blockSage,
            completedCount: 0,
            levelCount: 60,
            isLocked: true
        ),
        Pack(
            id: "arctic",
            title: "Arctic Dawn",
            subtitle: "The hardest 8×8 puzzles — for the truly dedicated.",
            iconSymbol: "mountain.2.fill",
            gridLabel: "8×8 grid",
            accentColor: AppColors.blockCream,
            completedCount: 0,
            levelCount: 60,
            isLocked: true
        ),
    ]

    // MARK: — Continue helpers

    /// The first unlocked pack with at least one completed level.
    static var continuePack: Pack? {
        allPacks.first { !$0.isLocked && $0.completedCount > 0 }
    }

    /// The next unplayed level in the continue pack.
    static var continueLevel: LevelItem? {
        guard let pack = continuePack else { return nil }
        let nextIndex = pack.completedCount + 1
        return LevelItem(
            id: "level_5x5",
            index: nextIndex,
            number: nextIndex,
            packId: pack.id,
            isLocked: false,
            isCompleted: false,
            stars: 0
        )
    }

    // MARK: — Level list for a pack

    /// Returns 60 mock LevelItems for the given packId.
    static func levels(in packId: String) -> [LevelItem] {
        guard let pack = allPacks.first(where: { $0.id == packId }) else { return [] }
        return (1...pack.levelCount).map { i in
            LevelItem(
                id: "level_\(packId)_\(i)",
                index: i,
                number: i,
                packId: packId,
                isLocked: i > pack.completedCount + 1,
                isCompleted: i <= pack.completedCount,
                stars: i <= pack.completedCount ? 3 : 0
            )
        }
    }
}
