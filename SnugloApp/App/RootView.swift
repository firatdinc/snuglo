import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            SplashView()
                .navigationBarBackButtonHidden()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .environment(router)
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
