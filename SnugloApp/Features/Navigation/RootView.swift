import SwiftUI

// MARK: — RootView
// Faz C — Navigation skeleton
// Single NavigationStack rooted at SplashView.
// All route destinations registered here.
// Bottom tab-bar lives inside MainMenuView (native TabView).

struct RootView: View {

    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            SplashView()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .environment(router)
    }

    // MARK: — Destination map

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .onboarding:
            OnboardingView()
        case .mainMenu:
            MainMenuView()
                .navigationBarBackButtonHidden()
        case .game(let levelID):
            GameView(levelId: levelID)
                .navigationBarBackButtonHidden()
        case .packDetail(let packName):
            PackDetailView(packName: packName)
        case .settings:
            SettingsView()
        case .shop:
            ShopView()
        }
    }
}

// MARK: — Preview

#Preview {
    RootView()
}
