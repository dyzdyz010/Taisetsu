import Foundation
import Testing

@testable import TaisetsuCore

struct WatchSnapshotTests {
    @Test func listKeepsHiddenEventsWhileComplicationsRespectVisibility() throws {
        let snapshot = try makeSnapshot(
            records: [
                record("隐藏", day: 4, visible: false),
                record("最近", day: 5),
                record("置顶", day: 20, pinned: true),
            ]
        )

        #expect(snapshot.events.map(\.title) == ["置顶", "隐藏", "最近"])
        #expect(snapshot.complicationEvents(for: .circular).map(\.title) == ["置顶"])
        #expect(snapshot.complicationEvents(for: .rectangular).map(\.title) == ["置顶"])
    }

    @Test func lookaheadCarriesFutureOccurrencesForRecurringEvents() throws {
        let snapshot = try makeSnapshot(records: [
            record("生日", day: 10, recurrence: .init(unit: .year, interval: 1))
        ])
        let event = try #require(snapshot.events.first)

        #expect(event.upcomingDates.count == WatchSnapshot.occurrenceLookahead)
        #expect(event.upcomingDates == event.upcomingDates.sorted())
        #expect(event.upcomingDates.first == date("2026-08-10T00:00:00Z"))
        #expect(event.upcomingDates.last == date("2028-08-10T00:00:00Z"))
    }

    @Test func targetDateRollsOverLocallyOnceAnOccurrencePasses() throws {
        let snapshot = try makeSnapshot(records: [
            record("生日", day: 10, recurrence: .init(unit: .year, interval: 1))
        ])
        let event = try #require(snapshot.events.first)

        // The watch advances on its own, without a fresh snapshot from the iPhone.
        #expect(
            event.targetDate(relativeTo: date("2026-08-11T09:00:00Z"), calendar: utcCalendar())
                == date("2027-08-10T00:00:00Z")
        )
        #expect(
            event.dayPresentation(relativeTo: date("2026-08-11T09:00:00Z"), calendar: utcCalendar()).value
                == 364
        )
    }

    @Test func allDayEventStaysOnItsOwnDayUntilMidnight() throws {
        let snapshot = try makeSnapshot(records: [
            record("生日", day: 10, recurrence: .init(unit: .year, interval: 1))
        ])
        let event = try #require(snapshot.events.first)

        let presentation = event.dayPresentation(
            relativeTo: date("2026-08-10T23:59:00Z"),
            calendar: utcCalendar()
        )
        #expect(presentation.value == 0)
        #expect(presentation.direction == .countdown)
    }

    @Test func pastOneTimeEventFallsBackToItsLastOccurrence() throws {
        let snapshot = try makeSnapshot(records: [record("已过", day: 1)])
        let event = try #require(snapshot.events.first)

        #expect(event.upcomingDates.isEmpty)
        #expect(
            event.targetDate(relativeTo: referenceDate, calendar: utcCalendar())
                == date("2026-08-01T00:00:00Z")
        )
    }

    @Test func eventCountIsCappedAtCapacity() throws {
        let records = (1...30).map { record("第\($0)天", day: 1, recurrence: .init(unit: .day, interval: $0)) }
        let snapshot = try makeSnapshot(records: records)

        #expect(snapshot.events.count == WatchSnapshot.eventCapacity)
    }

    @Test func codableRoundTripPreservesContent() throws {
        let snapshot = try makeSnapshot(records: [
            record("生日", day: 10, recurrence: .init(unit: .year, interval: 1))
        ])

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(WatchSnapshot.self, from: encoder.encode(snapshot))

        #expect(decoded == snapshot)
        #expect(decoded.schemaVersion == WatchSnapshot.currentSchemaVersion)
    }

    @Test func progressRunsBetweenTheSurroundingOccurrences() throws {
        let snapshot = try makeSnapshot(
            records: [record("生日", day: 10, recurrence: .init(unit: .year, interval: 1))]
        )
        let event = try #require(snapshot.events.first)

        // Halfway between the 2026 and 2027 occurrences.
        let halfway = try #require(
            event.progress(relativeTo: date("2027-02-08T12:00:00Z"), calendar: utcCalendar()))
        #expect(abs(halfway - 0.5) < 0.01)
    }

    @Test func progressIsAbsentWithoutAnEarlierOccurrenceToMeasureFrom() throws {
        let snapshot = try makeSnapshot(records: [record("一次性", day: 10)])
        let event = try #require(snapshot.events.first)

        #expect(event.progress(relativeTo: referenceDate, calendar: utcCalendar()) == nil)
    }

    @Test func contentDigestIgnoresTheGenerationTimestamp() throws {
        let snapshot = try makeSnapshot(records: [record("生日", day: 10)])
        let later = WatchSnapshot(
            generatedAt: snapshot.generatedAt.addingTimeInterval(7_200),
            timeZoneIdentifier: snapshot.timeZoneIdentifier,
            localeIdentifier: snapshot.localeIdentifier,
            events: snapshot.events
        )

        #expect(later.contentDigest == snapshot.contentDigest)
    }

    @Test func contentDigestChangesWhenTheWearerWouldSeeSomethingDifferent() throws {
        let base = try makeSnapshot(records: [record("生日", day: 10)])
        let renamed = try makeSnapshot(records: [record("忌日", day: 10)])
        let moved = try makeSnapshot(records: [record("生日", day: 11)])

        #expect(renamed.contentDigest != base.contentDigest)
        #expect(moved.contentDigest != base.contentDigest)
    }

    private let referenceDate = ISO8601DateFormatter().date(from: "2026-08-03T00:00:00Z")!

    private func makeSnapshot(records: [AnniversaryRecord]) throws -> WatchSnapshot {
        try WatchSnapshot.make(
            records: records,
            relativeTo: referenceDate,
            timeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "zh-Hans")
        )
    }

    private func record(
        _ title: String,
        day: Int,
        pinned: Bool = false,
        visible: Bool = true,
        recurrence: RecurrenceRule = .none
    ) -> AnniversaryRecord {
        AnniversaryRecord(
            title: title,
            date: AnniversaryDate(year: 2026, month: 8, day: day),
            recurrence: recurrence,
            isPinned: pinned,
            isVisibleInWidget: visible
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}
