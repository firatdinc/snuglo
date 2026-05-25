import Foundation
import SnugloEngine

// MARK: - PackProvider
//
// Engine (LevelGenerator) ile UI (Pack / LevelItem) arasındaki köprü.
//
// Faz D-2: Tüm level'lar deterministik olarak engine'den üretilir.
//           Progress (isCompleted / isLocked / stars) henüz statik;
//           Faz E'de AppStorage / CoreData'dan okunacak.

enum PackProvider {

    // MARK: - Generator

    static let generator = LevelGenerator()

    // MARK: - Pack API

    /// 4 pack'in tümünü döndürür.
    static func allPacks() -> [Pack] {
        MockData.allPacks
    }

    // MARK: - Level List API

    /// Belirli bir pack için 60 LevelItem döndürür.
    ///
    /// - Progress Faz E'de gerçek: isCompleted / isLocked / stars
    ///   şimdilik hepsi tamamlanmamış; sadece ilk level açık.
    static func levelItems(in packId: String) -> [LevelItem] {
        guard let pack = MockData.allPacks.first(where: { $0.id == packId }) else { return [] }
        return (1...pack.levelCount).map { i in
            LevelItem(
                id: "\(packId)-\(i)",
                index: i,
                isCompleted: false,
                isLocked: i > 1,   // Faz E: gerçek lock logic AppStorage'tan
                stars: 0
            )
        }
    }

    // MARK: - Level Load API

    /// packId + levelIndex (1-tabanlı) → engine Level üretir.
    static func loadLevel(packId: String, levelIndex: Int) -> Level {
        guard let pack = MockData.allPacks.first(where: { $0.id == packId }) else {
            // Bilinmeyen pack → minimal fallback
            return generator.generate(packId: packId, levelIndex: levelIndex, gridSize: 5)
        }
        return generator.generate(
            packId:     packId,
            levelIndex: levelIndex,
            gridSize:   pack.gridSize
        )
    }

    /// String id ("packId-index" formatı) ile level yükler.
    ///
    /// id format: "{packId}-{index}" — örn. "cozy-beginnings-12"
    /// Son "-" delimiter olarak kullanılır (packId'de "-" olabilir).
    static func loadLevel(id: String) -> Level? {
        guard let dashIdx = id.lastIndex(of: "-") else { return nil }
        let packId     = String(id[..<dashIdx])
        let indexStr   = String(id[id.index(after: dashIdx)...])
        guard let levelIndex = Int(indexStr) else { return nil }
        return loadLevel(packId: packId, levelIndex: levelIndex)
    }

    // MARK: - Daily Puzzle

    /// Bugünün daily puzzle Level'ını döndürür.
    static func dailyPuzzle() -> Level {
        DailyPuzzle.today()
    }
}
