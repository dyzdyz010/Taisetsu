import Foundation
import LifeTimerCore
import SwiftUI
import WidgetKit

struct LifeTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> LifeTimerWidgetEntry {
        LifeTimerWidgetEntry(date: .now, snapshot: Self.placeholderSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeTimerWidgetEntry) -> Void) {
        completion(LifeTimerWidgetEntry(date: .now, snapshot: loadSnapshot() ?? Self.placeholderSnapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeTimerWidgetEntry>) -> Void) {
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
                entries: [LifeTimerWidgetEntry(date: now, snapshot: snapshot)],
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
        localeIdentifier: "zh-Hans",
        events: [
            WidgetEventSnapshot(
                id: UUID(),
                title: "生日",
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

struct LifeTimerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfiguration.widgetKind, provider: LifeTimerProvider()) { entry in
            LifeTimerWidgetView(entry: entry)
        }
        .configurationDisplayName("最近纪念日")
        .description("自动显示置顶和离现在最近的纪念日。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
