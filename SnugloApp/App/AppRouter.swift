import SwiftUI
import Observation

// MARK: — Route enum
// Navigation destinations for the entire app.
// Faz C: 11-screen navigation skeleton.
// Faz I-2: added .levelsList for levels-list pushed from home tab.

enum Route: Hashable {
    case onboarding
    case mainMenu
    case game(levelID: String)
    // gamePlay is a semantic alias used by daily-puzzle / continue-card call sites.
    // Both route to the same GameView; kept separate so call-site intent is readable.
    case gamePlay(levelId: String)
    case packDetail(packId: String)
    case levelsList          // Faz I-2: levels list (was a tab; now pushed from home)
    case settings
    case shop
}

// MARK: — AppTab
// Faz I-2: Tabs updated to home / stats / shop / settings.
// Levels are now accessed via the home tab (push → levelsList route).

enum AppTab: Hashable, CaseIterable {
    case home, stats, shop, settings
}

// MARK: — AppRouter

/// Observable navigation state. Inject via `.environment(router)` from SnugloApp.
@Observable
final class AppRouter {

    var path: [Route] = []
    var selectedTab: AppTab = .home

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
        // Tab switching is a state-only change — MainMenuView swaps its
        // content based on selectedTab. Don't pop the NavigationStack;
        // doing so would unwind back to Splash and re-trigger its animation.
        selectedTab = tab
    }
}
