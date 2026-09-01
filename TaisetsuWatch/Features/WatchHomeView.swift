import SwiftUI
import TaisetsuCore

/// One event per screen. The wrist is not the place for the iPhone's information density.
struct WatchHomeView: View {
    let events: [WatchEventSnapshot]
    @Binding var selection: UUID?

    var body: some View {
        TabView(selection: $selection) {
            ForEach(events) { event in
                WatchDetailView(event: event)
                    .tag(Optional(event.id))
            }
        }
        .tabViewStyle(.verticalPage)
    }
}
