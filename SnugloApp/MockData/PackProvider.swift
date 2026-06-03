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
    /// completedCount ProgressStore.shared'dan gerçek sayı.
    /// isLocked → Faz G-1: StoreManager.shared.isPackUnlocked ile belirlenir.
    static func allPacks() -> [Pack] {
        let progress = ProgressStore.shared
        let sk       = StoreManager.shared
        return MockData.allPacks.map { pack in
            Pack(
                id: pack.id,
                title: pack.title,
                subtitle: pack.subtitle,
                gridSize: pack.gridSize,
                levelCount: pack.levelCount,
                completedCount: progress.packCompletionCount(pack.id),
                isLocked: !sk.isPackUnlocked(pack.id),
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
            packId: packId,
            levelIndex: levelIndex,
            gridSize: pack.gridSize
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

    /// Bugünün daily puzzle Level'ını döndürür (0-tabanlı index ile çok-bölümlü).
    static func dailyPuzzle(index: Int = 0) -> Level {
        DailyPuzzle.today(index: index)
    }

    /// Bir levelId'den ("daily" veya "daily-N") günlük bölüm index'ini çözer.
    static func dailyIndex(from levelId: String) -> Int {
        guard levelId.hasPrefix("daily") else { return 0 }
        return Int(levelId.split(separator: "-").last ?? "0") ?? 0
    }

    // MARK: - Continue helpers (v1.1 bug fix — read from ProgressStore, not MockData)

    /// First unlocked pack that has a "next playable" level.
    /// Falls back to the first unlocked pack if no progress yet.
    static func continuePack() -> Pack? {
        let packs = allPacks()
        // Prefer the pack the user has progress in.
        if let inProgress = packs.first(where: { !$0.isLocked && $0.completedCount > 0 && $0.completedCount < $0.levelCount }) {
            return inProgress
        }
        // Otherwise the first unlocked pack so Level 1 is always reachable.
        return packs.first { !$0.isLocked }
    }

    /// The next playable level in `continuePack()`. For a brand-new player
    /// this is Level 1 of the first unlocked pack.
    static func continueLevel() -> LevelItem? {
        guard let pack = continuePack() else { return nil }
        let nextIndex = pack.completedCount + 1
        guard nextIndex <= pack.levelCount else { return nil }
        return LevelItem(
            id: "\(pack.id)-\(nextIndex)",
            index: nextIndex,
            isCompleted: false,
            isLocked: false,
            stars: 0
        )
    }

    // MARK: - Next-level helper (v1.1 bug fix — LevelCompleteSheet "Next Level")

    /// Returns the levelId immediately after `currentId` in the same pack.
    /// Returns `nil` if `currentId` is malformed or this was the last level
    /// in the pack (caller should fall through to pack-complete UX).
    static func nextLevelId(after currentId: String) -> String? {
        guard let dashIdx = currentId.lastIndex(of: "-") else { return nil }
        let packId   = String(currentId[..<dashIdx])
        let indexStr = String(currentId[currentId.index(after: dashIdx)...])
        guard let index = Int(indexStr),
              let pack = MockData.allPacks.first(where: { $0.id == packId }),
              index + 1 <= pack.levelCount
        else { return nil }
        return "\(packId)-\(index + 1)"
    }
}
