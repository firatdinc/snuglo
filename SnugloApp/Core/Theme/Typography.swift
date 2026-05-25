import SwiftUI

// MARK: — Nordic Hearth Design System: Typography
// Source: Designs/INDEX.md (Stitch alignment v1.1)
//
// 3-font strategy (v1.1 — registered via UIAppFonts in Info.plist):
//   Plus Jakarta Sans  [variable wght 200–800] — Headlines
//   Be Vietnam Pro     [static Regular/Medium]  — Body / Labels
//   Space Grotesk      [variable wght 300–700]  — Numeric displays
//
// Variable font weight notes (UIFontDescriptor variation axis):
//   'wght' tag = 0x77676874 = 2003265652
//   Plus Jakarta Sans default = 400; use 600 for all headline tokens
//   Space Grotesk default = 300 (Light); use 500 for numericLabel
//
// Tracking (letter-spacing): SwiftUI .tracking() receives raw pt values.
//   Converted from em:  trackingPt = fontSize × emValue
//   −0.02em @ 28pt = −0.56 pt → use .tracking(-0.6) at call site
//    0.05em @ 12pt =  0.60 pt → use .tracking(0.6) at call site for labelSmall
//
// Fallback: if a custom font cannot be loaded (font file missing or not registered),
//   UIFont returns the system font rather than crashing.

/// Nordic Hearth typography scale. Every Text view must reference these tokens.
enum AppTypography {

    // MARK: — Headlines (Plus Jakarta Sans, semibold)

    /// 28 pt — main screen titles, modal headlines
    static let headlineLarge: Font  = plusJakartaSans(size: 28, weight: 600)
    /// 22 pt — section headers, modal sub-titles
    static let headlineMedium: Font = plusJakartaSans(size: 22, weight: 600)
    /// 18 pt — card titles, level names
    static let headlineSmall: Font  = plusJakartaSans(size: 18, weight: 600)

    // MARK: — Body (Be Vietnam Pro, regular)

    /// 17 pt — primary reading content
    static let bodyLarge: Font  = .custom("BeVietnamPro-Regular", size: 17)
    /// 15 pt — secondary content, descriptions
    static let bodyMedium: Font = .custom("BeVietnamPro-Regular", size: 15)

    // MARK: — Numeric (Space Grotesk, medium)

    /// 26 pt — KPI card hero values, large statistics
    static let numericLarge: Font = spaceGrotesk(size: 26, weight: 600)
    /// 20 pt — timers, scores, piece cell-count labels
    static let numericLabel: Font = spaceGrotesk(size: 20, weight: 500)
    /// 13 pt — small inline numeric values (pack donut counts, table values)
    static let numericSmall: Font = spaceGrotesk(size: 13, weight: 500)

    // MARK: — Label (Be Vietnam Pro, medium, UPPERCASE, +0.05em)

    /// 12 pt — uppercase badges, captions, level-ID line
    /// Call site must add: .tracking(0.6).textCase(.uppercase)
    static let labelSmall: Font = .custom("BeVietnamPro-Medium", size: 12)

    // MARK: — Private font builders

    /// Plus Jakarta Sans variable font at a given weight axis value.
    /// Registered as PlusJakartaSans-Regular.ttf (variable wght 200–800).
    private static func plusJakartaSans(size: CGFloat, weight: CGFloat) -> Font {
        Font(variableFont(family: "Plus Jakarta Sans", size: size, wghtAxis: weight))
    }

    /// Space Grotesk variable font at a given weight axis value.
    /// Registered as SpaceGrotesk-Regular.ttf (variable wght 300–700, default 300).
    /// Falls back to "Space Grotesk Light" PS name if family lookup misses.
    private static func spaceGrotesk(size: CGFloat, weight: CGFloat) -> Font {
        // Try the typographic family name (ID16). If the variable font isn't found,
        // UIFont falls back gracefully to the system font.
        let font = variableFont(family: "Space Grotesk", size: size, wghtAxis: weight)
        return Font(font)
    }

    /// Creates a UIFont from a variable font family using the OpenType 'wght' axis.
    /// - Parameter family: Typographic family name (ID1 or ID16 in the font's name table).
    /// - Parameter size: Point size.
    /// - Parameter wghtAxis: OpenType weight axis value (e.g. 400, 500, 600, 700).
    private static func variableFont(family: String, size: CGFloat, wghtAxis: CGFloat) -> UIFont {
        // 'wght' axis tag as Int: 0x77676874 = 2003265652
        let variationKey = UIFontDescriptor.AttributeName(rawValue: "NSCTFontVariationAttribute")
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            variationKey: [2003265652: wghtAxis]
        ])
        return UIFont(descriptor: descriptor, size: size)
    }
}
