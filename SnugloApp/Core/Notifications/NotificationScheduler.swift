import UserNotifications
import Observation

// MARK: — NotificationScheduler
// Faz F: Daily reminder via UNUserNotificationCenter.
//
// Info.plist note: UNUserNotificationCenter does NOT require a plist key.
//   (Unlike camera/photos/contacts, UNAuthorizationStatus is self-contained.)
// UIBackgroundModes "audio" is intentionally omitted (BGM is in-game only).
//
// Usage:
//   1. Call `requestAuthorization()` → user sees system dialog.
//   2. If granted, `reminderEnabled = true` auto-schedules.
//   3. `cancelDaily()` removes pending notification.

@Observable
final class NotificationScheduler {

    // MARK: - Singleton

    static let shared = NotificationScheduler()

    // MARK: - Notification ID

    private let notificationId = "snuglo.daily"

    // MARK: - State

    var reminderEnabled: Bool {
        didSet {
            defaults.set(reminderEnabled, forKey: Keys.enabled)
            if reminderEnabled { scheduleDaily() } else { cancelDaily() }
        }
    }

    var reminderHour: Int {
        didSet {
            defaults.set(reminderHour, forKey: Keys.hour)
            if reminderEnabled { scheduleDaily() }
        }
    }

    var reminderMinute: Int {
        didSet {
            defaults.set(reminderMinute, forKey: Keys.minute)
            if reminderEnabled { scheduleDaily() }
        }
    }

    // MARK: - Private

    private let defaults: UserDefaults

    private enum Keys {
        static let enabled = "snuglo.reminder.enabled"
        static let hour    = "snuglo.reminder.hour"
        static let minute  = "snuglo.reminder.minute"
    }

    // MARK: - Init

    private convenience init() {
        self.init(defaults: .standard)
    }

    /// Testable init — accepts isolated UserDefaults suite.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.reminderEnabled = defaults.bool(forKey: Keys.enabled)
        self.reminderHour    = defaults.object(forKey: Keys.hour)   as? Int ?? 19
        self.reminderMinute  = defaults.object(forKey: Keys.minute) as? Int ?? 0
    }

    // MARK: - Authorization

    /// Requests UNUserNotificationCenter permission.
    /// Returns `true` if granted, `false` if denied or error.
    /// Must be called before setting `reminderEnabled = true`.
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Check current authorization status without prompting.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedule (or reschedule) the daily reminder notification.
    /// Silently no-ops if authorization was not granted.
    func scheduleDaily() {
        let center = UNUserNotificationCenter.current()

        // Remove any stale request first
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])

        let content = UNMutableNotificationContent()
        content.title = "Snuglo 🧩"
        content.body  = "Today's puzzle is waiting for you!"
        content.sound = .default

        var dc = DateComponents()
        dc.hour   = reminderHour
        dc.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                // Authorization may have been revoked — surface in debug only
                #if DEBUG
                print("[NotificationScheduler] Failed to schedule: \(error)")
                #endif
            }
        }
    }

    /// Remove the pending daily reminder.
    func cancelDaily() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
