import CoreFoundation

/// Spec §7 spacing — 4dp base unit.
enum AppSpacing {
    static let xs: CGFloat  =  4   // 1×
    static let sm: CGFloat  =  8   // 2×
    static let md: CGFloat  = 12   // 3×
    static let lg: CGFloat  = 16   // 4×
    static let xl: CGFloat  = 24   // 6×
    static let xxl: CGFloat = 32   // 8×

    // Radius tokens (spec §7)
    static let blockRadius: CGFloat  =  8
    static let buttonRadius: CGFloat = 12
    static let cardRadius: CGFloat   = 16
}
