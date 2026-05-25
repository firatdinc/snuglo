import SwiftUI
import UserNotifications

// MARK: — SnugloApp (Faz F update)
// Faz C: Entry point updated to use RootView (NavigationStack + AppRouter).
// Faz F: init() sets UNUserNotificationCenter.delegate = NotificationService.shared
//        so willPresent fires in foreground → banner + sound displayed.

@main
struct SnugloApp: App {

    init() {
        // Delegate must be assigned before any notifications arrive.
        // NotificationService.shared is the UNUserNotificationCenterDelegate.
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        // I-2: Reset state for UI automation tests
        if ProcessInfo.processInfo.arguments.contains("-uitest-reset-progress") {
            ProgressStore.shared.reset()
            UserDefaults.standard.removeObject(forKey: "hasOnboarded")
            UserDefaults.standard.removeObject(forKey: "snuglo.language.override")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
