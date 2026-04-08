import Foundation
import UserNotifications

final class NotificationService {

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        if status == .authorized { return true }
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func scheduleMorningReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Your new canvas is ready"
        content.body = "See how today's rhythm shaped your art."
        content.sound = .default

        var components = DateComponents()
        components.hour = 8
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_canvas", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
