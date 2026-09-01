import SwiftUI
import TaisetsuCore

@main
struct TaisetsuWatchApp: App {
    @State private var receiver = WatchSessionReceiver()

    var body: some Scene {
        WindowGroup {
            WatchRootView(receiver: receiver)
                .task { receiver.activate() }
        }

        WKNotificationScene(
            controller: ReminderNotificationController.self,
            category: AppConfiguration.reminderNotificationCategory
        )
    }
}
