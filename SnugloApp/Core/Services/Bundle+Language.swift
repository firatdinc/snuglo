import Foundation

// MARK: — Runtime language bundle swizzle
// SwiftUI's `Text(LocalizedStringKey)` and `NSLocalizedString` both resolve
// through `Bundle.main.localizedString(forKey:value:table:)`. The chosen `.lproj`
// is normally fixed at launch (AppleLanguages) — so `.environment(\.locale, …)`
// alone does NOT switch the string table for already-rendered views.
//
// We swizzle `Bundle.main`'s class to one that redirects lookups to the selected
// language bundle. Combined with a view rebuild (`.id` in RootView), every
// localized string re-resolves into the active language instantly — no restart.

private var languageBundleKey: UInt8 = 0

private final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &languageBundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        // No override → fall back to default resolution (follows the system).
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {

    /// Installs the LocalizedBundle class onto `Bundle.main` exactly once.
    private static let installSwizzle: Void = {
        object_setClass(Bundle.main, LocalizedBundle.self)
    }()

    /// Redirects `Bundle.main` lookups to `language`'s `.lproj`.
    /// Pass `"system"` / `nil` to follow the device language.
    static func setAppLanguage(_ language: String?) {
        _ = installSwizzle

        let override: Bundle?
        if let language, language != "system",
           let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            override = langBundle
        } else {
            override = nil
        }
        objc_setAssociatedObject(
            Bundle.main, &languageBundleKey, override, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
