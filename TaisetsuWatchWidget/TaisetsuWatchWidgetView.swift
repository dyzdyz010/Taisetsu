import Foundation
import SwiftUI
import TaisetsuCore
import WidgetKit

struct TaisetsuWatchWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaisetsuWatchWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular: circularView
            case .accessoryCorner: cornerView
            case .accessoryInline: inlineView
            default: rectangularView
            }
        }
        .containerBackground(.clear, for: .widget)
        .widgetURL(events.first?.deepLink)
    }

    private var events: [WatchEventSnapshot] {
        entry.snapshot.complicationEvents(for: complicationFamily)
    }

    private var complicationFamily: WatchComplicationFamily {
        switch family {
        case .accessoryCircular: .circular
        case .accessoryCorner: .corner
        case .accessoryInline: .inline
        default: .rectangular
        }
    }

    private var circularView: some View {
        Group {
            if let event = events.first {
                if let progress = event.progress(relativeTo: entry.date, calendar: .current) {
                    Gauge(value: progress) {
                        Image(systemName: event.categorySymbolName)
                    } currentValueLabel: {
                        dayNumber(event)
                    }
                    .gaugeStyle(.accessoryCircular)
                } else {
                    VStack(spacing: 0) {
                        Image(systemName: event.categorySymbolName)
                            .font(.caption2)
                        dayNumber(event)
                    }
                }
            } else {
                Image(systemName: "calendar")
            }
        }
    }

    private var cornerView: some View {
        Group {
            if let event = events.first {
                dayNumber(event)
                    .widgetLabel(event.title)
            } else {
                Image(systemName: "calendar")
            }
        }
    }

    private var inlineView: some View {
        Group {
            if let event = events.first {
                // Composed rather than interpolated: an interpolated key would be pure
                // placeholders, which no locale can translate differently from English.
                Text(event.title) + Text(verbatim: " ") + Text(dayValue(event), format: .number)
            } else {
                Text("No important days yet")
            }
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 1) {
            if events.isEmpty {
                Text("No important days yet")
                    .font(.headline)
                Text("Open Taisetsu on iPhone")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(events) { event in
                    HStack(spacing: 4) {
                        Image(systemName: event.categorySymbolName)
                            .font(.caption2)
                        Text(event.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        dayNumber(event)
                            .font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dayNumber(_ event: WatchEventSnapshot) -> some View {
        Text(dayValue(event), format: .number)
            .monospacedDigit()
            .minimumScaleFactor(0.6)
            .lineLimit(1)
    }

    private func dayValue(_ event: WatchEventSnapshot) -> Int {
        event.dayPresentation(relativeTo: entry.date, calendar: .current).value
    }
}
