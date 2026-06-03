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

    // MARK: — Zen Mode tinting
    // Zen Mode shifts the app's MOOD tokens (surfaces, primary, text, board) to a
    // soft sage-green palette — warm, natural, restful — while keeping block fills,
    // error and the secondary/tertiary accents intact. Tokens below are computed
    // so every call-site picks up the sage variant with zero changes; RootView
    // includes `zenMode` in its rebuild id so the whole UI re-reads them on toggle.

    /// True when the player has enabled Zen Mode.
    private static var zenActive: Bool {
        UserDefaults.standard.bool(forKey: "zenMode")
    }

    /// Pick the Zen variant when Zen Mode is on, else the standard token.
    private static func tone(_ normal: Color, zen: Color) -> Color {
        zenActive ? zen : normal
    }

    // MARK: — Background / Surface (tonal layering L0 → L4)

    /// Alias for background (L0)
    static var surface: Color {
        tone(Color(light: "#FDF8FB", dark: "#1B1A1D"), zen: Color(light: "#EDF1E6", dark: "#161A13"))
    }
    /// L0 — page background
    static var background: Color {
        tone(Color(light: "#FDF8FB", dark: "#1B1A1D"), zen: Color(light: "#EDF1E6", dark: "#161A13"))
    }
    /// Pure white cards (light) / deepest surface (dark)
    static var surfaceContainerLowest: Color {
        tone(Color(light: "#FFFFFF", dark: "#141316"), zen: Color(light: "#F6F9F0", dark: "#10130D"))
    }
    /// L1 — lowest-elevation containers
    static var surfaceContainerLow: Color {
        tone(Color(light: "#F8F2F5", dark: "#252428"), zen: Color(light: "#E6ECDC", dark: "#1D2118"))
    }
    /// L2 — standard containers
    static var surfaceContainer: Color {
        tone(Color(light: "#F2ECF0", dark: "#2D2C30"), zen: Color(light: "#DFE6D3", dark: "#24291E"))
    }
    /// L3 — elevated containers
    static var surfaceContainerHigh: Color {
        tone(Color(light: "#ECE7EA", dark: "#363539"), zen: Color(light: "#D8E0CB", dark: "#2B3124"))
    }
    /// L4 — highest-elevation containers
    static var surfaceContainerHighest: Color {
        tone(Color(light: "#E6E1E4", dark: "#414045"), zen: Color(light: "#D1DAC2", dark: "#32382A"))
    }

    // MARK: — Primary (gri-mor → sage in Zen)

    static var primary: Color {
        tone(Color(light: "#65587A", dark: "#C5B5DC"), zen: Color(light: "#5C7A52", dark: "#A9C59D"))
    }
    static var primaryContainer: Color {
        tone(Color(light: "#C5B5DC", dark: "#3F3654"), zen: Color(light: "#C3D7B4", dark: "#3B4F32"))
    }
    static let onPrimary            = Color(light: "#FFFFFF", dark: "#1B0F2E")
    static var onPrimaryContainer: Color {
        tone(Color(light: "#524566", dark: "#C5B5DC"), zen: Color(light: "#3F5436", dark: "#C3D7B4"))
    }
    /// Pressed / active state — slightly deeper primary
    static var primaryPressed: Color {
        tone(Color(light: "#524566", dark: "#B0A0C7"), zen: Color(light: "#4C6743", dark: "#97B389"))
    }

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

    static var onSurface: Color {
        tone(Color(light: "#1C1B1D", dark: "#E6E1E4"), zen: Color(light: "#1A1F16", dark: "#E1E7DA"))
    }
    static var onSurfaceVariant: Color {
        tone(Color(light: "#49454D", dark: "#CBC4CE"), zen: Color(light: "#464F3D", dark: "#C5CDBB"))
    }

    // MARK: — Outline

    static var outline: Color {
        tone(Color(light: "#7A757E", dark: "#8E8893"), zen: Color(light: "#71785E", dark: "#8A917E"))
    }
    static var outlineVariant: Color {
        tone(Color(light: "#CBC4CE", dark: "#3D3B40"), zen: Color(light: "#C7CFB8", dark: "#3B4135"))
    }

    // MARK: — Error

    static let error          = Color(light: "#BA1A1A", dark: "#FFB4AB")
    static let onError        = Color(light: "#FFFFFF", dark: "#690005")
    static let errorContainer = Color(light: "#FFDAD6", dark: "#93000A")

    // MARK: — Surface Variant

    static var surfaceVariant: Color {
        tone(Color(light: "#E6E1E4", dark: "#414045"), zen: Color(light: "#D1DAC2", dark: "#32382A"))
    }

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

    // MARK: — Block Skins (unlockable cosmetics)
    // Each skin is a 6-colour palette (light/dark). Defined here in the palette
    // file — the one legitimate place for hex literals. Unlocked by player level.

    static let skinCandyPalette: [Color] = [
        Color(light: "#FF8FB1", dark: "#B56E84"),
        Color(light: "#7ED9C3", dark: "#5E9E8E"),
        Color(light: "#8FC1F2", dark: "#6B8FB5"),
        Color(light: "#F2D06B", dark: "#B59E55"),
        Color(light: "#C9A0F2", dark: "#9277B5"),
        Color(light: "#F2956B", dark: "#B5715A"),
    ]
    static let skinOceanPalette: [Color] = [
        Color(light: "#3FA7B5", dark: "#347E89"),
        Color(light: "#5EC2A8", dark: "#4A9080"),
        Color(light: "#6FA8DC", dark: "#567E9E"),
        Color(light: "#88D0C0", dark: "#5E9183"),
        Color(light: "#4E90A8", dark: "#3D6E80"),
        Color(light: "#9AD0C2", dark: "#6E948A"),
    ]
    static let skinMonoPalette: [Color] = [
        Color(light: "#8C8C8C", dark: "#9A9A9A"),
        Color(light: "#A6A29A", dark: "#8E8A82"),
        Color(light: "#7E8A88", dark: "#6E7A78"),
        Color(light: "#B0AAA0", dark: "#7C766C"),
        Color(light: "#94908A", dark: "#A4A09A"),
        Color(light: "#A8A29C", dark: "#827C76"),
    ]
    static let skinSunsetPalette: [Color] = [
        Color(light: "#FF9E6D", dark: "#B5734E"),
        Color(light: "#FFB38A", dark: "#B5805F"),
        Color(light: "#F2785C", dark: "#B05743"),
        Color(light: "#FFC56B", dark: "#B58E4E"),
        Color(light: "#E8956B", dark: "#A86D50"),
        Color(light: "#F4A6A0", dark: "#B07873"),
    ]
    static let skinAuroraPalette: [Color] = [
        Color(light: "#3FBFA8", dark: "#46A593"),
        Color(light: "#6E78E8", dark: "#5C63B0"),
        Color(light: "#9A7FE8", dark: "#7765B0"),
        Color(light: "#4FCB94", dark: "#50A583"),
        Color(light: "#4FB3D9", dark: "#4592A8"),
        Color(light: "#A48FE0", dark: "#8A7EB5"),
    ]

    struct BlockSkin: Identifiable {
        let id: String
        let nameKey: String
        let unlockLevel: Int
        let palette: [Color]
    }

    static let blockSkins: [BlockSkin] = [
        BlockSkin(id: "nordic", nameKey: "skin.nordic", unlockLevel: 1, palette: blockPalette),
        BlockSkin(id: "candy",  nameKey: "skin.candy",  unlockLevel: 3, palette: skinCandyPalette),
        BlockSkin(id: "ocean",  nameKey: "skin.ocean",  unlockLevel: 6, palette: skinOceanPalette),
        BlockSkin(id: "mono",   nameKey: "skin.mono",   unlockLevel: 9, palette: skinMonoPalette),
        BlockSkin(id: "sunset", nameKey: "skin.sunset", unlockLevel: 12, palette: skinSunsetPalette),
        BlockSkin(id: "aurora", nameKey: "skin.aurora", unlockLevel: 15, palette: skinAuroraPalette),
    ]

    /// The palette for the currently-selected skin (read live from UserDefaults).
    static func activeBlockPalette() -> [Color] {
        let id = UserDefaults.standard.string(forKey: "blockSkin") ?? "nordic"
        return (blockSkins.first { $0.id == id } ?? blockSkins[0]).palette
    }

    // MARK: — Elevation / Shadow

    /// Warm ambient shadow derived from softCocoa base.
    static let shadowAmbient = Color(red: 58 / 255, green: 51 / 255, blue: 45 / 255)

    // MARK: — Semantic aliases

    static let invalidRed = error
    static var success: Color { primary }
    /// Clear leaf-green used for positive/solved states (e.g. the daily "sun" badge).
    static let successGreen = Color(light: "#4FB05A", dark: "#5AA861")

    // MARK: — Game Board (Nordic Hearth warm parchment → soft sage in Zen)

    /// Warm parchment game board
    static var gameBoardBackground: Color {
        tone(Color(light: "#F2EBE0", dark: "#2A2419"), zen: Color(light: "#E7EEDD", dark: "#21271A"))
    }
    /// Grid lines — warm linen
    static var gridLine: Color {
        tone(Color(light: "#E5DCC8", dark: "#3A3228"), zen: Color(light: "#D6DEC6", dark: "#313829"))
    }
    /// Blush tint for success accents
    static var blushAccent: Color {
        tone(Color(light: "#F5E6E0", dark: "#3D2E28"), zen: Color(light: "#E4EDD9", dark: "#2B3324"))
    }
    /// Row divider / secondary-button border
    static var divider: Color {
        tone(Color(light: "#EDE6DA", dark: "#2E2923"), zen: Color(light: "#E2E8D6", dark: "#272D20"))
    }
    /// Primary text for secondary button labels
    static var softCocoa: Color {
        tone(Color(light: "#3A332D", dark: "#D5CFC8"), zen: Color(light: "#2F3528", dark: "#D2D8C8"))
    }

    // MARK: — GridView aliases

    /// Alias: game board background
    static var gridBackground: Color { gameBoardBackground }
    /// Alias: grid lines
    static var gridLines: Color { gridLine }

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
        let palette = activeBlockPalette()
        return palette[abs(hash) % palette.count]
    }

    /// Palette index for a piece — used to pick a distinct color-blind glyph so
    /// blocks are distinguishable without relying on hue.
    static func blockColorIndex(for pieceID: String) -> Int {
        var hash = 0
        for scalar in pieceID.unicodeScalars {
            hash = hash &* 31 &+ Int(scalar.value)
        }
        return abs(hash) % activeBlockPalette().count
    }

    /// One distinct glyph per palette index (6) for color-blind mode (unicode so
    /// it resolves as Text in a Canvas GraphicsContext).
    static let blockGlyphs = ["●", "■", "▲", "◆", "✦", "⬢"]
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
