import SwiftUI
import Observation
import UIKit
import GoogleMobileAds

// MARK: — AdsManager (Faz 5: real AdMob)
//
// Wraps Google Mobile Ads (interstitial + rewarded) behind the same surface the
// app already used in the placeholder era, so call-sites are unchanged. The
// frequency-cap / lifecycle logic (and its unit tests) are preserved exactly;
// only the presentation bodies now drive the real SDK.
//
// Frequency cap rules:
//   • Interstitial every `interstitialFrequencyLevels` (default 3) completions
//   • Skip if within first `warmupSeconds` (default 30s) of session
//   • Hard cap `maxInterstitialsPerSession` (default 5) per session
//   • All paths short-circuit if StoreManager.adsRemoved == true
//
// DEBUG builds use Google's official TEST ad units (always fill). Release builds
// must use the real AdMob units below — and Info.plist's GADApplicationIdentifier
// must be the real ca-app-pub-XXXX~YYYY.

private enum AdUnitID {
#if DEBUG
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    static let rewarded     = "ca-app-pub-3940256099942544/1712485313"
#else
    // TODO: AdMob konsolunda gerçek birimleri oluştur ve buraya koy.
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    static let rewarded     = "ca-app-pub-3940256099942544/1712485313"
#endif
}

@MainActor
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

    let interstitialFrequencyLevels: Int = 3
    let maxInterstitialsPerSession: Int = 5
    let warmupSeconds: TimeInterval = 30

    let sessionStart: Date

    // MARK: - Loaded ads (@ObservationIgnored — SDK objects aren't observable state)

    @ObservationIgnored private var interstitial: GADInterstitialAd?
    @ObservationIgnored private var rewarded: GADRewardedAd?
    @ObservationIgnored private var started = false

    // MARK: - Ads-removed provider (injectable for tests)

    var adsRemovedProvider: () -> Bool = { StoreManager.shared.adsRemoved }

    // MARK: - Consent

    private(set) var hasConsented: Bool = false

    // MARK: - Init

    private init() {
        sessionStart = Date()
        loadConsentFlags()
    }

    /// Testable init: inject a custom session start to bypass warmup window.
    init(sessionStart: Date) {
        self.sessionStart = sessionStart
        loadConsentFlags()
    }

    // MARK: - SDK lifecycle

    /// Start the Mobile Ads SDK and preload the first interstitial + rewarded.
    /// Idempotent — safe to call on every launch/foreground.
    func start() {
        guard !started else { return }
        started = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        guard !adsRemovedProvider() else { return }
        loadInterstitial()
        loadRewarded()
    }

    // MARK: - Lifecycle Hooks

    /// Called when a level is successfully completed — applies the frequency-cap
    /// rules and shows an interstitial when due.
    func onLevelCompleted() {
        guard !adsRemovedProvider() else { return }
        levelsCompletedSinceLastInterstitial += 1
        guard Date().timeIntervalSince(sessionStart) >= warmupSeconds else { return }
        guard interstitialsShownThisSession < maxInterstitialsPerSession else { return }
        guard levelsCompletedSinceLastInterstitial >= interstitialFrequencyLevels else { return }
        Task { await showInterstitial(reason: "levelCompleted") }
    }

    // MARK: - Ad Presentation

    /// Present a real interstitial if one is loaded (the SDK draws its own
    /// full-screen UI). The frequency-cap accounting advances regardless of fill
    /// so the cadence stays stable — and so the unit tests remain valid.
    func showInterstitial(reason: String) async {
        guard !adsRemovedProvider() else { return }
        if let ad = interstitial, let root = Self.topViewController() {
            interstitial = nil
            ad.present(fromRootViewController: root)
            loadInterstitial()          // preload the next
        }
        interstitialsShownThisSession += 1
        levelsCompletedSinceLastInterstitial = 0
    }

    /// Present a rewarded video; `onReward` fires only if the user earns it.
    func showRewarded(onReward: @escaping () -> Void) {
        guard !adsRemovedProvider() else { return }
        guard let ad = rewarded, let root = Self.topViewController() else { return }
        rewarded = nil
        rewardedAvailable = false
        ad.present(fromRootViewController: root, userDidEarnRewardHandler: onReward)
        loadRewarded()                  // preload the next
    }

    // MARK: - Loading

    private func loadInterstitial() {
        guard !adsRemovedProvider() else { return }
        GADInterstitialAd.load(withAdUnitID: AdUnitID.interstitial, request: GADRequest()) { [weak self] ad, _ in
            Task { @MainActor in self?.interstitial = ad }
        }
    }

    private func loadRewarded() {
        guard !adsRemovedProvider() else { return }
        GADRewardedAd.load(withAdUnitID: AdUnitID.rewarded, request: GADRequest()) { [weak self] ad, _ in
            Task { @MainActor in
                self?.rewarded = ad
                self?.rewardedAvailable = ad != nil
            }
        }
    }

    // MARK: - Banner

    var shouldShowBanner: Bool { !adsRemovedProvider() }

    // MARK: - Remove-Ads Reset

    func resetOnAdsRemoved() {
        interstitialsShownThisSession = 0
        levelsCompletedSinceLastInterstitial = 0
        interstitial = nil
        rewarded = nil
        rewardedAvailable = false
    }

    // MARK: - Consent

    func setConsent(_ value: Bool) {
        hasConsented = value
        UserDefaults.standard.set(value, forKey: "snuglo.ads.consent")
    }

    private func loadConsentFlags() {
        hasConsented = UserDefaults.standard.bool(forKey: "snuglo.ads.consent")
    }

    // MARK: - Top view controller

    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? scene.windows.first?.rootViewController
        else { return nil }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}
