import Foundation

// MARK: — GameCenterScoreMapper
// Pure, side-effect-free mapping functions. No GameKit import — fully unit-testable.

struct GameCenterScoreMapper {

    /// Total completed levels score. Clamps negative inputs to 0.
    static func totalLevels(completedCount: Int) -> Int {
        max(0, completedCount)
    }

    /// Fastest solve time in milliseconds.
    /// Filters out zero/negative values; returns nil if no valid time exists.
    static func fastestSolveMs(fromBestTimes bestTimes: [TimeInterval]) -> Int? {
        let valid = bestTimes.filter { $0 > 0 }
        guard let minTime = valid.min() else { return nil }
        return Int(minTime * 1000)
    }

    /// Best streak score. Clamps negative inputs to 0.
    static func bestStreak(_ streak: Int) -> Int {
        max(0, streak)
    }
}
