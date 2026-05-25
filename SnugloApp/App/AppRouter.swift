import SwiftUI
import Observation

// MARK: — Route enum
// Navigation destinations for the entire app.
// Faz C: 11-screen navigation skeleton.

enum Route: Hashable {
    case onboarding
    case mainMenu
    case game(levelID: String)
    // gamePlay is a semantic alias used by daily-puzzle / continue-card call sites.
    // Both route to the same GameView; kept separate so call-site intent is readable.
    case gamePlay(levelId: String)
    case packDetail(packId: String)
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
        // Tab switching is a state-only change — MainMenuView swaps its
        // content based on selectedTab. Don't pop the NavigationStack;
        // doing so would unwind back to Splash and re-trigger its animation.
        selectedTab = tab
    }
}
