import Foundation
import SwiftUI
import TaisetsuCore
import WidgetKit

struct TaisetsuProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaisetsuWidgetEntry {
        TaisetsuWidgetEntry(date: .now, snapshot: Self.placeholderSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaisetsuWidgetEntry) -> Void) {
        completion(TaisetsuWidgetEntry(date: .now, snapshot: loadSnapshot() ?? Self.placeholderSnapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaisetsuWidgetEntry>) -> Void) {
        let now = Date.now
        let snapshot =
            loadSnapshot()
            ?? WidgetSnapshot(
                generatedAt: now,
                timeZoneIdentifier: TimeZone.current.identifier,
                localeIdentifier: Locale.current.identifier,
                events: []
            )
        let nextRefresh =
            Calendar.current.nextDate(
                after: now,
                matching: DateComponents(hour: 0, minute: 1),
                matchingPolicy: .nextTime
            ) ?? now.addingTimeInterval(3_600)
        completion(
            Timeline(
                entries: [TaisetsuWidgetEntry(date: now, snapshot: snapshot)],
                policy: .after(nextRefresh)
            )
        )
    }

    private func loadSnapshot() -> WidgetSnapshot? {
        guard
            let directory = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppConfiguration.appGroupIdentifier
            )
        else { return nil }
        let url = directory.appending(path: "upcoming-events.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(WidgetSnapshot.self, from: data),
            snapshot.schemaVersion == WidgetSnapshot.currentSchemaVersion
        else { return nil }
        return snapshot
    }

    private static let placeholderSnapshot = WidgetSnapshot(
        generatedAt: .now,
        timeZoneIdentifier: TimeZone.current.identifier,
        localeIdentifier: Locale.current.identifier,
        events: [
            WidgetEventSnapshot(
                id: UUID(),
                title: "Birthday",
                targetDate: Calendar.current.date(byAdding: .day, value: 12, to: .now)!,
                originalDate: Calendar.current.date(byAdding: .year, value: -20, to: .now)!,
                isAllDay: true,
                displayMode: .countdown,
                categorySymbolName: "birthday.cake",
                categoryColorToken: "purple",
                isPinned: true
            )
        ]
    )
}

struct TaisetsuWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfiguration.widgetKind, provider: TaisetsuProvider()) { entry in
            TaisetsuWidgetView(entry: entry)
        }
        .configurationDisplayName("Taisetsu — Important Days")
        .description("Shows pinned and nearest important days automatically.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
