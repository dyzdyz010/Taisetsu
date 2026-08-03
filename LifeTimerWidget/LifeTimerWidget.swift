import LifeTimerCore
import SwiftUI
import WidgetKit

private struct LifeTimerEntry: TimelineEntry {
    let date: Date
}

private struct LifeTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> LifeTimerEntry {
        LifeTimerEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeTimerEntry) -> Void) {
        completion(LifeTimerEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeTimerEntry>) -> Void) {
        completion(
            Timeline(entries: [LifeTimerEntry(date: .now)], policy: .after(.now.addingTimeInterval(3600))))
    }
}

struct LifeTimerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfiguration.widgetKind, provider: LifeTimerProvider()) { _ in
            Text("生命倒计时")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("最近纪念日")
        .description("查看离现在最近的纪念日。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
