import SwiftUI
import Observation

// MARK: — AdsManager (Faz G-2 Placeholder)
//
// Placeholder ads layer. Real AdMob integration is swapped in Faz J via
// `RealAdsAdapter`; this scaffold keeps frequency cap + lifecycle correct.
//
// Frequency cap rules:
//   • Interstitial every `interstitialFrequencyLevels` (default 3) completions
//   • Skip if within first `warmupSeconds` (default 30s) of session
//   • Hard cap `maxInterstitialsPerSession` (default 5) per session
//   • All paths short-circuit if StoreManager.adsRemoved == true
//
// Faz J swap points are marked with // FAZ-J: comments.

@Observable
final class AdsManager {

    // MARK: - Singleton

    static let shared = AdsManager()

    // MARK: - State

    private(set) var isShowingInterstitial: Bool = false
    private(set) var isShowingBanner: Bool = false
    private(set) var interstitialsShownThisSession: Int = 0
    private(set) var levelsCompletedSinceLastInterstitial: Int = 0
    private(set) var rewardedAvailable: Bool = false

    // MARK: - Config

    /// Show an interstitial every N level completions (skip first N-1 completions).
    let interstitialFrequencyLevels: Int = 3
    /// Hard cap per session.
    let maxInterstitialsPerSession: Int = 5
    /// Don't show in the first N seconds of a session (engine warm-up).
    let warmupSeconds: TimeInterval = 30

    // Session start — injectable for unit tests via internal init.
    let sessionStart: Date

    // MARK: - Ads-removed provider (injectable for tests)

    /// Override in tests: `manager.adsRemovedProvider = { true }`
    var adsRemovedProvider: () -> Bool = { StoreManager.shared.adsRemoved }

    // MARK: - Consent

    private(set) var hasConsented: Bool = false

    // MARK: - Init

    /// Production singleton init — session starts now.
    private init() {
        sessionStart = Date()
        loadConsentFlags()
    }

    /// Testable init: inject a custom session start to bypass warmup window.
    init(sessionStart: Date) {
        self.sessionStart = sessionStart
        loadConsentFlags()
    }

    // MARK: - Lifecycle Hooks

    /// Called when a level is successfully completed.
    /// Determines whether to trigger an interstitial based on frequency cap rules.
    func onLevelCompleted() {
        guard !adsRemovedProvider() else { return }

        levelsCompletedSinceLastInterstitial += 1

        // Warmup guard — don't show in first N seconds of session
        guard Date().timeIntervalSince(sessionStart) >= warmupSeconds else { return }

        // Session hard cap
        guard interstitialsShownThisSession < maxInterstitialsPerSession else { return }

        // Frequency cap — every N completions
        guard levelsCompletedSinceLastInterstitial >= interstitialFrequencyLevels else { return }

        Task { await showInterstitial(reason: "levelCompleted") }
    }

    // MARK: - Ad Presentation

    /// Show an interstitial ad. Placeholder: simulates a 1.5 s ad duration.
    /// FAZ-J: Replace body with GADInterstitialAd load + present.
    @MainActor
    func showInterstitial(reason: String) async {
        guard !adsRemovedProvider() else { return }

        isShowingInterstitial = true

        // FAZ-J: Real impl calls GADInterstitialAd.load(...) then present(...)
        //        and awaits the delegate callback. Remove the sleep below.
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 s placeholder

        isShowingInterstitial = false
        interstitialsShownThisSession += 1
        levelsCompletedSinceLastInterstitial = 0
    }

    /// Show a rewarded video. Placeholder: immediately calls reward callback
    /// so developer flow remains testable end-to-end.
    /// FAZ-J: Replace with GADRewardedAd load + present + delegate reward callback.
    func showRewarded(onReward: @escaping () -> Void) {
        guard !adsRemovedProvider() else { return }
        guard rewardedAvailable else { return }
        // FAZ-J: Remove immediate call; fire only via GADFullScreenContentDelegate
        onReward()
    }

    // MARK: - Banner

    /// True when a banner should be displayed (not removed by IAP).
    var shouldShowBanner: Bool {
        !adsRemovedProvider()
    }

    // MARK: - Remove-Ads Reset

    /// Called automatically via shouldShowBanner / adsRemovedProvider once
    /// StoreManager.adsRemoved flips to true. No explicit reset needed —
    /// all guards short-circuit through adsRemovedProvider().
    ///
    /// FAZ-J: If AdMob SDK holds cached ads, call GADMobileAds.sharedInstance()
    ///        and clear cached interstitial/rewarded references here.
    func resetOnAdsRemoved() {
        interstitialsShownThisSession = 0
        levelsCompletedSinceLastInterstitial = 0
    }

    // MARK: - Consent

    func setConsent(_ value: Bool) {
        hasConsented = value
        UserDefaults.standard.set(value, forKey: "snuglo.ads.consent")
        // FAZ-J: Forward to UMP SDK (Google User Messaging Platform) here.
    }

    private func loadConsentFlags() {
        hasConsented = UserDefaults.standard.bool(forKey: "snuglo.ads.consent")
    }
}
