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
    case levelsList
    case settings
    case shop
}

// MARK: — AppTab
// Faz 2: Vibrant Play — 4 visible tabs: Play · Levels · Stats · Shop
//   .play    — primary "Play" tab (main menu / home scroll content)
//   .levels  — tapping pushes .levelsList route (BottomTabBar handles the push)
//   .stats   — Stats screen
//   .shop    — Shop screen
// Backward-compat cases (not shown in tab bar, kept so existing call sites compile):
//   .home     — LevelsListView sets router.selectedTab = .home on appear
//   .settings — LevelsListView calls router.selectTab(.settings); MainMenuView
//               tabContent still renders SettingsView for this case

enum AppTab: Hashable {
    case play
    case home       // backward compat — maps to play content in tabContent switch
    case levels     // Levels tab — BottomTabBar pushes .levelsList route on tap
    case stats      // backward compat — Stats now lives INSIDE the Profile tab
    case shop
    case profile    // rightmost tab — profile screen that contains Stats
    case settings   // backward compat — no longer in tab bar; shows inline settings
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
    }
}
