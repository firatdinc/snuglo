import SwiftUI

// MARK: — Nordic Hearth Design System: Colors
// Source: Designs/NordicHearth/SPEC.md
// Token NAMES are preserved — all call-sites compile unchanged.
//
// Palette values (light / dark):
//   surface #FDF8FB / #1B1A1D · primary #65587A / #C5B5DC
//   secondary (warm coffee) #675C58 / #D3C5BF
//   tertiary (khaki gold) #665F31 / #D0C68C
//   blocks: solgun Nordic pastels

/// Canonical color tokens for the Nordic Hearth design system.
enum AppColors {

    // MARK: — Background / Surface (tonal layering L0 → L4)

    /// Alias for background (L0)
    static let surface                  = Color(light: "#FDF8FB", dark: "#1B1A1D")
    /// L0 — page background
    static let background               = Color(light: "#FDF8FB", dark: "#1B1A1D")
    /// Pure white cards (light) / deepest surface (dark)
    static let surfaceContainerLowest   = Color(light: "#FFFFFF", dark: "#141316")
    /// L1 — lowest-elevation containers
    static let surfaceContainerLow      = Color(light: "#F8F2F5", dark: "#252428")
    /// L2 — standard containers
    static let surfaceContainer         = Color(light: "#F2ECF0", dark: "#2D2C30")
    /// L3 — elevated containers
    static let surfaceContainerHigh     = Color(light: "#ECE7EA", dark: "#363539")
    /// L4 — highest-elevation containers
    static let surfaceContainerHighest  = Color(light: "#E6E1E4", dark: "#414045")

    // MARK: — Primary (gri-mor)

    static let primary              = Color(light: "#65587A", dark: "#C5B5DC")
    static let primaryContainer     = Color(light: "#C5B5DC", dark: "#3F3654")
    static let onPrimary            = Color(light: "#FFFFFF", dark: "#1B0F2E")
    static let onPrimaryContainer   = Color(light: "#524566", dark: "#C5B5DC")
    /// Pressed / active state — slightly deeper primary
    static let primaryPressed       = Color(light: "#524566", dark: "#B0A0C7")

    // MARK: — Secondary (sıcak kahve)

    static let secondary                = Color(light: "#675C58", dark: "#D3C5BF")
    static let onSecondary              = Color(light: "#FFFFFF", dark: "#411E17")
    static let secondaryContainer       = Color(light: "#EBDDD7", dark: "#5D4037")
    static let onSecondaryContainer     = Color(light: "#6B605C", dark: "#D3C5BF")

    // MARK: — Tertiary (haki altın)

    static let tertiary                 = Color(light: "#665F31", dark: "#D0C68C")
    static let onTertiary               = Color(light: "#FFFFFF", dark: "#343100")
    static let tertiaryContainer        = Color(light: "#C6BD86", dark: "#4C4900")
    static let onTertiaryContainer      = Color(light: "#524C20", dark: "#D0C68C")

    // MARK: — Text / Content

    static let onSurface        = Color(light: "#1C1B1D", dark: "#E6E1E4")
    static let onSurfaceVariant = Color(light: "#49454D", dark: "#CBC4CE")

    // MARK: — Outline

    static let outline        = Color(light: "#7A757E", dark: "#8E8893")
    static let outlineVariant = Color(light: "#CBC4CE", dark: "#3D3B40")

    // MARK: — Error

    static let error          = Color(light: "#BA1A1A", dark: "#FFB4AB")
    static let onError        = Color(light: "#FFFFFF", dark: "#690005")
    static let errorContainer = Color(light: "#FFDAD6", dark: "#93000A")

    // MARK: — Surface Variant

    static let surfaceVariant = Color(light: "#E6E1E4", dark: "#414045")

    // MARK: — Block fills
    // Light mode uses clear, saturated mid-tones (not washed-out pastels) so the
    // pieces read crisply — closer in vividness to their dark-mode counterparts.

    static let blockLavender   = Color(light: "#B49BE0", dark: "#7A6D8C")
    static let blockSage       = Color(light: "#90C58C", dark: "#6F8A6B")
    static let blockPeach      = Color(light: "#F2A878", dark: "#A5826A")
    static let blockBlush      = Color(light: "#E59FAC", dark: "#9C7780")
    static let blockCream      = Color(light: "#EBC861", dark: "#9D9168")
    static let blockDustyOlive = Color(light: "#AEAA62", dark: "#7D7A5F")

    /// Index-stable palette — DO NOT reorder (deterministic piece coloring).
    static let blockPalette: [Color] = [
        blockLavender, blockSage, blockPeach,
        blockBlush, blockCream, blockDustyOlive
    ]

    // MARK: — Elevation / Shadow

    /// Warm ambient shadow derived from softCocoa base.
    static let shadowAmbient = Color(red: 58 / 255, green: 51 / 255, blue: 45 / 255)

    // MARK: — Semantic aliases

    static let invalidRed = error
    static let success    = primary
    /// Clear leaf-green used for positive/solved states (e.g. the daily "sun" badge).
    static let successGreen = Color(light: "#4FB05A", dark: "#5AA861")

    // MARK: — Game Board (Nordic Hearth warm parchment)

    /// Warm parchment game board
    static let gameBoardBackground = Color(light: "#F2EBE0", dark: "#2A2419")
    /// Grid lines — warm linen
    static let gridLine            = Color(light: "#E5DCC8", dark: "#3A3228")
    /// Blush tint for success accents
    static let blushAccent         = Color(light: "#F5E6E0", dark: "#3D2E28")
    /// Row divider / secondary-button border
    static let divider             = Color(light: "#EDE6DA", dark: "#2E2923")
    /// Primary text for secondary button labels
    static let softCocoa           = Color(light: "#3A332D", dark: "#D5CFC8")

    // MARK: — GridView aliases

    /// Alias: game board background
    static let gridBackground = gameBoardBackground
    /// Alias: grid lines
    static let gridLines      = gridLine

    // MARK: — Helpers

    /// Deterministic, index-stable block color for a piece, keyed by piece ID.
    /// Uses a polynomial hash (multiplier 31) — NOT String.hashValue which is
    /// randomised per-process since Swift 4.2 and would produce different colors
    /// each launch.
    static func blockColor(for pieceID: String) -> Color {
        var hash = 0
        for scalar in pieceID.unicodeScalars {
            hash = hash &* 31 &+ Int(scalar.value)
        }
        return blockPalette[abs(hash) % blockPalette.count]
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
