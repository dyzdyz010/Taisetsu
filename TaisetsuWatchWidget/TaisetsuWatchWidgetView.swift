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
                Text(event.title) + Text(verbatim: " ") + Text(relativeLabel(event))
            } else {
                Text("No important days yet")
            }
        }
    }

    private var rectangularView: some View {
        Group {
            if let event = events.first {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: event.categorySymbolName)
                        Text(event.title)
                            .lineLimit(1)
                    }
                    .font(.headline)
                    .widgetAccentable()

                    Text(relativeLabel(event))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let target = event.targetDate(relativeTo: entry.date, calendar: .current) {
                        Text(target, format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text("No important days yet")
                        .font(.headline)
                    Text("Open Taisetsu on iPhone")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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

    /// A bare number answers "12 what?" with nothing. Each locale places the count differently, so
    /// the whole phrase is translated rather than a number glued to a unit.
    private func relativeLabel(_ event: WatchEventSnapshot) -> String {
        let presentation = event.dayPresentation(relativeTo: entry.date, calendar: .current)
        switch presentation.direction {
        case .countUp:
            return String(localized: "\(presentation.value) days so far")
        case .countdown:
            return presentation.value == 0
                ? String(localized: "Today")
                : String(localized: "in \(presentation.value) days")
        }
    }
}
