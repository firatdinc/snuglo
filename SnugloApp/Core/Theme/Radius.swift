import CoreFoundation

// MARK: — Nordic Hearth Design System: Corner Radii
// Source: Designs/INDEX.md
//   Primary cards / modals / scoreboards: 20 px
//   Buttons ("softer than standard"):      14 px
//   Game blocks:                           10 px

/// Corner-radius tokens for the Nordic Hearth design system.
enum AppRadius {
    /// 20 pt — modals, scoreboards, large cards
    static let card: CGFloat   = 20
    /// 14 pt — buttons (softer than standard iOS)
    static let button: CGFloat = 14
    /// 10 pt — game puzzle pieces / blocks
    static let block: CGFloat  = 10
}
