import Foundation

// MARK: — PowerUpRules
// Pure applicability rules — no SwiftUI, no store access.
// Callers pass integer counts so this is easy to unit-test in isolation.

struct PowerUpRules {

    /// Returns true when `pu` can be applied given the current game state.
    /// - Parameters:
    ///   - unplacedCount: Number of pieces not yet placed on the grid.
    ///   - moveHistoryCount: Number of successful placements recorded in history.
    ///   - misplacedCount: Pieces on the board sitting off their solution slot — a
    ///     hint can correct these even when nothing is left in the tray.
    ///   - placedCount: Pieces currently on the board — shuffle can pull these back
    ///     into the tray and reshuffle, so it stays useful after pieces are placed.
    static func isApplicable(
        _ pu: PowerUp,
        unplacedCount: Int,
        moveHistoryCount: Int,
        misplacedCount: Int = 0,
        placedCount: Int = 0
    ) -> Bool {
        switch pu {
        case .hint:
            return unplacedCount > 0 || misplacedCount > 0
        case .undo:
            return moveHistoryCount > 0
        case .shuffleTray:
            // Useful when there are ≥2 tray pieces to reorder, OR any placed piece
            // to return to the tray and reshuffle.
            return unplacedCount >= 2 || placedCount >= 1
        }
    }
}
