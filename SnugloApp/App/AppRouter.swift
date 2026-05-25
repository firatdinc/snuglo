import SwiftUI

// MARK: — AppRouter
// Faz C navigation skeleton — iOS 18+, @Observable (no ObservableObject).
// Single NavigationStack at the app root; path drives all screen transitions.
// Sheets (Pause, LevelComplete) are managed locally in GameView.

// MARK: — Level completion stats (passed to LevelCompleteSheet)

struct LevelStats: Hashable, Sendable {
    let elapsedSeconds: Int   // total play time
    let stars: Int            // 0 – 3
    let hintsUsed: Int
}

// MARK: — Bottom tab

enum AppTab: String, CaseIterable {
    case play   = "Play"
    case levels = "Levels"
    case stats  = "Stats"
    case shop   = "Shop"

    var sfSymbol: String {
        switch self {
        case .play:   "puzzlepiece.fill"
        case .levels: "square.grid.2x2.fill"
        case .stats:  "chart.bar.fill"
        case .shop:   "bag.fill"
        }
    }
}

// MARK: — Route

/// All navigation destinations.
/// Pause and LevelComplete are sheets inside GameView, not NavigationStack pushes.
enum Route: Hashable {
    case onboarding
    case mainMenu
    case levelsList(packId: String)   // screen 04 — pack browser ("" = all packs)
    case packDetail(packId: String)   // screen 05 — levels within a pack
    case gamePlay(levelId: String)    // screen 06 — active game
    case stats                        // screen 09
    case shop                         // screen 10
    case settings                     // screen 11
}

// MARK: — AppRouter

@Observable
@MainActor
final class AppRouter {

    // NavigationStack path — everything after the SplashView root
    var path: [Route] = []

    // Active bottom tab (used by BottomTabBar)
    var selectedTab: AppTab = .play

    // MARK: — Basic navigation

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

    /// Generic present — uses push for NavigationStack destinations.
    func present(_ route: Route) {
        push(route)
    }

    // MARK: — Tab switching

    /// Called by BottomTabBar; resets path to [.mainMenu] then optionally pushes tab route.
    func selectTab(_ tab: AppTab) {
        selectedTab = tab
        switch tab {
        case .play:
            path = [.mainMenu]
        case .levels:
            path = [.mainMenu, .levelsList(packId: "")]
        case .stats:
            path = [.mainMenu, .stats]
        case .shop:
            path = [.mainMenu, .shop]
        }
    }

    // MARK: — Helpers

    /// Whether the current top route should show the bottom tab bar.
    var showsTabBar: Bool {
        guard let top = path.last else { return false }
        switch top {
        case .mainMenu, .stats, .shop: return true
        case .levelsList:              return true
        default:                       return false
        }
    }
}
