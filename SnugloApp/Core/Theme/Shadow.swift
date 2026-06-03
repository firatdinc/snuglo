import SwiftUI

// MARK: — Vibrant Play Design System: Elevation Shadows
// Source: Designs/VibrantPlay/SPEC.md — "soft shadows"
//   L1 cards/board: blue-tinted rgba(0,101,145, 0.06) — ambient glow, 4 px y-offset, 12 px radius
//   L2 active:      blue-tinted rgba(0,101,145, 0.12) — picked-up block, 8 px y-offset, 16 px radius
//
// shadowAmbient = Color(red:0, green:101, blue:145) from SPEC darker primary #006591.
// Note: tonal/ambient, never harsh. Keep blur large, offset small.

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

    /// L3 — floating overlays / modals (reward popups, dialogs). Deep, soft lift.
    func shadowL3() -> some View {
        shadow(
            color: AppColors.shadowAmbient.opacity(0.22),
            radius: 30, x: 0, y: 14
        )
    }
}
