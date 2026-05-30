import SwiftUI
import Observation

// MARK: — Route enum

enum Route: Hashable {
    case onboarding
    case mainMenu
    case game(levelID: String)
    // gamePlay is a semantic alias — both route to GameView; kept for call-site readability.
    case gamePlay(levelId: String)
    case packDetail(packId: String)
    case levelsList
    case settings
    case shop
    case achievements
    case dailyReward
}

// MARK: — AppTab

// 5 visible tabs: levels · shop · play (center, elevated) · leaderboard · profile
// Backward-compat cases kept so existing call sites compile unchanged:
//   .home     → .play
//   .stats    → .profile
//   .settings → push .settings into playPath + switch to .play tab

enum AppTab: Hashable {
    case levels
    case shop
    case play
    case leaderboard
    case profile
    // backward compat
    case home
    case stats
    case settings
}

// MARK: — AppRouter

/// Observable navigation state. Inject via `.environment(router)` from SnugloApp.
@Observable
final class AppRouter {

    /// Outer stack — splash / onboarding flow only (.onboarding).
    var path: [Route] = []
    /// True once the main-app shell (RootTabView) should be shown.
    /// Set by push(.mainMenu); RootView switches from NavigationStack to RootTabView.
    var showingMainApp: Bool = false
    var selectedTab: AppTab = .play

    // Per-tab NavigationStack paths (Faz 1)
    var levelsPath: [Route] = []
    var shopPath: [Route] = []
    var playPath: [Route] = []
    var leaderboardPath: [Route] = []
    var profilePath: [Route] = []

    // MARK: — Push

    func push(_ route: Route) {
        switch route {
        case .mainMenu:
            // Flip the top-level switch in RootView; no path append needed.
            // Avoids nested NavigationStacks (outer RootView stack + inner per-tab stacks).
            showingMainApp = true
        case .onboarding:
            path.append(route)
        case .levelsList:
            // .levelsList is the Levels tab root — switch tab instead of pushing
            selectedTab = .levels
        default:
            appendToCurrentTab(route)
        }
    }

    // MARK: — Pop

    func pop() {
        guard !currentTabPath.isEmpty else { return }
        switch resolvedTab {
        case .levels:      levelsPath.removeLast()
        case .shop:        shopPath.removeLast()
        case .leaderboard: leaderboardPath.removeLast()
        case .profile:     profilePath.removeLast()
        default:           playPath.removeLast()
        }
    }

    func popToRoot() {
        switch resolvedTab {
        case .levels:      levelsPath.removeAll()
        case .shop:        shopPath.removeAll()
        case .leaderboard: leaderboardPath.removeAll()
        case .profile:     profilePath.removeAll()
        default:           playPath.removeAll()
        }
    }

    // MARK: — Select tab (with backward-compat normalization)

    func selectTab(_ tab: AppTab) {
        switch tab {
        case .home:
            selectedTab = .play
        case .stats:
            selectedTab = .profile
        case .settings:
            // .settings has no dedicated tab — push settings route into play tab
            playPath.append(.settings)
            selectedTab = .play
        default:
            selectedTab = tab
        }
    }

    // MARK: — Private helpers

    /// Resolves backward-compat tab values to their canonical equivalents.
    private var resolvedTab: AppTab {
        switch selectedTab {
        case .home, .settings: return .play
        case .stats:           return .profile
        default:               return selectedTab
        }
    }

    private var currentTabPath: [Route] {
        switch resolvedTab {
        case .levels:      return levelsPath
        case .shop:        return shopPath
        case .leaderboard: return leaderboardPath
        case .profile:     return profilePath
        default:           return playPath
        }
    }

    private func appendToCurrentTab(_ route: Route) {
        switch resolvedTab {
        case .levels:      levelsPath.append(route)
        case .shop:        shopPath.append(route)
        case .leaderboard: leaderboardPath.append(route)
        case .profile:     profilePath.append(route)
        default:           playPath.append(route)
        }
    }
}
