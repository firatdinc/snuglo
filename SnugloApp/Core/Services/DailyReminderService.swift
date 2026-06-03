import Foundation
import UserNotifications

// MARK: — DailyReminderService
// Opt-in local notification reminding the player that a fresh daily puzzle is
// waiting (and to keep their streak). One repeating notification at a friendly
// local hour. State persists in UserDefaults; toggling requests authorization
// on enable and clears the pending request on disable.

@MainActor
@Observable
final class DailyReminderService {

    static let shared = DailyReminderService()

    /// Hour (local time) the daily reminder fires.
    private static let reminderHour = 19
    private let notifID = "snuglo.daily.reminder"
    private let key     = "snuglo.dailyReminder.enabled"
    private let defaults = UserDefaults.standard

    private(set) var isEnabled: Bool

    private init() {
        isEnabled = defaults.bool(forKey: key)
    }

    /// Toggle the reminder. On enable, requests authorization first; if the user
    /// denies (or has denied before), the toggle reverts to off.
    /// - Returns: the resulting enabled state.
    @discardableResult
    func setEnabled(_ on: Bool) async -> Bool {
        if on {
            guard await requestAuthorization() else {
                isEnabled = false
                defaults.set(false, forKey: key)
                return false
            }
            schedule()
            isEnabled = true
        } else {
            cancel()
            isEnabled = false
        }
        defaults.set(isEnabled, forKey: key)
        return isEnabled
    }

    /// Re-sync on launch: if the user enabled reminders but the OS permission was
    /// later revoked, flip our flag off so the UI stays honest.
    func refreshAuthorizationState() async {
        guard isEnabled else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus != .authorized {
            isEnabled = false
            defaults.set(false, forKey: key)
        }
    }

    // MARK: — Private

    private func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            return false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    private func schedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notifID])

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif.daily.title", comment: "")
        content.body  = NSLocalizedString("notif.daily.body", comment: "")
        content.sound = .default

        var comps = DateComponents()
        comps.hour = Self.reminderHour
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        center.add(UNNotificationRequest(identifier: notifID, content: content, trigger: trigger))
    }

    private func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifID])
    }
}
