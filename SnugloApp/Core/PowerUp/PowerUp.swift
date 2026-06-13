import SwiftUI

// MARK: — PowerUp
// Faz 3: 3 active power-ups for the in-game power-up bar.
//
// DEFER (engine constraints):
//   • addTime  — Snuglo timer is ELAPSED (no countdown). Requires engine countdown
//                support. Scheduled for Faz 6+.
//   • swapPiece — Engine Piece.cells is immutable; rotation/flip semantics require
//                engine-side support. Scheduled for Faz 6+.

enum PowerUp: String, CaseIterable, Identifiable {
    case hint
    case undo
    case shuffleTray

    var id: Self { self }

    var gemCost: Int {
        switch self {
        case .hint:        return 30
        case .undo:        return 20
        case .shuffleTray: return 15
        }
    }

    var displayNameKey: LocalizedStringKey {
        switch self {
        case .hint:        return "powerup.hint"
        case .undo:        return "powerup.undo"
        case .shuffleTray: return "powerup.shuffle"
        }
    }

    var sfSymbol: String {
        switch self {
        case .hint:        return "lightbulb.fill"
        case .undo:        return "arrow.uturn.backward"
        // Named "Restart" in the UI — it pulls every placed piece off the board back
        // into the tray, so a reset glyph fits better than a shuffle glyph.
        case .shuffleTray: return "arrow.counterclockwise"
        }
    }
}

// MARK: — PowerUpResult

enum PowerUpResult: Equatable {
    case success
    case insufficientGem
    case notApplicable
}
