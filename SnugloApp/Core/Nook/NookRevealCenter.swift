import SwiftUI
import Observation

// MARK: — NookRevealCenter
// Drives the milestone "surprise egg" — every 10th level cleared earns a Nook
// scene piece, and that moment is announced with a juicy reveal overlay (shown
// globally from RootView, like RewardCenter). The player still drags the piece
// into place in the Nook; this just makes earning it feel like a gift.

@Observable
@MainActor
final class NookRevealCenter {

    static let shared = NookRevealCenter()

    struct Reveal: Identifiable, Equatable {
        let id = UUID()
        let packId: String
        let pieceIndex: Int     // 0-based slot the new piece fills (levelIndex/10 - 1)
    }

    private(set) var pending: Reveal?

    /// Set when the player opens the Nook straight from a level-complete to place a
    /// freshly-earned piece. The Nook consumes it on the next placement to auto-return
    /// to the game, so the player isn't stranded on the Nook screen.
    var autoReturnOnPlace: Bool = false

    /// Announce a freshly-earned scene piece. Latest wins if one is already up
    /// (overlap is rare — milestones are 10 levels apart).
    func announce(packId: String, pieceIndex: Int) {
        pending = Reveal(packId: packId, pieceIndex: pieceIndex)
    }

    func dismiss() { pending = nil }
}
