import CoreFoundation

// MARK: — Nordic Hearth Design System: Spacing
// Source: Designs/INDEX.md — 4 px baseline grid.
//   Screen margin: 24 px (lg)
//   Internal padding: 16 px (md)
//   Stack gaps: 8 / 16 / 32 (sm / md / xl)
//
// Note: Radius tokens moved to Radius.swift (AppRadius).

/// Spacing constants — 4 pt baseline unit.
enum AppSpacing {
    static let xs: CGFloat  =  4  // 1× — micro gaps, icon badges
    static let sm: CGFloat  =  8  // 2× — tight stacks, inner padding
    static let md: CGFloat  = 16  // 4× — internal padding, component stacks
    static let lg: CGFloat  = 24  // 6× — screen horizontal margin
    static let xl: CGFloat  = 32  // 8× — section vertical rhythm

    // Legacy alias — kept for Faz B→C migration; remove in Faz C
    @available(*, deprecated, renamed: "xl")
    static let xxl: CGFloat = xl
}
