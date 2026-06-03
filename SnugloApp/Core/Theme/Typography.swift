import SwiftUI

// MARK: — Vibrant Play Design System: Typography
// Source: Designs/VibrantPlay/SPEC.md
// Faz 1: Unified single-font strategy — Plus Jakarta Sans for all tokens.
//        (Previously: Be Vietnam Pro body, Space Grotesk numeric — both removed.)
//
// Plus Jakarta Sans [variable wght 200–800] — registered via UIAppFonts in Info.plist.
//
// Variable font weight axis:
//   'wght' tag = 0x77676874 = 2003265652
//   400 = Regular, 500 = Medium, 600 = SemiBold
//
// Tracking (letter-spacing): SwiftUI .tracking() receives raw pt values.
//   Converted from em:  trackingPt = fontSize × emValue
//   −0.02em @ 28pt = −0.56 pt → use .tracking(-0.6) at call site
//    0.05em @ 12pt =  0.60 pt → use .tracking(0.6) at call site for labelSmall
//
// Fallback: if a custom font cannot be loaded, UIFont returns the system font.

/// Vibrant Play typography scale. Every Text view must reference these tokens.
enum AppTypography {

    // MARK: — Headlines (Plus Jakarta Sans, semibold)

    /// 28 pt — main screen titles, modal headlines
    static let headlineLarge: Font  = plusJakartaSans(size: 28, weight: 600)
    /// 22 pt — section headers, modal sub-titles
    static let headlineMedium: Font = plusJakartaSans(size: 22, weight: 600)
    /// 18 pt — card titles, level names
    static let headlineSmall: Font  = plusJakartaSans(size: 18, weight: 600)

    // MARK: — Body (Plus Jakarta Sans, regular)

    /// 17 pt — primary reading content
    static let bodyLarge: Font  = plusJakartaSans(size: 17, weight: 400)
    /// 15 pt — secondary content, descriptions
    static let bodyMedium: Font = plusJakartaSans(size: 15, weight: 400)

    // MARK: — Numeric (SF Rounded, heavy — chunky "game" numbers for scores,
    //         currencies, timers; the brand font stays on text headings/body.)

    /// 28 pt — KPI card hero values, large statistics
    static let numericLarge: Font = .system(size: 28, weight: .heavy, design: .rounded)
    /// 20 pt — timers, scores, piece cell-count labels
    static let numericLabel: Font = .system(size: 20, weight: .bold, design: .rounded)
    /// 13 pt — small inline numeric values (pack donut counts, table values)
    static let numericSmall: Font = .system(size: 13, weight: .bold, design: .rounded)

    // MARK: — Label (Plus Jakarta Sans, medium, UPPERCASE, +0.05em)

    /// 12 pt — uppercase badges, captions, level-ID line
    /// Call site must add: .tracking(0.6).textCase(.uppercase)
    static let labelSmall: Font = plusJakartaSans(size: 12, weight: 500)

    // MARK: — Private font builder

    /// Plus Jakarta Sans variable font at a given weight axis value.
    /// Registered as PlusJakartaSans-Regular.ttf (variable wght 200–800).
    private static func plusJakartaSans(size: CGFloat, weight: CGFloat) -> Font {
        Font(variableFont(family: "Plus Jakarta Sans", size: size, wghtAxis: weight))
    }

    /// Creates a UIFont from a variable font family using the OpenType 'wght' axis.
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
