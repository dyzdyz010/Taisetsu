import SwiftUI
import TaisetsuCore

struct WatchRootView: View {
    let receiver: WatchSessionReceiver
    let router: WatchNotificationRouter
    @State private var selection: UUID?

    var body: some View {
        Group {
            if events.isEmpty {
                WatchEmptyView()
            } else {
                WatchHomeView(events: events, selection: $selection)
            }
        }
        .onOpenURL { select(AnniversaryDeepLink.anniversaryID(from: $0)) }
        .onChange(of: router.requestedAnniversaryID) { _, id in select(id) }
        .onAppear { select(router.requestedAnniversaryID) }
    }

    private var events: [WatchEventSnapshot] { receiver.snapshot?.events ?? [] }

    /// Complications link with `taisetsu://anniversary/<id>`; reminders carry the same id.
    private func select(_ id: UUID?) {
        guard let id else { return }
        if let resolved = receiver.snapshot?.selectableID(id) {
            selection = resolved
        }
        router.clear()
    }
}
