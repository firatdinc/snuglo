import SwiftUI

// MARK: — SnugloApp
// Faz C: Entry point updated to use RootView (NavigationStack + AppRouter).
// Previously: WindowGroup { GameView() }
// Now:        WindowGroup { RootView() }

@main
struct SnugloApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
