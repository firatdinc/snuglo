import SwiftUI

// MARK: — SnugloApp entry point
// Faz C: NavigationStack with path-based routing via AppRouter.
//
// NavigationStack root = SplashView (always the base).
// After 1.2 s splash pushes .onboarding (first run) or .mainMenu (returning user).
// All subsequent navigation goes through AppRouter.path.

@main
struct SnugloApp: App {

    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                SplashView()
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(route)
                    }
            }
            .environment(router)
        }
    }

    // MARK: — Route → View mapping

    @MainActor @ViewBuilder
    private func routeDestination(_ route: Route) -> some View {
        switch route {
        case .onboarding:
            OnboardingView()

        case .mainMenu:
            MainMenuView()
                .navigationBarBackButtonHidden(true)

        case .levelsList(let packId):
            LevelsListView(packId: packId)
                .navigationBarBackButtonHidden(true)

        case .packDetail(let packId):
            PackDetailView(packId: packId)

        case .gamePlay(let levelId):
            GameView(levelId: levelId)

        case .stats:
            StatsView()
                .navigationBarBackButtonHidden(true)

        case .shop:
            ShopView()
                .navigationBarBackButtonHidden(true)

        case .settings:
            SettingsView()
        }
    }
}
