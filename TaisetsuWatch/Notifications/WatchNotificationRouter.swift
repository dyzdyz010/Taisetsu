import Foundation
import Observation
import TaisetsuCore
import UserNotifications

/// Routes a tapped reminder to the day it is about.
///
/// Without this the notification only launches the app, leaving the wearer on whatever page they
/// last looked at — which reads as the reminder having opened the wrong thing.
@MainActor
@Observable
final class WatchNotificationRouter {
    private(set) var requestedAnniversaryID: UUID?

    private let delegate = NotificationDelegate()

    init() {
        delegate.onOpen = { [weak self] id in
            self?.requestedAnniversaryID = id
        }
    }

    func activate(center: UNUserNotificationCenter = .current()) {
        center.delegate = delegate
    }

    /// Clears the request once a view has acted on it, so returning to the app later does not
    /// silently jump away from wherever the wearer scrolled to.
    func clear() {
        requestedAnniversaryID = nil
    }
}

private final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    /// Assigned once during construction on the main actor, read from notification callbacks.
    var onOpen: (@Sendable @MainActor (UUID) -> Void)?

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard
            let id = AnniversaryDeepLink.anniversaryID(
                fromNotification: response.notification.request.content.userInfo
            )
        else { return }
        let handler = onOpen
        await MainActor.run { handler?(id) }
    }
}
