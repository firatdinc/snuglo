import UIKit

// MARK: — ThemeApplier
// Applies the user's theme choice (0=System, 1=Light, 2=Dark) by forcing the
// app windows' `overrideUserInterfaceStyle`.
//
// Why not rely on SwiftUI's `.preferredColorScheme` alone?
//   The main UI lives inside a `.page`-styled TabView (UIPageViewController).
//   Runtime changes to `preferredColorScheme` do NOT reliably propagate into the
//   page controller's child view controllers, so dynamic `UIColor { trait in }`
//   tokens (AppColors) fail to re-resolve and screens keep the old theme.
//   Setting `overrideUserInterfaceStyle` on the window forces a real trait change
//   down the ENTIRE UIKit hierarchy — page children included — so every dynamic
//   color re-resolves instantly.

enum ThemeApplier {

    /// Maps the persisted `appTheme` raw value to a UIKit interface style.
    static func style(for raw: Int) -> UIUserInterfaceStyle {
        switch raw {
        case 1:  return .light
        case 2:  return .dark
        default: return .unspecified   // System — follow device setting
        }
    }

    /// Forces every connected window to the requested interface style.
    static func apply(_ raw: Int) {
        let style = style(for: raw)
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
