import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()

    // Faz F: Theme picker (0=System, 1=Light, 2=Dark) — mirrors SettingsView key.
    @AppStorage("appTheme") private var appThemeRaw: Int = 0

    private var preferredScheme: ColorScheme? {
        switch appThemeRaw {
        case 1: return .light
        case 2: return .dark
        default: return nil   // System — follow device setting
        }
    }

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
            if bindableRouter.showingMainApp {
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
        .environment(router)
        .preferredColorScheme(preferredScheme)
        // Faz G-2: Interstitial ad overlay — sits above all navigation content.
        // FAZ-J: Remove once GADInterstitialAd handles its own UIViewController.
        .overlay(AdInterstitialOverlay())
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
        case .mainMenu:
            EmptyView()
        }
    }
}

#Preview {
    RootView()
}
