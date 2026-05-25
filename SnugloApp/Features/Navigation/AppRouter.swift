import SwiftUI

// MARK: — Navigation: Route + AppRouter
// Faz C — Navigation Skeleton
//
// Architecture:
//   NavigationStack(path: router.path) starting from SplashView.
//   SplashView pushes .onboarding or .mainMenu.
//   MainMenuView hosts a native TabView for the 4 tabs.
//   Deep links (game, packDetail, settings) push over the tab bar.

// MARK: — Route

enum Route: Hashable {
    case onboarding
    case mainMenu
    case game(levelID: String)
    case packDetail(packName: String)
    case settings
    case shop
}

// MARK: — Tab

enum AppTab: Hashable, CaseIterable {
    case play, levels, stats, shop
}

// MARK: — AppRouter

/// Observable navigation state injected via `.environment(router)` from RootView.
@Observable
final class AppRouter {

    // MARK: — Navigation path (drives NavigationStack)

    var path: [Route] = []

    // MARK: — Active tab (drives TabView inside MainMenuView)

    var selectedTab: AppTab = .play

    // MARK: — Helpers

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
