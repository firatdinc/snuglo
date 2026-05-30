import Foundation

// MARK: — PowerUpRules
// Pure applicability rules — no SwiftUI, no store access.
// Callers pass integer counts so this is easy to unit-test in isolation.

struct PowerUpRules {

    /// Returns true when `pu` can be applied given the current game state.
    /// - Parameters:
    ///   - unplacedCount: Number of pieces not yet placed on the grid.
    ///   - moveHistoryCount: Number of successful placements recorded in history.
    static func isApplicable(
        _ pu: PowerUp,
        unplacedCount: Int,
        moveHistoryCount: Int
    ) -> Bool {
        switch pu {
        case .hint:
            return unplacedCount > 0
        case .undo:
            return moveHistoryCount > 0
        case .shuffleTray:
            return unplacedCount >= 2
        }
    }
}
