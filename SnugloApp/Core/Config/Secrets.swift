import Foundation

// MARK: — Secrets
// Public, client-side keys (safe to ship). The RevenueCat *public* SDK key is
// designed to live in the app binary. Replace the placeholder with the real key
// from the RevenueCat dashboard (Project → API keys → Public app-specific key,
// starts with `appl_`). While it stays the placeholder, RevenueCat is not
// configured and the app falls back to the StoreKit/premium-flag path.

enum Secrets {
    static let revenueCatPublicKey = "appl_REPLACE_WITH_REAL_KEY"

    /// True once a real RevenueCat key has been set.
    static var revenueCatConfigured: Bool {
        !revenueCatPublicKey.isEmpty && !revenueCatPublicKey.hasSuffix("REPLACE_WITH_REAL_KEY")
    }
}
