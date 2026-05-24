import SwiftUI

// MARK: — Nordic Hearth Design System: Elevation Shadows
// Source: Designs/INDEX.md
//   L1 cards/board: rgba(58,51,45, 0.06)  — ambient glow, 4 px y-offset, 12 px radius
//   L2 active:      rgba(58,51,45, 0.12)  — picked-up block, 8 px y-offset, 16 px radius
//
// Note: these are tonal/ambient, never harsh. Keep blur large, offset small.

extension View {

    /// L1 — cards, board, idle pieces. Subtle ambient glow.
    func shadowL1() -> some View {
        shadow(
            color: AppColors.shadowAmbient.opacity(0.06),
            radius: 12, x: 0, y: 4
        )
    }

    /// L2 — picked-up / actively dragged block. Stronger ambient lift.
    func shadowL2() -> some View {
        shadow(
            color: AppColors.shadowAmbient.opacity(0.12),
            radius: 16, x: 0, y: 8
        )
    }
}
