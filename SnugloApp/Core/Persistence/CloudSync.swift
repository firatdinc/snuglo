import Foundation
import Observation

// MARK: — CloudSync
// Transparent iCloud backup/restore of the local save via NSUbiquitousKeyValueStore
// (KVS). Reuses SaveTransfer.keys as the single source of truth for *what* makes up
// a save, so progress, economy, cosmetics, meta-progress and preferences all sync.
//
// Why KVS (not CloudKit): the whole save is a handful of small JSON snapshots well
// under the KVS budget (1 MB total / 1 MB per key / 1024 keys). KVS needs no schema,
// no record types, no custom container plumbing — just the ubiquity-kvstore
// entitlement — and it merges silently across the user's devices.
//
// Conflict model: a monotonic revision counter (`revKey`) lives in BOTH UserDefaults
// and KVS. Whoever has the higher rev wins. For a single-player cozy game this is the
// right trade-off — we want device migration continuity, not field-level merge.
//
// Lifecycle (wired from RootView):
//   • bootstrap()  — at launch, BEFORE the game stores read UserDefaults. On a fresh
//                    install with iCloud data it briefly waits for the cloud payload
//                    and merges it in; for an existing player it just backs up.
//   • pushToCloud()— on backgrounding (and after bootstrap) → this device → cloud.
//   • a lifetime observer pulls external changes into UserDefaults (applied on the
//     next cold launch — we don't hot-swap the in-memory singletons mid-session).

@MainActor
@Observable
final class CloudSync {

    static let shared = CloudSync()

    /// True once bootstrap() has finished — RootView gates first paint on this so the
    /// stores never read UserDefaults before a fresh-install restore lands.
    private(set) var ready: Bool = false

    @ObservationIgnored private let kv = NSUbiquitousKeyValueStore.default
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var started = false

    private let revKey = "snuglo.cloud.rev"
    /// Probe key: presence of a real save locally. If absent, this is a fresh install
    /// and we should wait for iCloud to (maybe) hand us a backup before painting.
    private let progressKey = "snuglo.progress.v1"

    private init() {}

    /// iCloud signed in on this device?
    private var iCloudAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }

    // MARK: - Launch

    /// Run once at launch, before the game's stores are first accessed.
    /// - Existing player (local save present): back this device up to the cloud.
    /// - Fresh install with iCloud: briefly wait for the cloud payload, then merge it
    ///   so the stores load restored data on their first read.
    /// Always flips `ready` so the UI proceeds even with no iCloud / on timeout.
    func bootstrap() async {
        defer { ready = true }
        startObserving()
        guard iCloudAvailable else { return }
        kv.synchronize()

        let hasLocalSave = defaults.object(forKey: progressKey) != nil
        if hasLocalSave {
            // Known player on this device — make sure the cloud holds our latest.
            pushToCloud()
            // …but if another device is ahead, prefer it (e.g. reinstalled here while
            // the iPad kept playing).
            pullFromCloud()
            return
        }

        // Fresh install: give iCloud a moment to deliver a backup before we paint.
        // KVS delivers asynchronously via didChangeExternallyNotification; poll the
        // rev for up to ~2.5s, then proceed regardless.
        for _ in 0..<12 {
            if kv.longLong(forKey: revKey) > 0 { break }
            try? await Task.sleep(for: .milliseconds(200))
        }
        if !pullFromCloud() {
            // Nothing in the cloud either — seed it so future devices can restore.
            pushToCloud()
        }
    }

    // MARK: - Push / Pull

    /// Copy the local save (SaveTransfer.keys) up to iCloud and bump the revision.
    func pushToCloud() {
        guard iCloudAvailable else { return }
        for key in SaveTransfer.keys {
            if let value = defaults.object(forKey: key) {
                kv.set(value, forKey: key)
            } else {
                kv.removeObject(forKey: key)
            }
        }
        let nextRev = max(kv.longLong(forKey: revKey), defaults.integer(forKey: revKey).toInt64) + 1
        kv.set(nextRev, forKey: revKey)
        defaults.set(Int(nextRev), forKey: revKey)
        kv.synchronize()
    }

    /// Merge iCloud's save into UserDefaults when the cloud is strictly ahead.
    /// Returns true if anything was applied. Caller decides what to do with that
    /// (at launch: nothing — stores read fresh; mid-session: applies next cold start).
    @discardableResult
    func pullFromCloud() -> Bool {
        guard iCloudAvailable else { return false }
        let cloudRev = kv.longLong(forKey: revKey)
        let localRev = Int64(defaults.integer(forKey: revKey))
        guard cloudRev > localRev else { return false }
        for key in SaveTransfer.keys {
            if let value = kv.object(forKey: key) {
                defaults.set(value, forKey: key)
            }
        }
        defaults.set(Int(cloudRev), forKey: revKey)
        return true
    }

    // MARK: - Observation

    private func startObserving() {
        guard !started else { return }
        started = true
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kv, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { _ = self?.pullFromCloud() }
        }
    }
}

private extension Int {
    var toInt64: Int64 { Int64(self) }
}
