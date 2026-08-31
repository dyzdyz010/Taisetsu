import Foundation
import Testing

@testable import TaisetsuCore

struct WidgetSelectionTests {
    @Test func hiddenEventsAreExcludedAndPinnedEventsLead() throws {
        let hidden = record("隐藏", day: 4, visible: false)
        let nearest = record("最近", day: 5)
        let pinned = record("置顶", day: 20, pinned: true)
        let snapshot = try WidgetSnapshot.make(
            records: [hidden, nearest, pinned],
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "zh-Hans")
        )

        #expect(snapshot.events.map(\.title) == ["置顶", "最近"])
    }

    @Test func smallAndMediumReturnFourEventsWhileLargeReturnsFive() throws {
        let records = (4...10).map { record("\($0)", day: $0) }
        let snapshot = try WidgetSnapshot.make(
            records: records,
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "zh-Hans")
        )
        #expect(snapshot.events(for: .small).map(\.title) == ["4", "5", "6", "7"])
        #expect(snapshot.events(for: .medium).count == 4)
        #expect(snapshot.events(for: .large).count == 5)
    }

    @Test func widgetDeepLinkUsesTaisetsuScheme() {
        let id = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
        let snapshot = WidgetEventSnapshot(
            id: id,
            title: "纪念日",
            targetDate: date("2026-08-04T00:00:00Z"),
            originalDate: date("2026-08-04T00:00:00Z"),
            isAllDay: true,
            displayMode: .countdown,
            categorySymbolName: "calendar",
            categoryColorToken: "blue",
            isPinned: false
        )

        #expect(
            snapshot.deepLink?.absoluteString
                == "taisetsu://anniversary/00000000-0000-4000-8000-000000000001"
        )
    }

    @Test func countdownDayPresentationUsesTargetDate() {
        let referenceDate = date("2026-08-03T00:00:00Z")
        let event = widgetEvent(
            targetDate: date("2026-08-15T00:00:00Z"),
            originalDate: date("2020-01-01T00:00:00Z"),
            displayMode: .countdown
        )

        let presentation = event.dayPresentation(
            relativeTo: referenceDate,
            calendar: utcCalendar()
        )

        #expect(presentation.value == 12)
        #expect(presentation.direction == .countdown)
    }

    @Test func countUpDayPresentationUsesOriginalDate() {
        let referenceDate = date("2026-08-03T00:00:00Z")
        let event = widgetEvent(
            targetDate: date("2027-01-01T00:00:00Z"),
            originalDate: date("2026-07-20T00:00:00Z"),
            displayMode: .countUp
        )

        let presentation = event.dayPresentation(
            relativeTo: referenceDate,
            calendar: utcCalendar()
        )

        #expect(presentation.value == 14)
        #expect(presentation.direction == .countUp)
    }

    @Test func bothDayPresentationUsesCountdownAndClampsPastTargetToZero() {
        let referenceDate = date("2026-08-03T00:00:00Z")
        let event = widgetEvent(
            targetDate: date("2026-08-01T00:00:00Z"),
            originalDate: date("2020-01-01T00:00:00Z"),
            displayMode: .both
        )

        let presentation = event.dayPresentation(
            relativeTo: referenceDate,
            calendar: utcCalendar()
        )

        #expect(presentation.value == 0)
        #expect(presentation.direction == .countdown)
    }

    private func record(
        _ title: String,
        day: Int,
        pinned: Bool = false,
        visible: Bool = true
    ) -> AnniversaryRecord {
        AnniversaryRecord(
            title: title,
            date: AnniversaryDate(year: 2026, month: 8, day: day),
            isPinned: pinned,
            isVisibleInWidget: visible
        )
    }

    private func widgetEvent(
        targetDate: Date,
        originalDate: Date,
        displayMode: DisplayMode
    ) -> WidgetEventSnapshot {
        WidgetEventSnapshot(
            id: UUID(),
            title: "纪念日",
            targetDate: targetDate,
            originalDate: originalDate,
            isAllDay: true,
            displayMode: displayMode,
            categorySymbolName: "calendar",
            categoryColorToken: "blue",
            isPinned: false
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}
