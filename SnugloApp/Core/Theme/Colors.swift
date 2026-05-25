import SwiftUI

// MARK: — Nordic Hearth Design System: Colors
// Source: Designs/INDEX.md
// Faz C: Added missing tokens (surface, onPrimaryContainer, secondaryContainer, etc.)
// Faz H-2: Full dark-mode support via Color(light:dark:) → UIColor traitCollection bridge.
//           Every token now has a light + dark variant.
//           Block palette soft-shifted for dark backgrounds.

/// Canonical color tokens for the Nordic Hearth design system.
enum AppColors {

    // MARK: — Background / Surface (tonal layering L0 → L4)

    /// Alias for background (L0)
    static let surface                  = Color(light: "#FDF8FB", dark: "#1B1A1D")
    /// L0 — page background, warm off-white paper
    static let background               = Color(light: "#FDF8FB", dark: "#1B1A1D")
    /// Pure white (light) / deepest surface (dark)
    static let surfaceContainerLowest   = Color(light: "#FFFFFF", dark: "#141316")
    /// L1 — lowest-elevation containers
    static let surfaceContainerLow      = Color(light: "#F8F2F5", dark: "#252428")
    /// L2 — standard containers (cards, tray)
    static let surfaceContainer         = Color(light: "#F2ECF0", dark: "#2D2C30")
    /// L3 — elevated containers
    static let surfaceContainerHigh     = Color(light: "#ECE7EA", dark: "#363539")
    /// L4 — highest-elevation containers
    static let surfaceContainerHighest  = Color(light: "#E6E1E4", dark: "#414045")

    // MARK: — Primary (Lavender / CTA)

    static let primary              = Color(light: "#65587A", dark: "#C5B5DC")
    static let primaryContainer     = Color(light: "#C5B5DC", dark: "#3F3654")
    static let onPrimary            = Color(light: "#FFFFFF", dark: "#1B0F2E")
    static let onPrimaryContainer   = Color(light: "#524566", dark: "#C5B5DC")

    // MARK: — Secondary (Cocoa)

    static let secondary                = Color(light: "#675C58", dark: "#D3C5BF")
    static let onSecondary              = Color(light: "#FFFFFF", dark: "#411E17")
    static let secondaryContainer       = Color(light: "#EBDDD7", dark: "#5D4037")
    static let onSecondaryContainer     = Color(light: "#6B605C", dark: "#D3C5BF")

    // MARK: — Tertiary (Warm Olive)

    static let tertiary                 = Color(light: "#665F31", dark: "#D0C68C")
    static let onTertiary               = Color(light: "#FFFFFF", dark: "#343100")
    static let tertiaryContainer        = Color(light: "#C6BD86", dark: "#4C4900")
    static let onTertiaryContainer      = Color(light: "#524C20", dark: "#D0C68C")

    // MARK: — Text / Content

    /// Deep cocoa — primary text, NEVER pure black
    static let onSurface        = Color(light: "#1C1B1D", dark: "#E6E1E4")
    /// Muted secondary text
    static let onSurfaceVariant = Color(light: "#49454D", dark: "#CBC4CE")

    // MARK: — Outline

    static let outline        = Color(light: "#7A757E", dark: "#8E8893")
    static let outlineVariant = Color(light: "#CBC4CE", dark: "#3D3B40")

    // MARK: — Error

    static let error          = Color(light: "#BA1A1A", dark: "#FFB4AB")
    static let onError        = Color(light: "#FFFFFF", dark: "#690005")
    static let errorContainer = Color(light: "#FFDAD6", dark: "#93000A")

    // MARK: — Surface Variant (alias for surfaceContainerHighest)

    static let surfaceVariant = Color(light: "#E6E1E4", dark: "#414045")

    // MARK: — Block fills (6 pastels — soft in dark mode)

    static let blockLavender   = Color(light: "#D4C3E8", dark: "#7A6D8C")
    static let blockSage       = Color(light: "#C8D8C5", dark: "#6F8A6B")
    static let blockPeach      = Color(light: "#F2D0B7", dark: "#A5826A")
    static let blockBlush      = Color(light: "#E8C6CD", dark: "#9C7780")
    static let blockCream      = Color(light: "#F2E5C2", dark: "#9D9168")
    static let blockDustyOlive = Color(light: "#C8C49C", dark: "#7D7A5F")

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

    // MARK: — Game Board (Stitch Nordic Hearth — v1.1)

    /// Warm parchment board background — Stitch spec: #F2EBE0
    static let gameBoardBackground = Color(light: "#F2EBE0", dark: "#2A2419")
    /// Warm dividing grid lines — Stitch spec: #E5DCC8 @ 1.5 px
    static let gridLine            = Color(light: "#E5DCC8", dark: "#3A3228")
    /// Blush accent circle behind success illustration — Stitch spec: #F5E6E0
    static let blushAccent         = Color(light: "#F5E6E0", dark: "#3D2E28")
    /// Row divider / secondary-button border — Stitch spec: #EDE6DA
    static let divider             = Color(light: "#EDE6DA", dark: "#2E2923")
    /// Soft cocoa text — never pure black; used for secondary button labels — Stitch: #3A332D
    static let softCocoa           = Color(light: "#3A332D", dark: "#D5CFC8")

    // MARK: — GridView aliases (updated v1.1 → Stitch warm board colors)

    /// Alias: game board background (was surfaceContainerLow)
    static let gridBackground = gameBoardBackground
    /// Alias: grid lines (was outlineVariant)
    static let gridLines      = gridLine

    // MARK: — Helpers

    /// Deterministic, index-stable block color for a piece, keyed by piece ID.
    static func blockColor(for pieceID: String) -> Color {
        blockPalette[abs(pieceID.hashValue) % blockPalette.count]
    }
}

// MARK: — Light / Dark Color initializer (Faz H-2)

extension Color {
    /// Creates a color that automatically switches between light and dark variants
    /// based on the current UITraitCollection.userInterfaceStyle.
    init(light lightHex: String, dark darkHex: String) {
        self.init(uiColor: UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? darkHex : lightHex)
        })
    }
}

// MARK: — UIColor hex initializer

extension UIColor {
    convenience init(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >>  8) & 0xFF) / 255
        let b = CGFloat( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
