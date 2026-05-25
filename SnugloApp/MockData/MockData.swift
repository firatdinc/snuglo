import SwiftUI

// MARK: — MockData
// Faz C placeholder data. Replace with LevelLoader-backed data in Faz D.
//
// Faz D plug-in point:
//   LevelLoader().loadAllPacks()  →  [Pack]
//   LevelLoader().loadLevels(packId: "cozy-beginnings")  →  [LevelItem]
//
// Currently MockData.allPacks and MockData.levels(for:) are the only call-sites.

// MARK: — Pack model

struct Pack: Identifiable {
    let id: String
    let title: String
    let subtitle: String        // e.g. "BEGINNER"
    let gridSize: Int           // e.g. 5 → 5×5
    let levelCount: Int         // e.g. 60
    let completedCount: Int
    let accentColor: Color
    let iconSymbol: String      // SF Symbol name
    let isLocked: Bool

    var progressFraction: Double {
        guard levelCount > 0 else { return 0 }
        return Double(completedCount) / Double(levelCount)
    }

    var gridLabel: String { "\(gridSize)×\(gridSize)" }
}

// MARK: — Level item model

struct LevelItem: Identifiable {
    let id: String
    let packId: String
    let number: Int             // 1-based display number
    let stars: Int              // 0 = not completed, 1-3 = star count
    let isLocked: Bool

    var isCompleted: Bool { !isLocked && stars > 0 }
    var isCurrent: Bool { !isLocked && stars == 0 }
}

// MARK: — Static mock data

enum MockData {

    // MARK: — Packs

    static let allPacks: [Pack] = [
        Pack(
            id: "cozy-beginnings",
            title: "Cozy Beginnings",
            subtitle: "BEGINNER",
            gridSize: 5,
            levelCount: 60,
            completedCount: 12,
            accentColor: AppColors.blockLavender,
            iconSymbol: "leaf.fill",
            isLocked: false
        ),
        Pack(
            id: "spice-route",
            title: "Spice Route",
            subtitle: "INTERMEDIATE",
            gridSize: 6,
            levelCount: 60,
            completedCount: 4,
            accentColor: AppColors.blockPeach,
            iconSymbol: "flame.fill",
            isLocked: false
        ),
        Pack(
            id: "mambo-nights",
            title: "Mambo Nights",
            subtitle: "ADVANCED",
            gridSize: 7,
            levelCount: 60,
            completedCount: 0,
            accentColor: AppColors.blockSage,
            iconSymbol: "music.note",
            isLocked: true
        ),
        Pack(
            id: "woodland-retreat",
            title: "Woodland Retreat",
            subtitle: "EXPERT",
            gridSize: 8,
            levelCount: 60,
            completedCount: 0,
            accentColor: AppColors.blockCream,
            iconSymbol: "tree.fill",
            isLocked: true
        )
    ]

    // MARK: — Level items per pack

    static func levels(for packId: String) -> [LevelItem] {
        guard let pack = allPacks.first(where: { $0.id == packId }) else { return [] }
        let completed = pack.completedCount

        return (1...pack.levelCount).map { number in
            if number <= completed {
                // Completed — assign random 1-3 stars deterministically
                let stars = (number % 3) == 0 ? 3 : (number % 3)
                return LevelItem(
                    id: "\(packId)-level-\(number)",
                    packId: packId,
                    number: number,
                    stars: stars,
                    isLocked: false
                )
            } else if number == completed + 1 {
                // Current active level
                return LevelItem(
                    id: "\(packId)-level-\(number)",
                    packId: packId,
                    number: number,
                    stars: 0,
                    isLocked: false
                )
            } else {
                // Locked
                return LevelItem(
                    id: "\(packId)-level-\(number)",
                    packId: packId,
                    number: number,
                    stars: 0,
                    isLocked: true
                )
            }
        }
    }

    // MARK: — Continue level (for MainMenu)

    static var continuePack: Pack? { allPacks.first(where: { !$0.isLocked && $0.completedCount > 0 }) }
    static var continueLevel: LevelItem? {
        guard let pack = continuePack else { return nil }
        return levels(for: pack.id).first(where: { $0.isCurrent })
    }

    // MARK: — Stats mock values (screen 09)

    static let statSolved    = 142
    static let statTimeHours = 48
    static let statFastest   = "1:12"
    static let statStreak    = 14

    // Weekly solves per day (M-S)
    static let weeklyBar: [(day: String, count: Int, isToday: Bool)] = [
        ("M", 3, false),
        ("T", 5, false),
        ("W", 2, false),
        ("T", 7, false),
        ("F", 4, false),
        ("S", 6, true),
        ("S", 0, false)
    ]
}
