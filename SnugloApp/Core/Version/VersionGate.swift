import Foundation
import Observation
import UIKit

// MARK: — VersionGate
// Remote version control. Fetches a small JSON config (GitHub gist raw) and
// compares the running app version against it:
//   • current < ios.minVersion    → .forced  (blocking update wall)
//   • current < ios.latestVersion → .soft    (dismissible "update available")
//   • otherwise                   → .upToDate
//
// Network/parse failures NEVER gate the player (state stays .unknown) so an
// offline launch is always playable.
//
// Config schema (same as the reference gist):
// {
//   "ios":     { "latestVersion": "1.2.0", "minVersion": "1.0.0" },
//   "android": { "latestVersion": "1.0.5", "minVersion": "1.0.0" },
//   "storeUrls": { "ios": "https://apps.apple.com/...", "android": "https://play.google.com/..." }
// }

@MainActor
@Observable
final class VersionGate {

    static let shared = VersionGate()

    // Snuglo-specific version config (hashless /raw → always the latest revision).
    private static let configURL = URL(
        string: "https://gist.githubusercontent.com/firatdinc/aeb3a641f9ba15c3c837977de9eb1830/raw"
    )!

    /// Snuglo's App Store product page (app id 6772764229) — the authoritative
    /// Update destination, never the gist's storeUrls.ios.
    private static let appStoreURL = URL(string: "https://apps.apple.com/app/id6772764229")!

    enum State { case unknown, upToDate, soft, forced }

    private(set) var state: State = .unknown
    private(set) var latestVersion: String = ""
    private(set) var storeURL: URL?

    /// Remembers the version the user already dismissed a soft prompt for, so it
    /// doesn't nag again until a newer version ships. (Forced is never dismissible.)
    @ObservationIgnored private let dismissedKey = "snuglo.version.dismissedSoft"

    /// The running app's marketing version (CFBundleShortVersionString).
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    // MARK: - Remote config

    private struct RemoteConfig: Decodable {
        struct Platform: Decodable { let latestVersion: String; let minVersion: String }
        struct Stores: Decodable { let ios: String }
        let ios: Platform
        let storeUrls: Stores
    }

    /// Fetches the config and resolves `state`. Safe to call repeatedly (launch +
    /// every foreground). Silent no-op on any failure.
    func check() async {
        var request = URLRequest(url: Self.configURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData   // always see the latest gist
        request.timeoutInterval = 8
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let config = try? JSONDecoder().decode(RemoteConfig.self, from: data)
        else {
            return   // offline / malformed → never gate
        }

        latestVersion = config.ios.latestVersion
        // Ignore the gist's storeUrls.ios (it points to another app) — always Snuglo.
        storeURL = Self.appStoreURL

        let current = currentVersion
        if Self.isVersion(current, lessThan: config.ios.minVersion) {
            state = .forced
        } else if Self.isVersion(current, lessThan: config.ios.latestVersion) {
            let dismissed = UserDefaults.standard.string(forKey: dismissedKey)
            state = (dismissed == config.ios.latestVersion) ? .upToDate : .soft
        } else {
            state = .upToDate
        }
    }

    /// User dismissed the soft prompt — remember this version so we stay quiet
    /// until a newer one ships.
    func dismissSoft() {
        UserDefaults.standard.set(latestVersion, forKey: dismissedKey)
        if state == .soft { state = .upToDate }
    }

    /// Opens the App Store product page from the config (falls back to a no-op if
    /// the config had no usable URL).
    func openStore() {
        UIApplication.shared.open(storeURL ?? Self.appStoreURL)
    }

    // MARK: - Semantic version compare

    /// Dotted numeric compare: `true` when `a` < `b`. Missing components count as 0,
    /// so "1.2" == "1.2.0" and "1.2" < "1.2.1". Non-numeric parts degrade to 0.
    nonisolated static func isVersion(_ a: String, lessThan b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }
        let pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x < y }
        }
        return false
    }
}
