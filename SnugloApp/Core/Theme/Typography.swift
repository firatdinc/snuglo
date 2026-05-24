import SwiftUI

/// Spec §7 typography scale — SF system fonts, no external dependencies.
enum AppTypography {
    /// Title 24 — SF Rounded semibold (emulated via .title2 + design)
    static let title: Font = .system(size: 24, weight: .semibold, design: .rounded)
    /// Subtitle 17 — SF Pro semibold
    static let subtitle: Font = .system(size: 17, weight: .semibold)
    /// Body 15 — SF Pro regular
    static let body: Font = .system(size: 15, weight: .regular)
    /// Caption 12 — SF Pro regular
    static let caption: Font = .system(size: 12, weight: .regular)
    /// Monospaced numbers (timer, block sizes) — SF Mono medium
    static let mono: Font = .system(size: 17, weight: .medium, design: .monospaced)
    /// Block label (number centered on block) — SF Rounded semibold
    static let blockLabel: Font = .system(size: 14, weight: .semibold, design: .rounded)
}
