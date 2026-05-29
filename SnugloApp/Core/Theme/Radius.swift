import CoreFoundation

// MARK: — Vibrant Play Design System: Corner Radii
// Source: Designs/VibrantPlay/SPEC.md
//   Primary cards / modals: ~20 px ("large rounded cards")
//   Buttons:               100 pt (pill-shaped — SPEC: "pill-shaped primary buttons")
//   Game blocks:            10 px

/// Corner-radius tokens for the Vibrant Play design system.
enum AppRadius {
    /// 20 pt — modals, scoreboards, large cards
    static let card: CGFloat   = 20
    /// 100 pt — pill buttons (SPEC: "pill-shaped primary buttons")
    static let button: CGFloat = 100
    /// 10 pt — game puzzle pieces / blocks
    static let block: CGFloat  = 10
}
