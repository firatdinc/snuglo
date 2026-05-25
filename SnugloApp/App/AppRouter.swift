import SwiftUI
import Observation

// MARK: — Route enum
// Navigation destinations for the entire app.
// Faz C: 11-screen navigation skeleton.

enum Route: Hashable {
    case onboarding
    case mainMenu
    case game(levelID: String)
    case packDetail(packName: String)
    case settings
    case shop
}

// MARK: — AppTab
// 4 bottom-nav tabs inside MainMenuView's TabView.

enum AppTab: Hashable, CaseIterable {
    case play, levels, stats, shop
}

// MARK: — AppRouter

/// Observable navigation state. Inject via `.environment(router)` from SnugloApp.
@Observable
final class AppRouter {

    var path: [Route] = []
    var selectedTab: AppTab = .play

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

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
        popToRoot()
    }
}
