import Foundation

public enum DayDirection: Equatable, Sendable {
    case countdown
    case countUp
}

public struct DayPresentation: Equatable, Sendable {
    public let value: Int
    public let direction: DayDirection

    public init(value: Int, direction: DayDirection) {
        self.value = value
        self.direction = direction
    }
}

/// Whole-day distance between a reference date and the date a surface should show.
///
/// Home screen widgets, watch complications and the watch app all render this number, so the
/// rounding rule lives here instead of once per surface. The dates themselves still come from
/// `OccurrenceCalculator`.
public enum DayPresentationCalculator {
    public static func make(
        displayMode: DisplayMode,
        originalDate: Date,
        targetDate: Date,
        relativeTo referenceDate: Date,
        calendar: Calendar
    ) -> DayPresentation {
        switch displayMode {
        case .countUp:
            DayPresentation(
                value: max(0, wholeDays(from: originalDate, to: referenceDate, calendar: calendar)),
                direction: .countUp
            )
        case .countdown, .both:
            DayPresentation(
                value: max(0, wholeDays(from: referenceDate, to: targetDate, calendar: calendar)),
                direction: .countdown
            )
        }
    }

    private static func wholeDays(from start: Date, to end: Date, calendar: Calendar) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: end)
        ).day ?? 0
    }
}
