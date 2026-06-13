import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()
    // Runtime language switching — drives `\.locale` so localized Text re-resolves
    // live, without an app restart.
    @State private var localeManager = LocaleManager.shared
    // iCloud save sync — first paint waits on this so a fresh-install restore lands
    // BEFORE any store reads UserDefaults.
    @State private var cloud = CloudSync.shared
    // Remote version control — drives the soft "update available" banner and the
    // forced (below-minVersion) update wall.
    @State private var versionGate = VersionGate.shared

    // Faz F: Theme picker (0=System, 1=Light, 2=Dark) — mirrors SettingsView key.
    @AppStorage("appTheme") private var appThemeRaw: Int = 0

    // Background music: switches theme by Zen state, pauses in background.
    @AppStorage("zenMode") private var zenMode = false
    // Re-engagement: gentle "come back" reminders after a real absence.
    @AppStorage("comebackRemindersEnabled") private var comebackEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // iOS 17+ pattern: @Bindable for NavigationStack(path:) binding from
        // an @Observable router. Without it the binding sometimes failed to
        // observe nested mutations.
        @Bindable var bindableRouter = router
        // Explicit reads create @Observable observation deps so body re-renders
        // when these properties change. $bindableRouter.path only creates a
        // Binding (lazy get) — it does NOT register a dep on path by itself.
        // swiftlint:disable:next redundant_discardable_let
        let _ = router.path
        // swiftlint:disable:next redundant_discardable_let
        let _ = router.showingMainApp

        // Faz 1 architecture: RootTabView must NOT live inside a NavigationStack —
        // its own per-tab NavigationStacks would become nested stacks, breaking
        // the XCTest accessibility hierarchy. The pre-main flow (Splash → Onboarding)
        // uses a NavigationStack; once push(.mainMenu) fires, showingMainApp flips
        // and RootTabView becomes the top-level view with no outer stack.
        Group {
            if !cloud.ready {
                // Brief gate while iCloud (maybe) restores a save on a fresh install.
                // Existing players clear this in well under a frame; the stores below
                // are never touched until it flips, so a restore can't lose a race.
                LoadingView()
            } else if bindableRouter.showingMainApp {
                RootTabView()
            } else {
                NavigationStack(path: $bindableRouter.path) {
                    SplashView()
                        .navigationBarBackButtonHidden()
                        .navigationDestination(for: Route.self) { route in
                            preMainDestination(for: route)
                        }
                }
                .accessibilityIdentifier("screen.root")
            }
        }
        // Rebuild the whole UI subtree when language OR theme changes. `router`
        // lives in @State on RootView (OUTSIDE this id), so navigation paths
        // survive the rebuild — the user stays on their current screen. This is
        // what forces the `.page` TabView children (Settings, etc.) to re-resolve
        // localized strings and dynamic AppColors, which a plain environment/trait
        // change fails to propagate to them at runtime.
        .id("\(localeManager.languageCode)|\(appThemeRaw)|\(zenMode)")
        .environment(router)
        // Runtime locale — drives number/date formatting + Text re-resolution.
        .environment(\.locale, localeManager.locale)
        // Theme: force the window's interface style so dynamic AppColors resolve
        // against the chosen scheme (the rebuild above then re-reads it everywhere).
        .onAppear {
            ThemeApplier.apply(appThemeRaw)
            MusicService.shared.update(zen: zenMode)
            AdsManager.shared.start()
            // RevenueCat — only once a real public key is set (else stay on the
            // StoreKit/premium-flag path).
            if Secrets.revenueCatConfigured {
                RevenueCatManager.configure(apiKey: Secrets.revenueCatPublicKey)
            }
        }
        // iCloud save sync — runs before stores are read (the UI is gated on
        // `cloud.ready`). Restores a backup on a fresh install; backs this device up
        // otherwise.
        .task { await CloudSync.shared.bootstrap() }
        // Remote version check at launch — resolves soft/forced update state.
        .task { await VersionGate.shared.check() }
        // Sign in to Game Center at launch so scores submit and achievements
        // report in the background (idempotent — early-returns once resolved).
        .task { await GameCenterManager.shared.authenticate() }
        // Ask for the ATT (personalized ads) permission at launch — once, after a
        // beat so the app is active when the system prompt appears.
        .task {
            try? await Task.sleep(for: .seconds(1.2))
            await AdsManager.shared.requestTrackingIfNeeded()
        }
        .onChange(of: appThemeRaw) { _, newValue in ThemeApplier.apply(newValue) }
        // Swap to the Zen theme music the moment Zen Mode toggles.
        .onChange(of: zenMode) { _, newValue in MusicService.shared.update(zen: newValue) }
        // Pause music in the background; resume (respecting all gates) on return.
        // Comeback reminders: cancel while here, (re)arm on leaving after a real absence.
        .onChange(of: scenePhase) { _, phase in
            MusicService.shared.setForeground(phase == .active)
            if phase == .active {
                NotificationService.shared.cancelComeback()
                // Re-check version on every foreground so a freshly-bumped minVersion
                // gates a long-running session without a relaunch.
                Task { await VersionGate.shared.check() }
            } else if phase == .background {
                // Back up the latest save to iCloud whenever we leave.
                CloudSync.shared.pushToCloud()
                if comebackEnabled { NotificationService.shared.scheduleComeback() }
            }
        }
        // Faz G-2: Interstitial ad overlay — sits above all navigation content.
        // FAZ-J: Remove once GADInterstitialAd handles its own UIViewController.
        .overlay(AdInterstitialOverlay())
        // Energy gate — shown above everything when a paid game start is blocked.
        .overlay {
            if bindableRouter.showEnergyGate {
                EnergyGateSheet()
                    .environment(router)
                    .transition(.opacity)
                    .zIndex(100)
            }
            if bindableRouter.showPaywall {
                PremiumPaywallSheet()
                    .environment(router)
                    .transition(.opacity)
                    .zIndex(110)
            }
            // Global animated reward popup — above everything.
            if let reward = RewardCenter.shared.pending {
                RewardPopup(reward: reward) { RewardCenter.shared.dismiss() }
                    .zIndex(120)
            }
            // Milestone surprise: a freshly-earned Nook scene piece. Deferred until
            // the player leaves the level so it doesn't fight the level-complete
            // celebration — it greets them like a gift when they're back.
            if !bindableRouter.isGameActive, let reveal = NookRevealCenter.shared.pending {
                NookPieceRevealOverlay(
                    reveal: reveal,
                    onPlace: {
                        NookRevealCenter.shared.dismiss()
                        router.push(.nook)
                    },
                    onDismiss: { NookRevealCenter.shared.dismiss() }
                )
                .transition(.opacity)
                .zIndex(130)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: bindableRouter.showEnergyGate)
        .animation(.easeInOut(duration: 0.2), value: bindableRouter.showPaywall)
        // Version gate — sits ABOVE everything (even the cloud-loading gate). The
        // forced wall blocks the whole app; the soft banner is a dismissible top card.
        .overlay {
            if versionGate.state == .forced {
                UpdateRequiredView { versionGate.openStore() }
                    .transition(.opacity)
                    .zIndex(200)
            } else if versionGate.state == .soft, bindableRouter.showingMainApp {
                ZStack {
                    // Frosted blur over the app + blocks interaction: the popup can't
                    // be dismissed without updating (no "×", tapping behind does nothing).
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    AnnouncementBanner(
                        titleKey: "update.soft.title",
                        messageKey: "update.soft.message",
                        ctaKey: "update.soft.cta",
                        onCTA: { versionGate.openStore() }
                        // no onDismiss → not closable until the user updates
                    )
                    .padding(.horizontal, AppSpacing.lg)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                .zIndex(150)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: versionGate.state)
    }

    /// Destinations reachable during the pre-main (splash/onboarding) flow only.
    /// .mainMenu is intentionally absent — push(.mainMenu) sets showingMainApp instead.
    @ViewBuilder
    private func preMainDestination(for route: Route) -> some View {
        switch route {
        case .onboarding:
            OnboardingView()
                .navigationBarBackButtonHidden()
        case .game(let levelID):
            GameView(levelId: levelID)
                .id(levelID)
                .navigationBarBackButtonHidden()
        case .gamePlay(let levelId):
            GameView(levelId: levelId)
                .id(levelId)
                .navigationBarBackButtonHidden()
        case .packDetail(let packId):
            PackDetailView(packName: packId)
        case .levelsList:
            LevelsListView(packId: "")
        case .settings:
            SettingsView()
        case .shop:
            ShopView()
        case .achievements:
            AchievementsView()
        case .dailyReward:
            DailyRewardView()
        case .nook:
            NookView()
        case .mainMenu:
            EmptyView()
        }
    }
}

#Preview {
    RootView()
}
