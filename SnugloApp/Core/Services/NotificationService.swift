import UserNotifications
import Foundation

// MARK: — NotificationService (Faz F)
//
// Manages daily reminder local push notifications.
// Uses UNCalendarNotificationTrigger with DateComponents so the reminder
// fires at the same clock-time every day regardless of timezone drift.
//
// Key design decisions:
//  • scheduleDaily always removes the existing request first (no ghost reminders).
//  • Permission denied path → silent fail + print log; never crashes.
//  • Identifier is constant — easy to cancel or re-check later.
//  • Implements UNUserNotificationCenterDelegate so foreground banners work.

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    // MARK: — Singleton
    static let shared = NotificationService()

    // MARK: — Constants
    static let dailyIdentifier = "snuglo.daily.reminder"

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    // MARK: — Authorization

    /// Request .alert / .sound / .badge permission.
    /// If already granted or denied, this completes immediately without a dialog.
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("[NotificationService] Permission granted: \(granted)")
        } catch {
            // Permission denied or restricted — log and continue.
            print("[NotificationService] Auth error: \(error)")
        }
    }

    // MARK: — Scheduling

    /// Schedule (or reschedule) a daily reminder at the given time.
    /// Removes any pending request with the same identifier first.
    func scheduleDaily(at time: Date) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyIdentifier])

        let content        = UNMutableNotificationContent()
        content.title      = "Time to Snuglo! 🧩"
        content.body       = "Your daily puzzle is waiting."
        content.sound      = .default

        let comps   = Self.makeComponents(from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.dailyIdentifier,
            content:    content,
            trigger:    trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] Schedule error: \(error)")
            }
        }
    }

    /// Cancel the daily reminder.
    func cancelDaily() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyIdentifier])
    }

    /// Convenience: reschedule when enabled, cancel otherwise.
    /// Call from SettingsView whenever the toggle or time picker changes.
    func reschedule(enabled: Bool, at time: Date) {
        if enabled {
            scheduleDaily(at: time)
        } else {
            cancelDaily()
        }
    }

    // MARK: — Internal helpers (exposed for unit tests)

    /// Extract hour + minute from `date` using the current Calendar.
    /// Pure function — no side effects; safe to test without mocking.
    static func makeComponents(from date: Date) -> DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: date)
    }

    // MARK: — UNUserNotificationCenterDelegate

    /// Show notification banners (with sound) even when app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
