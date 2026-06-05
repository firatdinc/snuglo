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
@MainActor
final class AppRouter {

    /// Outer stack — splash / onboarding flow only (.onboarding).
    var path: [Route] = []
    /// True once the main-app shell (RootTabView) should be shown.
    /// Set by push(.mainMenu); RootView switches from NavigationStack to RootTabView.
    var showingMainApp: Bool = false
    var selectedTab: AppTab = .play
    /// True while GameView is visible — disables tab carousel horizontal swipe.
    var isGameActive: Bool = false

    // MARK: — Energy gate
    /// Shown when the player tries to start a paid game without enough energy.
    var showEnergyGate: Bool = false
    /// The game route to launch once energy is topped up (ad / wait / premium).
    var pendingGameRoute: Route?

    /// Relaxed routes (Endless / Zen) are FREE — they never cost energy.
    private func isRelaxedRoute(_ route: Route) -> Bool {
        switch route {
        case .game(let id), .gamePlay(let id): return id.hasPrefix("endless")
        default: return false
        }
    }

    private func isGameRoute(_ route: Route) -> Bool {
        switch route {
        case .game, .gamePlay: return true
        default: return false
        }
    }

    /// Try to launch the remembered game once energy is available (called by the
    /// energy gate after an ad refill / premium purchase).
    func launchPendingGameIfReady() {
        guard let route = pendingGameRoute else { return }
        if isRelaxedRoute(route) || EnergyStore.shared.startGameIfAffordable() {
            pendingGameRoute = nil
            showEnergyGate = false
            appendToCurrentTab(route)
        }
    }

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
        case .game, .gamePlay:
            // Paid game start: spend energy (Endless/Zen + premium are free). If
            // the player can't afford it, remember the route and raise the gate.
            if isRelaxedRoute(route) || EnergyStore.shared.startGameIfAffordable() {
                appendToCurrentTab(route)
            } else {
                pendingGameRoute = route
                showEnergyGate = true
            }
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

    /// Atomically swap the top route of the CURRENT tab's stack. Used by the
    /// level-complete "Next" flow so Back still returns to the pre-game screen
    /// (PackDetail / MainMenu) instead of the just-finished level.
    ///
    /// Bug fix: the game lives in a per-tab path (e.g. `playPath`), NOT the
    /// outer `path` (which is only the splash/onboarding stack). Mutating the
    /// wrong array left the finished board on screen when "Next" was tapped.
    func replaceTop(with route: Route) {
        // Next-level continuation also costs energy (Endless/Zen + premium free).
        // Best-effort: never blocks mid-session — if low, it simply doesn't charge.
        if isGameRoute(route), !isRelaxedRoute(route) {
            _ = EnergyStore.shared.startGameIfAffordable()
        }
        func swap(_ p: inout [Route]) {
            if p.isEmpty { p.append(route) } else { p[p.count - 1] = route }
        }
        switch resolvedTab {
        case .levels:      swap(&levelsPath)
        case .shop:        swap(&shopPath)
        case .leaderboard: swap(&leaderboardPath)
        case .profile:     swap(&profilePath)
        default:           swap(&playPath)
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
