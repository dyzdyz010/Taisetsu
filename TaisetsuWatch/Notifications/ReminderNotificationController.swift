import SwiftUI
import TaisetsuCore
import UserNotifications
import WatchKit

/// Custom long-look for a forwarded reminder.
///
/// The wrist is where these reminders are actually read, so they get a real layout rather than the
/// system's default title-and-body stack.
final class ReminderNotificationController: WKUserNotificationHostingController<ReminderNotificationView> {
    private var eventTitle = ""
    private var message = ""

    override var body: ReminderNotificationView {
        ReminderNotificationView(title: eventTitle, message: message)
    }

    override func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        eventTitle = content.title
        message = content.body
    }
}

struct ReminderNotificationView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bell.badge")
                .font(.title3)
                .foregroundStyle(.tint)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }
}
