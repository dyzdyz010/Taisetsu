import SwiftUI
import TaisetsuCore

struct WatchRootView: View {
    let receiver: WatchSessionReceiver
    @State private var selection: UUID?

    var body: some View {
        Group {
            if events.isEmpty {
                WatchEmptyView()
            } else {
                WatchHomeView(events: events, selection: $selection)
            }
        }
        .onOpenURL(perform: open)
    }

    private var events: [WatchEventSnapshot] { receiver.snapshot?.events ?? [] }

    /// Complications deep link with `taisetsu://anniversary/<id>`.
    private func open(_ url: URL) {
        guard url.scheme == "taisetsu", url.host == "anniversary" else { return }
        guard let id = UUID(uuidString: url.lastPathComponent) else { return }
        guard events.contains(where: { $0.id == id }) else { return }
        selection = id
    }
}
