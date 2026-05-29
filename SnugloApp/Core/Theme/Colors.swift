import SwiftUI

// MARK: — Vibrant Play Design System: Colors
// Source: Designs/VibrantPlay/SPEC.md
// Faz 1: Full token remap from Nordic Hearth → Vibrant Play.
//        Token NAMES are preserved — all call-sites compile unchanged.
//
// SPEC-defined values used directly:
//   background #f4faff · card #ffffff · primary #30A7E7 · pressed #2589C1
//   gold accent #FFB800 · text #141d21 · border #dbe4ea · errorContainer #ffdad6
//   primary tints #89ceff #c9e6ff · gold variants #D99C00 #ffdea8
//
// Inferred tokens (SPEC has no explicit value; nearest Vibrant Play equivalent used):
//   surfaceContainer* scale  — interpolated between #f4faff and #ffffff
//   tertiary                 — gold (#FFB800), same as SPEC secondary accent; used for stars
//   onSurface/Variant        — derived from SPEC text palette
//   outline/Variant          — derived from SPEC border palette
//   blockPalette             — SPEC: "colored block tiles"; vivid Material-inspired set
//   shadowAmbient            — SPEC: "soft shadows"; blue-tinted from SPEC #006591
//   gameBoardBackground      — very light blue consistent with background
//   blushAccent              — replaced Nordic Hearth blush with SPEC tint #c9e6ff

/// Canonical color tokens for the Vibrant Play design system.
enum AppColors {

    // MARK: — Background / Surface (tonal layering L0 → L4)
    // SPEC: background #f4faff · card/surface #ffffff

    /// Alias for background (L0)
    static let surface                  = Color(light: "#f4faff", dark: "#0d1824")
    /// L0 — page background, very light blue
    static let background               = Color(light: "#f4faff", dark: "#0d1824")
    /// Pure white cards (light) / deepest surface (dark)
    static let surfaceContainerLowest   = Color(light: "#ffffff", dark: "#101e2a")
    /// L1 — lowest-elevation containers (inferred: ramp from #f4faff toward #ffffff)
    static let surfaceContainerLow      = Color(light: "#f0f8ff", dark: "#152535")
    /// L2 — standard containers (inferred)
    static let surfaceContainer         = Color(light: "#e4f3fd", dark: "#1a2d40")
    /// L3 — elevated containers (SPEC tint #c9e6ff)
    static let surfaceContainerHigh     = Color(light: "#c9e6ff", dark: "#1f3550")
    /// L4 — highest-elevation containers (inferred)
    static let surfaceContainerHighest  = Color(light: "#b8d9f7", dark: "#24405f")

    // MARK: — Primary (Blue CTA)
    // SPEC: #30A7E7 · pressed #2589C1 · tints #89ceff #c9e6ff · darker #006591

    static let primary              = Color(light: "#30A7E7", dark: "#89ceff")
    static let primaryContainer     = Color(light: "#c9e6ff", dark: "#006591")
    static let onPrimary            = Color(light: "#ffffff", dark: "#003549")
    static let onPrimaryContainer   = Color(light: "#003549", dark: "#c9e6ff")
    /// Pressed / active state — SPEC: #2589C1
    static let primaryPressed       = Color(light: "#2589C1", dark: "#006591")

    // MARK: — Secondary / Accent (Gold)
    // SPEC: #FFB800 · variants #D99C00 #ffdea8

    static let secondary                = Color(light: "#D99C00", dark: "#FFB800")
    static let onSecondary              = Color(light: "#ffffff", dark: "#3a2a00")
    static let secondaryContainer       = Color(light: "#ffdea8", dark: "#4a3800")
    static let onSecondaryContainer     = Color(light: "#3a2a00", dark: "#ffdea8")

    // MARK: — Tertiary (Gold — inferred; SPEC has no tertiary; used for stars)
    // Inferred: maps to SPEC secondary/accent gold (#FFB800).

