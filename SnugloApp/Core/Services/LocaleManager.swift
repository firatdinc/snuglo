import SwiftUI

// MARK: — LocaleManager
// Runtime, restart-free language switching.
//
// SwiftUI's `Text(LocalizedStringKey)` resolves its string lazily at render time
// using the environment's `\.locale`. By injecting this manager's `locale` at the
// root and changing it live, every localized Text re-resolves into the matching
// `.lproj` instantly — no app restart required.
//
// We also keep `AppleLanguages` in sync so NSLocalizedString-based lookups, the
// system language picker, and the NEXT cold launch all agree with the in-app
// choice. For immediate (same-session) NSLocalizedString-style lookups, use
// `localized(_:)`, which reads from the active language bundle directly.

@Observable
final class LocaleManager {

    static let shared = LocaleManager()

    /// Persisted override key — shared with SettingsView / launch-reset logic.
    private static let key = "snuglo.language.override"

    /// "system" | "en" | "tr" | "es"
    var languageCode: String {
        didSet {
            guard oldValue != languageCode else { return }
            UserDefaults.standard.set(languageCode, forKey: Self.key)
            applyAppleLanguages()
            Bundle.setAppLanguage(languageCode)   // redirect lookups immediately
        }
    }

    private init() {
        languageCode = UserDefaults.standard.string(forKey: Self.key) ?? "system"
        // Install the language bundle redirect for the persisted choice at launch.
        Bundle.setAppLanguage(languageCode)
    }

    /// Locale to inject into the SwiftUI environment.
    var locale: Locale {
        languageCode == "system" ? .autoupdatingCurrent : Locale(identifier: languageCode)
    }

    /// Bundle for the active language — used for NSLocalizedString-style lookups
    /// that must reflect the choice immediately (before next launch).
    private var bundle: Bundle {
        guard languageCode != "system",
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let langBundle = Bundle(path: path)
        else { return .main }
        return langBundle
    }

    /// Looks up `key` in the active language bundle.
    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private func applyAppleLanguages() {
        if languageCode == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        }
    }
}
