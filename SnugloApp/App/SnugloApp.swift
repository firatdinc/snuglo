import SwiftUI
import UserNotifications

// MARK: — SnugloApp (Faz F update)
// Faz C: Entry point updated to use RootView (NavigationStack + AppRouter).
// Faz F: init() sets UNUserNotificationCenter.delegate = NotificationService.shared
//        so willPresent fires in foreground → banner + sound displayed.

@main
struct SnugloApp: App {

    init() {
        // Faz I-2: XCUITest fast-path — skip splash & onboarding in UI test runs.
        if CommandLine.arguments.contains("-UITestMode") {
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
            UserDefaults.standard.set(true, forKey: "snuglo.uitestmode")
        }
        // Delegate must be assigned before any notifications arrive.
        // NotificationService.shared is the UNUserNotificationCenterDelegate.
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
