import Foundation
import SnugloEngine

// MARK: - PackProvider
//
// Engine (LevelGenerator) ile UI (Pack / LevelItem) arasındaki köprü.
//
// Faz D-2: Tüm level'lar deterministik olarak engine'den üretilir.
// Faz E: Progress (isCompleted / isLocked / stars) ProgressStore'dan okunur.

enum PackProvider {

    // MARK: - Generator

    static let generator = LevelGenerator()

    // MARK: - Pack API

    /// 4 pack'in tümünü döndürür.
    /// completedCount Faz E'de ProgressStore.shared'dan gerçek sayı.
    static func allPacks() -> [Pack] {
        let store = ProgressStore.shared
        return MockData.allPacks.map { pack in
            Pack(
                id: pack.id,
                title: pack.title,
                subtitle: pack.subtitle,
                gridSize: pack.gridSize,
                levelCount: pack.levelCount,
                completedCount: store.packCompletionCount(pack.id),
                isLocked: pack.isLocked,
                accentColor: pack.accentColor,
                iconName: pack.iconName
            )
        }
    }

    // MARK: - Level List API

    /// Belirli bir pack için LevelItem listesi döndürür.
    ///
    /// Faz E: isCompleted / isLocked / stars ProgressStore.shared'dan okunur.
    /// Lock logic: level 1 her zaman açık; level N → N-1 tamamlanmış olmalı.
    static func levelItems(in packId: String) -> [LevelItem] {
        guard let pack = MockData.allPacks.first(where: { $0.id == packId }) else { return [] }
        let store = ProgressStore.shared
        return (1...pack.levelCount).map { i in
            let levelId = "\(packId)-\(i)"
            return LevelItem(
                id: levelId,
                index: i,
                isCompleted: store.isLevelCompleted(levelId),
                isLocked: !store.isLevelUnlocked(packId: packId, levelIndex: i),
                stars: store.levelProgress[levelId]?.stars ?? 0
            )
        }
    }

    // MARK: - Level Load API

    /// packId + levelIndex (1-tabanlı) → engine Level üretir.
    static func loadLevel(packId: String, levelIndex: Int) -> Level {
        guard let pack = MockData.allPacks.first(where: { $0.id == packId }) else {
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
        let packId   = String(id[..<dashIdx])
        let indexStr = String(id[id.index(after: dashIdx)...])
        guard let levelIndex = Int(indexStr) else { return nil }
        return loadLevel(packId: packId, levelIndex: levelIndex)
    }

    // MARK: - Daily Puzzle

    /// Bugünün daily puzzle Level'ını döndürür.
    static func dailyPuzzle() -> Level {
        DailyPuzzle.today()
    }
}
