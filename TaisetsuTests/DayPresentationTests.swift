import Foundation
import Testing

@testable import TaisetsuCore

struct DayPresentationTests {
    @Test func countdownMeasuresWholeDaysToTheTarget() {
        let presentation = make(displayMode: .countdown, reference: "2026-08-03T23:00:00Z")

        #expect(presentation == DayPresentation(value: 12, direction: .countdown))
    }

    @Test func bothBehavesLikeCountdown() {
        #expect(
            make(displayMode: .both, reference: "2026-08-03T00:00:00Z")
                == make(displayMode: .countdown, reference: "2026-08-03T00:00:00Z")
        )
    }

    @Test func countUpMeasuresWholeDaysSinceTheOriginalDate() {
        let presentation = make(displayMode: .countUp, reference: "2026-08-03T00:00:00Z")

        #expect(presentation == DayPresentation(value: 945, direction: .countUp))
    }

    @Test func passedTargetsClampToZeroInsteadOfGoingNegative() {
        let presentation = make(displayMode: .countdown, reference: "2026-09-01T00:00:00Z")

        #expect(presentation == DayPresentation(value: 0, direction: .countdown))
    }

    @Test func widgetAndWatchSurfacesAgreeOnTheSameDates() {
        let reference = date("2026-08-03T12:00:00Z")
        let widgetEvent = WidgetEventSnapshot(
            id: UUID(),
            title: "纪念日",
            targetDate: date("2026-08-15T00:00:00Z"),
            originalDate: date("2024-01-01T00:00:00Z"),
            isAllDay: true,
            displayMode: .countdown,
            categorySymbolName: "calendar",
            categoryColorToken: "blue",
            isPinned: false
        )
        let watchEvent = WatchEventSnapshot(
            id: widgetEvent.id,
            title: widgetEvent.title,
            originalDate: widgetEvent.originalDate,
            upcomingDates: [widgetEvent.targetDate],
            previousDate: nil,
            isAllDay: true,
            displayMode: widgetEvent.displayMode,
            categorySymbolName: widgetEvent.categorySymbolName,
            categoryColorToken: widgetEvent.categoryColorToken,
            isPinned: false,
            isVisibleInWidget: true
        )

        #expect(
            widgetEvent.dayPresentation(relativeTo: reference, calendar: calendar)
                == watchEvent.dayPresentation(relativeTo: reference, calendar: calendar)
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func make(displayMode: DisplayMode, reference: String) -> DayPresentation {
        DayPresentationCalculator.make(
            displayMode: displayMode,
            originalDate: date("2024-01-01T00:00:00Z"),
            targetDate: date("2026-08-15T00:00:00Z"),
            relativeTo: date(reference),
            calendar: calendar
        )
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}
