import SwiftUI

// MARK: — Nordic Hearth Design System: Colors
// Source: Designs/INDEX.md (imported 2026-05-25)
// Faz C: Added missing tokens (surface, onPrimaryContainer, secondaryContainer, etc.)

/// Canonical color tokens for the Nordic Hearth design system.
enum AppColors {

    // MARK: — Background / Surface (tonal layering L0 → L4)

    /// Surface = warm off-white paper (alias for background)
    static let surface                  = Color(hex: "#FDF8FB")
    /// L0 — page background, warm off-white paper
    static let background               = Color(hex: "#FDF8FB")
    /// Pure white — lowest elevation surface
    static let surfaceContainerLowest   = Color(hex: "#FFFFFF")
    /// L1 — lowest-elevation containers
    static let surfaceContainerLow      = Color(hex: "#F8F2F5")
    /// L2 — standard containers (cards, tray)
    static let surfaceContainer         = Color(hex: "#F2ECF0")
    /// L3 — elevated containers
    static let surfaceContainerHigh     = Color(hex: "#ECE7EA")
    /// L4 — highest-elevation containers
    static let surfaceContainerHighest  = Color(hex: "#E6E1E4")

    // MARK: — Primary (Lavender / CTA)

    static let primary              = Color(hex: "#65587A")
    static let primaryContainer     = Color(hex: "#C5B5DC")
    static let onPrimary            = Color(hex: "#FFFFFF")
    static let onPrimaryContainer   = Color(hex: "#524566")

    // MARK: — Secondary (Cocoa)

    static let secondary                = Color(hex: "#675C58")
    static let onSecondary              = Color(hex: "#FFFFFF")
    static let secondaryContainer       = Color(hex: "#EBDDD7")
    static let onSecondaryContainer     = Color(hex: "#6B605C")

    // MARK: — Tertiary (Warm Olive)

    static let tertiary                 = Color(hex: "#665F31")
    static let onTertiary               = Color(hex: "#FFFFFF")
    static let tertiaryContainer        = Color(hex: "#C6BD86")
    static let onTertiaryContainer      = Color(hex: "#524C20")

    // MARK: — Text / Content

    /// Deep cocoa — primary text, NEVER pure black
    static let onSurface        = Color(hex: "#1C1B1D")
    /// Muted secondary text
    static let onSurfaceVariant = Color(hex: "#49454D")

    // MARK: — Outline

    static let outline        = Color(hex: "#7A757E")
    static let outlineVariant = Color(hex: "#CBC4CE")

    // MARK: — Error

    static let error          = Color(hex: "#BA1A1A")
    static let onError        = Color(hex: "#FFFFFF")
    static let errorContainer = Color(hex: "#FFDAD6")

    // MARK: — Surface Variant

    /// Surface with slight tint — same hex as surfaceContainerHighest
    static let surfaceVariant = Color(hex: "#E6E1E4")

    // MARK: — Block fills (6 pastels — Nordic Hearth palette)

    static let blockLavender   = Color(hex: "#C5B5DC") // = primaryContainer
    static let blockSage       = Color(hex: "#B5CDBA") // warm sage green
    static let blockPeach      = Color(hex: "#EDCDB8") // soft peach / apricot
    static let blockBlush      = Color(hex: "#E8BAC8") // rose blush
    static let blockCream      = Color(hex: "#E8DFC5") // warm cream
    static let blockDustyOlive = Color(hex: "#C5CAA8") // dusty olive

    /// Index-stable palette — DO NOT reorder (deterministic piece coloring).
    static let blockPalette: [Color] = [
        blockLavender, blockSage, blockPeach,
        blockBlush, blockCream, blockDustyOlive
    ]

    // MARK: — Elevation / Shadow

    /// Base tonal shadow color — rgba(58, 51, 45).
    static let shadowAmbient = Color(red: 58 / 255, green: 51 / 255, blue: 45 / 255)

    // MARK: — Semantic aliases

    static let invalidRed = error
    static let success    = primary

    // MARK: — GridView aliases

    static let gridBackground = surfaceContainerLow
    static let gridLines      = outlineVariant

    // MARK: — Helpers

    static func blockColor(for pieceID: String) -> Color {
        blockPalette[abs(pieceID.hashValue) % blockPalette.count]
    }
}

// MARK: — Private hex initializer

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
