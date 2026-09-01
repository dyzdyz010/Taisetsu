import SwiftUI
import TaisetsuCore

@main
struct TaisetsuWatchApp: App {
    @State private var receiver = WatchSessionReceiver()
    @State private var router = WatchNotificationRouter()

    var body: some Scene {
        WindowGroup {
            WatchRootView(receiver: receiver, router: router)
                .task {
                    receiver.activate()
                    router.activate()
                }
        }

        WKNotificationScene(
            controller: ReminderNotificationController.self,
            category: AppConfiguration.reminderNotificationCategory
        )
    }
}
