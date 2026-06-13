import SwiftUI
import Observation
import UIKit
import GoogleMobileAds
import AppTrackingTransparency

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
    // Real AdMob units (Fırat's account ca-app-pub-8571533711927103). Registered
    // test devices still see test ads even here (see start()) — no ban risk.
    static let interstitial = "ca-app-pub-8571533711927103/7206078348"
    static let rewarded     = "ca-app-pub-8571533711927103/4579915005"
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
    /// How many rewarded ads watched today (anti-spam; resets at local midnight).
    private(set) var rewardedShownToday: Int = 0

    // MARK: - Config

    let interstitialFrequencyLevels: Int = 3
    let maxInterstitialsPerSession: Int = 5
    let warmupSeconds: TimeInterval = 30
    /// Anti-spam for rewarded ads: a minimum gap + a generous daily cap so users
    /// can't farm rewards by watching back-to-back videos.
    let rewardedCooldown: TimeInterval = 45
    let maxRewardedPerDay: Int = 20

    @ObservationIgnored private var lastRewardedAt: Date = .distantPast
    @ObservationIgnored private var rewardedDay: Int = 0

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
        loadThrottle()
    }

    /// Testable init: inject a custom session start to bypass warmup window.
    init(sessionStart: Date) {
        self.sessionStart = sessionStart
        loadConsentFlags()
        loadThrottle()
    }

    // MARK: - SDK lifecycle

    /// Start the Mobile Ads SDK and preload the first interstitial + rewarded.
    /// Idempotent — safe to call on every launch/foreground.
    func start() {
        guard !started else { return }
        started = true
        // Registered test devices (ADMOB_SETUP.md) — test ads on Fırat's & Ergün's
        // devices even in Release, no ban risk. Set BEFORE start().
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "2362EB31-0BFE-4FC3-AF96-EFD7FCD7C93A",  // Fırat
            "26078A84-52D0-40B5-86C7-BB2E0BE1585F",  // ergn
            "c7ed54b33c372a9987c275f00467fecc",      // Ergün (hash)
            "5bdab3040b25f6bf3b6809864653e42d"       // Ergün (hash)
        ]
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
        // Accounting advances regardless of fill so the cadence stays stable — and
        // so the unit tests remain valid.
        interstitialsShownThisSession += 1
        levelsCompletedSinceLastInterstitial = 0
        guard let ad = interstitial else { return }
        interstitial = nil
        await present(ad)               // resilient present (see below)
        loadInterstitial()              // preload the next
    }

    /// Present an interstitial onto a STABLE top view controller, retrying briefly
    /// while the hierarchy settles. Presenting while the level-complete cover is
    /// still dismissing (or the next-level navigation transition is in flight) makes
    /// UIKit tear the ad down a moment later — that was the "ad flashes then vanishes"
    /// bug. A fixed delay only guessed at when the transition ends; this waits for it.
    private func present(_ ad: GADInterstitialAd, attempt: Int = 0) async {
        if let root = Self.stableTopViewController() {
            ad.present(fromRootViewController: root)
            return
        }
        guard attempt < 15 else { return }   // ~3s ceiling, then give up silently
        try? await Task.sleep(for: .milliseconds(200))
        await present(ad, attempt: attempt + 1)
    }

    /// True when a rewarded ad can be shown right now: loaded, off cooldown, and
    /// under the daily cap. UI watch-ad buttons should gate on THIS, not just
    /// `rewardedAvailable`.
    var rewardedReady: Bool {
        rollDayIfNeeded()
        return rewardedAvailable
            && rewardedShownToday < maxRewardedPerDay
            && Date().timeIntervalSince(lastRewardedAt) >= rewardedCooldown
    }

    /// Seconds left on the rewarded cooldown (0 when ready).
    var rewardedCooldownRemaining: Int {
        max(0, Int(rewardedCooldown - Date().timeIntervalSince(lastRewardedAt)))
    }

    /// Present a rewarded video; `onReward` fires only if the user earns it.
    func showRewarded(onReward: @escaping () -> Void) {
        guard !adsRemovedProvider() else { return }
        guard rewardedReady, let ad = rewarded, let root = Self.topViewController() else { return }
        rewarded = nil
        rewardedAvailable = false
        recordRewardedShown()           // anti-spam accounting
        ad.present(fromRootViewController: root, userDidEarnRewardHandler: onReward)
        loadRewarded()                  // preload the next
    }

    // MARK: - Rewarded anti-spam

    private func rollDayIfNeeded() {
        let today = Int(Date().timeIntervalSince1970 / 86_400)
        if today != rewardedDay {
            rewardedDay = today
            rewardedShownToday = 0
            persistThrottle()
        }
    }

    private func recordRewardedShown() {
        rollDayIfNeeded()
        lastRewardedAt = Date()
        rewardedShownToday += 1
        persistThrottle()
    }

    private func persistThrottle() {
        let d = UserDefaults.standard
        d.set(lastRewardedAt.timeIntervalSince1970, forKey: "snuglo.ads.rewarded.last")
        d.set(rewardedDay, forKey: "snuglo.ads.rewarded.day")
        d.set(rewardedShownToday, forKey: "snuglo.ads.rewarded.count")
    }

    private func loadThrottle() {
        let d = UserDefaults.standard
        let t = d.double(forKey: "snuglo.ads.rewarded.last")
        if t > 0 { lastRewardedAt = Date(timeIntervalSince1970: t) }
        rewardedDay = d.integer(forKey: "snuglo.ads.rewarded.day")
        rewardedShownToday = d.integer(forKey: "snuglo.ads.rewarded.count")
        rollDayIfNeeded()
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

    // MARK: - App Tracking Transparency

    /// Request the ATT permission prompt at launch — only when still
    /// undetermined (iOS shows the system prompt once). Syncs `hasConsented`.
    func requestTrackingIfNeeded() async {
        let current = ATTrackingManager.trackingAuthorizationStatus
        guard current == .notDetermined else {
            setConsent(current == .authorized)
            return
        }
        let status = await ATTrackingManager.requestTrackingAuthorization()
        setConsent(status == .authorized)
        // Reload ads so the consent decision applies to the next impressions
        // (ADMOB_SETUP.md: "izin kararından sonra reklamları yeniden yükle").
        if started, !adsRemovedProvider() {
            loadInterstitial()
            loadRewarded()
        }
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

    /// Like `topViewController()` but returns nil while any controller in the chain
    /// is mid-transition (being presented or dismissed). Presenting onto a VC that
    /// is about to leave the hierarchy makes the ad disappear with it — callers
    /// should retry until this returns a settled controller.
    private static func stableTopViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? scene.windows.first?.rootViewController
        else { return nil }
        var top = root
        if top.isBeingPresented || top.isBeingDismissed { return nil }
        while let presented = top.presentedViewController {
            if presented.isBeingPresented || presented.isBeingDismissed { return nil }
            top = presented
        }
        return top
    }
}
