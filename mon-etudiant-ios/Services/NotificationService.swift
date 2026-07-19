import UserNotifications
import Foundation

enum NotificationService {

    // MARK: - Permission

    /// Returns true if notifications are (or become) authorized.
    static func requestPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default: return false
        }
    }

    // MARK: - Schedule

    /// Schedules (or reschedules) a notification for `assignment`.
    /// - Cancels existing notification first.
    /// - Does nothing (and returns true) when `reminderType == 0`.
    /// - Returns false if permission was denied by the user.
    @discardableResult
    static func schedule(for assignment: Assignment) async -> Bool {
        guard assignment.reminderType != 0 else {
            cancel(for: assignment)
            return true
        }

        let authorized = await requestPermissionIfNeeded()
        guard authorized else { return false }

        // Generate a stable ID if somehow empty (e.g. migrated data from T1)
        if assignment.notificationID.isEmpty {
            assignment.notificationID = UUID().uuidString
        }

        cancel(for: assignment) // remove stale request before scheduling new one

        guard let fireDate = fireDate(for: assignment), fireDate > Date() else {
            return true  // due date already passed — nothing to schedule
        }

        let content = UNMutableNotificationContent()
        let subjectName = assignment.subject?.name ?? "Matière"

        // Exact texts from Design/CHARTE.md §3.2
        switch assignment.reminderType {
        case 1:
            content.title = "\(subjectName) — demain"
            content.body  = "« \(assignment.title) » est à rendre demain. Un petit coup d'œil ce soir ?"
        default:
            content.title = "À rendre aujourd'hui"
            content.body  = "« \(assignment.title) » (\(subjectName)). Tu y es presque."
        }
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: assignment.notificationID,
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
        return true
    }

    // MARK: - Cancel

    static func cancel(for assignment: Assignment) {
        guard !assignment.notificationID.isEmpty else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [assignment.notificationID])
    }

    // MARK: - Private

    private static func fireDate(for assignment: Assignment) -> Date? {
        let cal = Calendar.current
        let dueDay = cal.startOfDay(for: assignment.dueDate)
        switch assignment.reminderType {
        case 1: // La veille à 18:00
            return cal.date(byAdding: .day, value: -1, to: dueDay)
                .flatMap { cal.date(bySettingHour: 18, minute: 0, second: 0, of: $0) }
        case 2: // Le jour J à 07:00
            return cal.date(bySettingHour: 7, minute: 0, second: 0, of: dueDay)
        default:
            return nil
        }
    }
}