    static let tertiary                 = Color(light: "#FFB800", dark: "#ffdea8")
    static let onTertiary               = Color(light: "#ffffff", dark: "#3a2a00")
    static let tertiaryContainer        = Color(light: "#ffdea8", dark: "#4a3800")
    static let onTertiaryContainer      = Color(light: "#3a2a00", dark: "#ffdea8")

    // MARK: — Text / Content
    // SPEC: #141d21 near-black (NOT pure black)

    /// Near-black primary text — SPEC: #141d21
    static let onSurface        = Color(light: "#141d21", dark: "#e1ecf4")
    /// Muted secondary text (inferred from SPEC text range)
    static let onSurfaceVariant = Color(light: "#42575f", dark: "#9fb8c5")

    // MARK: — Outline
    // SPEC border/dim: #dbe4ea · #e0e9ef · #d2dbe1

    static let outline        = Color(light: "#587481", dark: "#7a9aaa")
    static let outlineVariant = Color(light: "#dbe4ea", dark: "#2d4454")

    // MARK: — Error
    // SPEC: errorContainer #ffdad6. Vivid error (#ba1a1a) preserved for game invalid
    // piece feedback — using ffdad6 as error would make invalid pieces nearly invisible.

    static let error          = Color(light: "#ba1a1a", dark: "#ffb4ab")
    static let onError        = Color(light: "#ffffff", dark: "#690005")
    static let errorContainer = Color(light: "#ffdad6", dark: "#93000a")

    // MARK: — Surface Variant

    static let surfaceVariant = Color(light: "#dbe4ea", dark: "#2d4454")

    // MARK: — Block fills (6 vivid — bright / kid-friendly; darker in dark mode)
    // Inferred: SPEC says "colored block tiles" without hex values.
    // Selected from Material Design 400 palette: vivid, distinguishable, well-spaced.

    static let blockLavender   = Color(light: "#9575CD", dark: "#6a4f9e")
    static let blockSage       = Color(light: "#26A69A", dark: "#1a7168")
    static let blockPeach      = Color(light: "#FF7043", dark: "#c24b27")
    static let blockBlush      = Color(light: "#EC407A", dark: "#a52d55")
    static let blockCream      = Color(light: "#FFA726", dark: "#c47400")
    static let blockDustyOlive = Color(light: "#66BB6A", dark: "#3a8a3e")

    /// Index-stable palette — DO NOT reorder (deterministic piece coloring).
    static let blockPalette: [Color] = [
        blockLavender, blockSage, blockPeach,
        blockBlush, blockCream, blockDustyOlive
    ]

    // MARK: — Elevation / Shadow
    // Inferred: SPEC says "soft shadows" without exact rgba.
    // Blue-tinted from SPEC darker primary #006591.

    /// Blue-tinted ambient shadow (derived from SPEC darker primary #006591).
    static let shadowAmbient = Color(red: 0 / 255, green: 101 / 255, blue: 145 / 255)

    // MARK: — Semantic aliases

    static let invalidRed = error
    static let success    = primary

    // MARK: — Game Board (Vibrant Play)

    /// Very light blue game board — consistent with #f4faff background
    static let gameBoardBackground = Color(light: "#edf6ff", dark: "#131e2b")
    /// Grid lines — SPEC border #dbe4ea
    static let gridLine            = Color(light: "#dbe4ea", dark: "#2d4454")
    /// Light-blue tint for success accents — SPEC tint #c9e6ff
    /// Inferred: replaces Nordic Hearth blushAccent (#F5E6E0).
    static let blushAccent         = Color(light: "#c9e6ff", dark: "#003a5c")
    /// Row divider / secondary-button border — SPEC border #dbe4ea
    static let divider             = Color(light: "#dbe4ea", dark: "#2d4454")
    /// Primary text for secondary button labels — SPEC #141d21
    /// Inferred: replaces Nordic Hearth softCocoa (#3A332D).
    static let softCocoa           = Color(light: "#141d21", dark: "#e1ecf4")

    // MARK: — GridView aliases

    /// Alias: game board background
    static let gridBackground = gameBoardBackground
    /// Alias: grid lines
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
