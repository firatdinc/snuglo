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
        NavigationStack(path: $bindableRouter.path) {
            SplashView()
                .navigationBarBackButtonHidden()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .accessibilityIdentifier("screen.root")   // Faz I-2
        .environment(router)
        .preferredColorScheme(preferredScheme)
        // Faz G-2: Interstitial ad overlay — sits above all navigation content.
        // FAZ-J: Remove once GADInterstitialAd handles its own UIViewController.
        .overlay(AdInterstitialOverlay())
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .mainMenu:
            MainMenuView()
                .navigationBarBackButtonHidden()
        case .onboarding:
            OnboardingView()
                .navigationBarBackButtonHidden()
        case .game(let levelID):
            GameView(levelId: levelID)
                .navigationBarBackButtonHidden()
        case .gamePlay(let levelId):
            GameView(levelId: levelId)
                .navigationBarBackButtonHidden()
        case .packDetail(let packId):
            PackDetailView(packName: packId)
        case .levelsList:                          // Faz I-2: levels list pushed from home tab
            LevelsListView(packId: "")
        case .settings:
            SettingsView()
        case .shop:
            ShopView()
        }
    }
}

#Preview {
    RootView()
}
