import Foundation
import SwiftUI
import TaisetsuCore
import WidgetKit

struct TaisetsuWidgetView: View {
    @Environment(\.locale) private var locale
    @Environment(\.widgetFamily) private var family
    let entry: TaisetsuWidgetEntry

    var body: some View {
        Group {
            if events.isEmpty {
                emptyView
            } else if family == .systemSmall {
                smallListView
            } else {
                listView
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(family == .systemSmall ? nil : events.first?.deepLink)
    }

    private var events: [WidgetEventSnapshot] {
        let snapshotFamily: WidgetSnapshotFamily
        switch family {
        case .systemSmall: snapshotFamily = .small
        case .systemMedium: snapshotFamily = .medium
        default: snapshotFamily = .large
        }
        return entry.snapshot.events(for: snapshotFamily)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
                .foregroundStyle(.tint)
            Text("No important days yet")
                .font(.headline)
            Text("Open Taisetsu to add one")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var smallListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                if let deepLink = event.deepLink {
                    Link(destination: deepLink) {
                        smallEventRow(event)
                    }
                    .buttonStyle(.plain)
                } else {
                    smallEventRow(event)
                }
                if index < events.count - 1 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func smallEventRow(_ event: WidgetEventSnapshot) -> some View {
        HStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                Text(event.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(color(event.categoryColorToken))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                if event.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(.secondary)
                        .offset(x: -2, y: -3)
                        .accessibilityLabel("Pinned")
                }
            }
            Spacer(minLength: 2)
            Text(relativeText(event))
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var listView: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 10 : 5) {
            HStack {
                Text("Nearest Important Days").font(.headline)
                Spacer()
                Image(systemName: "hourglass")
                    .foregroundStyle(.tint)
            }
            ForEach(events) { event in
                HStack(spacing: 8) {
                    Image(systemName: event.categorySymbolName)
                        .foregroundStyle(color(event.categoryColorToken))
                        .frame(width: 18)
                    Text(event.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Spacer()
                    Text(relativeText(event))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                if event.id != events.last?.id { Divider() }
            }
            Spacer(minLength: 0)
        }
    }

    private func relativeText(_ event: WidgetEventSnapshot) -> String {
        let calendar = Calendar.current
        switch event.displayMode {
        case .countUp:
            let days =
                calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: event.originalDate),
                    to: calendar.startOfDay(for: entry.date)
                ).day ?? 0
            return relativeDayText(-max(0, days))
        case .countdown, .both:
            let days =
                calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: entry.date),
                    to: calendar.startOfDay(for: event.targetDate)
                ).day ?? 0
            return relativeDayText(max(0, days))
        }
    }

    private func relativeDayText(_ days: Int) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .full
        return formatter.localizedString(from: DateComponents(day: days))
    }

    private func color(_ token: String) -> Color {
        switch token {
        case "orange": .orange
        case "pink": .pink
        case "purple": .purple
        case "green": .green
        case "red": .red
        default: .blue
        }
    }
}
