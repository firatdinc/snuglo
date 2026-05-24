import SwiftUI

// MARK: — Nordic Hearth Design System: Typography
// Source: Designs/INDEX.md (imported 2026-05-25)
//
// System-font fallbacks (custom fonts planned for Faz H):
//   Plus Jakarta Sans  → Font.system(design: .rounded,   weight: .semibold) — Headlines
//   Be Vietnam Pro     → Font.system(design: .default,   weight: .regular)  — Body / Labels
//   Space Grotesk      → Font.system(design: .monospaced, weight: .medium)  — Numeric
//
// Tracking (letter-spacing): SwiftUI .tracking() receives raw pt values.
//   Converted from em:  trackingPt = fontSize × emValue
//   −0.02em @ 28pt = −0.56 pt ≈ use .tracking(-0.6)
//    0.05em @ 12pt =  0.60 pt ≈ use .tracking(0.6) at call site for labelSmall
//
// Apply .textCase(.uppercase) at the call site for full labelSmall spec.

/// Nordic Hearth typography scale. Every Text view must reference these tokens.
enum AppTypography {

    // MARK: — Headlines (Plus Jakarta Sans → SF Rounded, semibold, −0.02em)

    /// 28 pt — main screen titles (GameView header, modal headlines)
    static let headlineLarge: Font  = .system(size: 28, weight: .semibold, design: .rounded)
    /// 22 pt — section headers, modal sub-titles
    static let headlineMedium: Font = .system(size: 22, weight: .semibold, design: .rounded)
    /// 18 pt — card titles, level names
    static let headlineSmall: Font  = .system(size: 18, weight: .semibold, design: .rounded)

    // MARK: — Body (Be Vietnam Pro → SF Pro, regular)

    /// 17 pt — primary reading content
    static let bodyLarge: Font  = .system(size: 17, weight: .regular)
    /// 15 pt — secondary content, descriptions
    static let bodyMedium: Font = .system(size: 15, weight: .regular)

    // MARK: — Numeric (Space Grotesk → SF Mono, medium)

    /// 20 pt — timers, scores, piece cell-count labels
    static let numericLabel: Font = .system(size: 20, weight: .medium, design: .monospaced)

    // MARK: — Label (Be Vietnam Pro → SF Pro, medium, UPPERCASE, +0.05em)

    /// 12 pt — uppercase badges, captions, level-ID line
    /// Call site must add: .tracking(0.6).textCase(.uppercase)
    static let labelSmall: Font = .system(size: 12, weight: .medium)

    // MARK: — Legacy aliases (Faz B → Faz C migration shim; remove in Faz C)


    @available(*, deprecated, renamed: "headlineLarge")
    static let title: Font = headlineLarge
    @available(*, deprecated, renamed: "headlineSmall")
    static let subtitle: Font = headlineSmall
    @available(*, deprecated, renamed: "bodyMedium")
    static let body: Font = bodyMedium
    @available(*, deprecated, renamed: "labelSmall")
    static let caption: Font = labelSmall
    @available(*, deprecated, renamed: "numericLabel")
    static let mono: Font = numericLabel
    @available(*, deprecated, renamed: "numericLabel")
    static let blockLabel: Font = numericLabel
}

// MARK: — Text helpers (tracking + body color baked in)
//
// Prefer these over raw `.font(AppTypography.xxx)` so that tracking and
// body foreground color are applied consistently at every call site.
// Return type is `Text` so callers can still chain `.foregroundStyle()`,
// `.multilineTextAlignment()`, etc.
//
// Tracking values (pt) derived from INDEX.md em specs:
//   headlineLarge  −0.02em @ 28 pt = −0.56 → −0.6
//   headlineMedium −0.02em @ 22 pt = −0.44 → −0.4
//   headlineSmall  −0.02em @ 18 pt = −0.36 → −0.3 (rounded down, avoids over-tightening)
//   labelSmall     +0.05em @ 12 pt = +0.60 → +0.6 (includes uppercase via textCase)

extension Text {

    // MARK: — Headline helpers
    // Return type is `some View` so SwiftUI can unambiguously resolve
    // overloads (.tracking / .textCase / .foregroundStyle all have both
    // Text and View variants; opaque return avoids compile-time ambiguity).
    // Callers can still chain any View modifier after these helpers.

    /// 28 pt · SF Rounded · semibold · tracking −0.6 pt
    func appHeadlineLarge() -> some View {
        self.font(AppTypography.headlineLarge).tracking(-0.6)
    }

    /// 22 pt · SF Rounded · semibold · tracking −0.4 pt
    func appHeadlineMedium() -> some View {
        self.font(AppTypography.headlineMedium).tracking(-0.4)
    }

    /// 18 pt · SF Rounded · semibold · tracking −0.3 pt
    func appHeadlineSmall() -> some View {
        self.font(AppTypography.headlineSmall).tracking(-0.3)
    }

    // MARK: — Label helper

    /// 12 pt · SF Pro · medium · tracking +0.6 pt · UPPERCASE
    func appLabelSmall() -> some View {
        self.font(AppTypography.labelSmall).tracking(0.6).textCase(.uppercase)
    }

    // MARK: — Body helpers (bodyText foreground baked in)

    /// 17 pt · SF Pro · regular · color `AppColors.bodyText` (#3A332D)
    func appBodyLarge() -> some View {
        self.font(AppTypography.bodyLarge).foregroundStyle(AppColors.bodyText)
    }

    /// 15 pt · SF Pro · regular · color `AppColors.bodyText` (#3A332D)
    func appBodyMedium() -> some View {
        self.font(AppTypography.bodyMedium).foregroundStyle(AppColors.bodyText)
    }
}
