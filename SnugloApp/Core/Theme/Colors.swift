import SwiftUI

// MARK: — Warm Cozy Design System: Colors
// Token NAMES are preserved — all call-sites compile unchanged.
//
// Direction: deepen "cozy" + add visual pop via WARMTH, not gloss.
// Cream backgrounds, terracotta primary, honey accent. The muted grey-purple
// of the old "Nordic Hearth" palette is gone; the warm character now carries
// the pop. Block fills stay (already warm pastels). Zen variants unchanged.
//
// Palette values (light / dark):
//   surface #FBF4EA / #1E1A15 · primary (terracotta) #E08A4F / #F4B183
//   secondary (clay rose) #A8675C / #E3B5AC
//   tertiary (honey gold) #C8901F / #F2C857
//   blocks: warm pastels (peach / sage / lavender / blush / honey / olive)

/// Canonical color tokens for the Warm Cozy design system.
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
        tone(Color(light: "#FBF4EA", dark: "#1E1A15"), zen: Color(light: "#EDF1E6", dark: "#161A13"))
    }
    /// L0 — page background
    static var background: Color {
        tone(Color(light: "#FBF4EA", dark: "#1E1A15"), zen: Color(light: "#EDF1E6", dark: "#161A13"))
    }
    /// Pure white cards (light) / deepest surface (dark)
    static var surfaceContainerLowest: Color {
        tone(Color(light: "#FFFDF9", dark: "#181410"), zen: Color(light: "#F6F9F0", dark: "#10130D"))
    }
    /// L1 — lowest-elevation containers
    static var surfaceContainerLow: Color {
        tone(Color(light: "#F6EEE0", dark: "#28231C"), zen: Color(light: "#E6ECDC", dark: "#1D2118"))
    }
    /// L2 — standard containers
    static var surfaceContainer: Color {
        tone(Color(light: "#F1E7D6", dark: "#322B22"), zen: Color(light: "#DFE6D3", dark: "#24291E"))
    }
    /// L3 — elevated containers
    static var surfaceContainerHigh: Color {
        tone(Color(light: "#EBE0CC", dark: "#3C3429"), zen: Color(light: "#D8E0CB", dark: "#2B3124"))
    }
    /// L4 — highest-elevation containers
    static var surfaceContainerHighest: Color {
        tone(Color(light: "#E4D8C2", dark: "#463C2F"), zen: Color(light: "#D1DAC2", dark: "#32382A"))
    }

    // MARK: — Primary (terracotta → sage in Zen)

    static var primary: Color {
        tone(Color(light: "#E08A4F", dark: "#F4B183"), zen: Color(light: "#5C7A52", dark: "#A9C59D"))
    }
    static var primaryContainer: Color {
        tone(Color(light: "#F6D9C2", dark: "#6B3D22"), zen: Color(light: "#C3D7B4", dark: "#3B4F32"))
    }
    static let onPrimary            = Color(light: "#FFFFFF", dark: "#3A1A08")
    static var onPrimaryContainer: Color {
        tone(Color(light: "#8A4A23", dark: "#F6D9C2"), zen: Color(light: "#3F5436", dark: "#C3D7B4"))
    }
    /// Pressed / active state — slightly deeper primary
    static var primaryPressed: Color {
        tone(Color(light: "#C66E3B", dark: "#E8995F"), zen: Color(light: "#4C6743", dark: "#97B389"))
    }

    // MARK: — Secondary (clay rose)

    static let secondary                = Color(light: "#A8675C", dark: "#E3B5AC")
    static let onSecondary              = Color(light: "#FFFFFF", dark: "#43180F")
    static let secondaryContainer       = Color(light: "#F5DDD5", dark: "#5E372E")
    static let onSecondaryContainer     = Color(light: "#804A40", dark: "#F5DDD5")

    // MARK: — Tertiary (honey gold — reward/accent pop)

    static let tertiary                 = Color(light: "#C8901F", dark: "#F2C857")
    static let onTertiary               = Color(light: "#FFFFFF", dark: "#3D2E00")
    static let tertiaryContainer        = Color(light: "#F8E3A8", dark: "#5A4715")
    static let onTertiaryContainer      = Color(light: "#6E5410", dark: "#F8E3A8")

    // MARK: — Text / Content (warm brown ink)

    static var onSurface: Color {
        tone(Color(light: "#2B2118", dark: "#EEE4D6"), zen: Color(light: "#1A1F16", dark: "#E1E7DA"))
    }
    static var onSurfaceVariant: Color {
        tone(Color(light: "#6B5D4D", dark: "#CFC2B0"), zen: Color(light: "#464F3D", dark: "#C5CDBB"))
    }

    // MARK: — Outline

    static var outline: Color {
        tone(Color(light: "#9C8A74", dark: "#978872"), zen: Color(light: "#71785E", dark: "#8A917E"))
    }
    static var outlineVariant: Color {
        tone(Color(light: "#DDCFBA", dark: "#463E32"), zen: Color(light: "#C7CFB8", dark: "#3B4135"))
    }

    // MARK: — Error

    static let error          = Color(light: "#BA1A1A", dark: "#FFB4AB")
    static let onError        = Color(light: "#FFFFFF", dark: "#690005")
    static let errorContainer = Color(light: "#FFDAD6", dark: "#93000A")

    // MARK: — Surface Variant

    static var surfaceVariant: Color {
        tone(Color(light: "#E4D8C2", dark: "#463C2F"), zen: Color(light: "#D1DAC2", dark: "#32382A"))
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
        Color(light: "#F2956B", dark: "#B5715A")
    ]
    static let skinOceanPalette: [Color] = [
        Color(light: "#3FA7B5", dark: "#347E89"),
        Color(light: "#5EC2A8", dark: "#4A9080"),
        Color(light: "#6FA8DC", dark: "#567E9E"),
        Color(light: "#88D0C0", dark: "#5E9183"),
        Color(light: "#4E90A8", dark: "#3D6E80"),
        Color(light: "#9AD0C2", dark: "#6E948A")
    ]
    static let skinMonoPalette: [Color] = [
        Color(light: "#8C8C8C", dark: "#9A9A9A"),
        Color(light: "#A6A29A", dark: "#8E8A82"),
        Color(light: "#7E8A88", dark: "#6E7A78"),
        Color(light: "#B0AAA0", dark: "#7C766C"),
        Color(light: "#94908A", dark: "#A4A09A"),
        Color(light: "#A8A29C", dark: "#827C76")
    ]
    static let skinSunsetPalette: [Color] = [
        Color(light: "#FF9E6D", dark: "#B5734E"),
        Color(light: "#FFB38A", dark: "#B5805F"),
        Color(light: "#F2785C", dark: "#B05743"),
        Color(light: "#FFC56B", dark: "#B58E4E"),
        Color(light: "#E8956B", dark: "#A86D50"),
        Color(light: "#F4A6A0", dark: "#B07873")
    ]
    static let skinAuroraPalette: [Color] = [
        Color(light: "#3FBFA8", dark: "#46A593"),
        Color(light: "#6E78E8", dark: "#5C63B0"),
        Color(light: "#9A7FE8", dark: "#7765B0"),
        Color(light: "#4FCB94", dark: "#50A583"),
        Color(light: "#4FB3D9", dark: "#4592A8"),
        Color(light: "#A48FE0", dark: "#8A7EB5")
    ]

    // Premium skins — NEVER unlocked by level; obtained only with gems / IAP, so
    // they create genuine demand for the hard currency. Richer, jewel/pastel sets.
    static let skinMidnightPalette: [Color] = [
        Color(light: "#3D5A80", dark: "#2C415C"),
        Color(light: "#5E548E", dark: "#463E6B"),
        Color(light: "#9B5DE5", dark: "#6E42A5"),
        Color(light: "#00BBF9", dark: "#0A86B0"),
        Color(light: "#3A86FF", dark: "#2C63BF"),
        Color(light: "#7B2CBF", dark: "#5A2090")
    ]
    static let skinBlossomPalette: [Color] = [
        Color(light: "#FFB3C6", dark: "#B57E8C"),
        Color(light: "#FFC8A2", dark: "#B58E73"),
        Color(light: "#E0BBE4", dark: "#9C84A0"),
        Color(light: "#FEC8D8", dark: "#B58D99"),
        Color(light: "#D4A5FF", dark: "#9477B5"),
        Color(light: "#FFDAC1", dark: "#B59C8A")
    ]

    struct BlockSkin: Identifiable {
        let id: String
        let nameKey: String
        let unlockLevel: Int
        let palette: [Color]
        /// Premium (gem-only) skins set this; they are never unlocked by level.
        var premiumCost: Int?
    }

    static let blockSkins: [BlockSkin] = [
        BlockSkin(id: "nordic", nameKey: "skin.nordic", unlockLevel: 1, palette: blockPalette),
        BlockSkin(id: "candy", nameKey: "skin.candy", unlockLevel: 3, palette: skinCandyPalette),
        BlockSkin(id: "ocean", nameKey: "skin.ocean", unlockLevel: 6, palette: skinOceanPalette),
        BlockSkin(id: "mono", nameKey: "skin.mono", unlockLevel: 9, palette: skinMonoPalette),
        BlockSkin(id: "sunset", nameKey: "skin.sunset", unlockLevel: 12, palette: skinSunsetPalette),
        BlockSkin(id: "aurora", nameKey: "skin.aurora", unlockLevel: 15, palette: skinAuroraPalette),
        // ── Premium (gem-only) ──
        BlockSkin(id: "midnight", nameKey: "skin.midnight", unlockLevel: .max, palette: skinMidnightPalette, premiumCost: 300),
        BlockSkin(id: "blossom", nameKey: "skin.blossom", unlockLevel: .max, palette: skinBlossomPalette, premiumCost: 400)
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

    // MARK: — Game Board (Warm Cozy parchment → soft sage in Zen)

    /// Warm parchment game board
    static var gameBoardBackground: Color {
        tone(Color(light: "#F3E8D6", dark: "#2C2519"), zen: Color(light: "#E7EEDD", dark: "#21271A"))
    }
    /// Grid lines — warm linen
    static var gridLine: Color {
        tone(Color(light: "#E6D6BC", dark: "#3C3225"), zen: Color(light: "#D6DEC6", dark: "#313829"))
    }
    /// Blush tint for success accents
    static var blushAccent: Color {
        tone(Color(light: "#F8E7DA", dark: "#3F2E24"), zen: Color(light: "#E4EDD9", dark: "#2B3324"))
    }
    /// Row divider / secondary-button border
    static var divider: Color {
        tone(Color(light: "#EFE4D2", dark: "#2F2920"), zen: Color(light: "#E2E8D6", dark: "#272D20"))
    }
    /// Primary text for secondary button labels
    static var softCocoa: Color {
        tone(Color(light: "#3A2E22", dark: "#D8CDBE"), zen: Color(light: "#2F3528", dark: "#D2D8C8"))
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
