import SwiftUI
import UserNotifications

// MARK: — SnugloApp (Faz F update · Faz I-2 launch-arg reset)
// Faz C: Entry point updated to use RootView (NavigationStack + AppRouter).
// Faz F: init() sets UNUserNotificationCenter.delegate = NotificationService.shared
//        so willPresent fires in foreground → banner + sound displayed.
// Faz I-2: -uitest-reset-progress wipes ProgressStore + UserDefaults for clean runs.

@main
struct SnugloApp: App {

    init() {
        let args = CommandLine.arguments

        // Faz I-2: XCUITest fast-path — skip splash & onboarding in UI test runs.
        if args.contains("-UITestMode") {
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
            UserDefaults.standard.set(true, forKey: "snuglo.uitestmode")
        }

        // Faz I-2: SmokeUITests reset path — wipe persisted progress so every run
        //          starts from first-launch state (onboarding visible, no completed levels).
        if args.contains("-uitest-reset-progress") {
            ProgressStore.shared.reset()
            UserDefaults.standard.removeObject(forKey: "hasOnboarded")
            UserDefaults.standard.removeObject(forKey: "snuglo.language.override")
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
