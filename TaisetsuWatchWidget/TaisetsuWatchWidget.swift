import Foundation
import SwiftUI
import TaisetsuCore
import WidgetKit

struct TaisetsuWatchProvider: TimelineProvider {
    /// One entry per day, so the day count advances without ever waking the extension.
    private static let entryCount = 8

    func placeholder(in _: Context) -> TaisetsuWatchWidgetEntry {
        TaisetsuWatchWidgetEntry(date: .now, snapshot: Self.placeholderSnapshot)
    }

    func getSnapshot(in _: Context, completion: @escaping (TaisetsuWatchWidgetEntry) -> Void) {
        completion(TaisetsuWatchWidgetEntry(date: .now, snapshot: loadSnapshot() ?? Self.placeholderSnapshot))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<TaisetsuWatchWidgetEntry>) -> Void) {
        let snapshot = loadSnapshot() ?? Self.emptySnapshot
        let calendar = Calendar.current
        var entries: [TaisetsuWatchWidgetEntry] = []
        var cursor = Date.now

        for index in 0..<Self.entryCount {
            let window = WatchRelevance.window(for: snapshot, relativeTo: cursor, calendar: calendar)
            entries.append(
                TaisetsuWatchWidgetEntry(
                    date: cursor,
                    snapshot: snapshot,
                    relevance: TimelineEntryRelevance(
                        score: Float(window.score),
                        duration: window.duration
                    )
                )
            )
            guard
                index < Self.entryCount - 1,
                let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: cursor))
            else { break }
            cursor = nextDay.addingTimeInterval(60)
        }

        completion(Timeline(entries: entries, policy: .after(cursor)))
    }

    private func loadSnapshot() -> WatchSnapshot? {
        try? WatchSnapshotStore()?.read()
    }

    private static var emptySnapshot: WatchSnapshot {
        WatchSnapshot(
            generatedAt: .now,
            timeZoneIdentifier: TimeZone.current.identifier,
            localeIdentifier: Locale.current.identifier,
            events: []
        )
    }

    private static var placeholderSnapshot: WatchSnapshot {
        WatchSnapshot(
            generatedAt: .now,
            timeZoneIdentifier: TimeZone.current.identifier,
            localeIdentifier: Locale.current.identifier,
            events: [
                WatchEventSnapshot(
                    id: UUID(),
                    title: String(localized: "Birthday"),
                    originalDate: Calendar.current.date(byAdding: .year, value: -20, to: .now)!,
                    upcomingDates: [Calendar.current.date(byAdding: .day, value: 12, to: .now)!],
                    previousDate: Calendar.current.date(byAdding: .day, value: -353, to: .now),
                    isAllDay: true,
                    displayMode: .countdown,
                    categorySymbolName: "birthday.cake",
                    categoryColorToken: "purple",
                    isPinned: true,
                    isVisibleInWidget: true
                )
            ]
        )
    }
}

struct TaisetsuWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfiguration.watchWidgetKind, provider: TaisetsuWatchProvider()) {
            entry in
            TaisetsuWatchWidgetView(entry: entry)
        }
        .configurationDisplayName("Taisetsu — Important Days")
        .description("Shows pinned and nearest important days automatically.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular,
        ])
    }
}
