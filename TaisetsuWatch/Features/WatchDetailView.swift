import SwiftUI
import TaisetsuCore

struct WatchDetailView: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.locale) private var locale
    let event: WatchEventSnapshot

    var body: some View {
        VStack(spacing: 2) {
            Label {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } icon: {
                Image(systemName: event.categorySymbolName)
                    .foregroundStyle(accentColor)
            }
            .labelStyle(.titleAndIcon)

            Text(presentation.value, format: .number)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(accentColor)
                .contentTransition(.numericText())

            Text(directionLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let target = event.targetDate(relativeTo: .now, calendar: .current) {
                Text(target, format: .dateTime.year().month().day())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private var presentation: DayPresentation {
        event.dayPresentation(relativeTo: .now, calendar: .current)
    }

    private var directionLabel: String {
        switch presentation.direction {
        case .countdown: String(localized: "days left")
        case .countUp: String(localized: "days so far")
        }
    }

    /// Always-On keeps the layout but drops colour, which is the expensive part of the frame.
    private var accentColor: Color {
        isLuminanceReduced ? .secondary : WatchCategoryStyle.color(for: event.categoryColorToken)
    }
}
