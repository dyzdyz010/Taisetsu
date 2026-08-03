import Foundation
import UserNotifications

@MainActor
protocol NotificationCenterClientProtocol {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func replaceLifeTimerRequests(with requests: [ScheduledReminder]) async throws
}

@MainActor
final class NotificationCenterClient: NotificationCenterClientProtocol {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func replaceLifeTimerRequests(with requests: [ScheduledReminder]) async throws {
        let existing = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix("lifetimer.") }
        center.removePendingNotificationRequests(withIdentifiers: existing)
        for item in requests {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            content.userInfo = ["anniversaryID": item.anniversaryID.uuidString]
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: item.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try await center.add(
                UNNotificationRequest(identifier: item.identifier, content: content, trigger: trigger)
            )
        }
    }
}
