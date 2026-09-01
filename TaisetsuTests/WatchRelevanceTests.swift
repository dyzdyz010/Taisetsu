import Foundation
import Testing

@testable import TaisetsuCore

struct WatchRelevanceTests {
    @Test func imminentEventsOutrankDistantOnes() {
        let today = event(daysAway: 0)
        let tomorrow = event(daysAway: 1)
        let nextMonth = event(daysAway: 40)

        #expect(score(today) == WatchRelevance.maximumScore)
        #expect(score(today) > score(tomorrow))
        #expect(score(tomorrow) > score(nextMonth))
    }

    @Test func pinnedEventsOutrankAnIdenticalUnpinnedEvent() {
        #expect(score(event(daysAway: 10, pinned: true)) > score(event(daysAway: 10)))
    }

    @Test func pinningCannotPushTheScorePastTheMaximum() {
        #expect(score(event(daysAway: 0, pinned: true)) == WatchRelevance.maximumScore)
    }

    @Test func countingUpStaysLowPriority() {
        #expect(score(event(daysAway: 0, displayMode: .countUp)) == WatchRelevance.countUpScore)
    }

    @Test func windowUsesTheMostRelevantVisibleEvent() {
        let snapshot = snapshot(events: [event(daysAway: 40), event(daysAway: 0)])

        #expect(
            WatchRelevance.window(for: snapshot, relativeTo: referenceDate, calendar: calendar).score == 100)
    }

    @Test func windowIgnoresEventsHiddenFromComplications() {
        let snapshot = snapshot(events: [event(daysAway: 40), event(daysAway: 0, visible: false)])

        #expect(
            WatchRelevance.window(for: snapshot, relativeTo: referenceDate, calendar: calendar).score == 5)
    }

    @Test func windowExpiresAtTheNextLocalMidnight() {
        let evening = date("2026-08-03T21:00:00Z")
        let window = WatchRelevance.window(
            for: snapshot(events: [event(daysAway: 0)]),
            relativeTo: evening,
            calendar: calendar
        )

        #expect(window.duration == 3 * 3_600)
    }

    @Test func emptySnapshotIsNotRelevant() {
        #expect(
            WatchRelevance.window(for: snapshot(events: []), relativeTo: referenceDate, calendar: calendar)
                .score == 0)
    }

    private let referenceDate = ISO8601DateFormatter().date(from: "2026-08-03T00:00:00Z")!

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func score(_ event: WatchEventSnapshot) -> Double {
        WatchRelevance.score(for: event, relativeTo: referenceDate, calendar: calendar)
    }

    private func snapshot(events: [WatchEventSnapshot]) -> WatchSnapshot {
        WatchSnapshot(
            generatedAt: referenceDate,
            timeZoneIdentifier: "UTC",
            localeIdentifier: "zh-Hans",
            events: events
        )
    }

    private func event(
        daysAway: Int,
        pinned: Bool = false,
        visible: Bool = true,
        displayMode: DisplayMode = .countdown
    ) -> WatchEventSnapshot {
        let target = calendar.date(byAdding: .day, value: daysAway, to: referenceDate)!
        return WatchEventSnapshot(
            id: UUID(),
            title: "纪念日",
            originalDate: referenceDate,
            upcomingDates: [target],
            previousDate: nil,
            isAllDay: true,
            displayMode: displayMode,
            categorySymbolName: "calendar",
            categoryColorToken: "blue",
            isPinned: pinned,
            isVisibleInWidget: visible
        )
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}
