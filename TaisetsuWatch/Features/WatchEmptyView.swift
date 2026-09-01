import SwiftUI

struct WatchEmptyView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar.badge.plus")
                .font(.title3)
                .foregroundStyle(.tint)
            Text("No important days yet")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Open Taisetsu on iPhone")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }
}
