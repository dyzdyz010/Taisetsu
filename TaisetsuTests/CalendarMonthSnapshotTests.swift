import Foundation
import Synchronization
import Testing

@testable import TaisetsuCore

struct CalendarMonthSnapshotTests {
    @Test func builderCalculatesEachRecordOnceAndIndexesEventDays() throws {
        let utc = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        calendar.firstWeekday = 1
        let testCalendar = calendar
        let calls = Mutex(0)
        let builder = CalendarMonthBuilder { record, _, _ in
            calls.withLock { $0 += 1 }
            let eventDate = testCalendar.date(
                from: DateComponents(year: 2026, month: 8, day: record.date.day)
            )!
            return Occurrence(
                original: eventDate,
                previous: nil,
                next: eventDate,
                elapsed: nil,
                remaining: nil,
                state: .upcoming
            )
        }
        let records = [record(day: 5), record(day: 12), record(day: 27)]

        let snapshot = try builder.make(
            records: records,
            month: date("2026-08-01T00:00:00Z"),
            calendar: testCalendar,
            timeZone: utc
        )

        #expect(calls.withLock { $0 } == records.count)
        #expect(snapshot.cells.count == 37)
        #expect(snapshot.events.map(\.record.date.day) == [5, 12, 27])
        #expect(snapshot.hasEvent(on: date("2026-08-12T00:00:00Z"), calendar: testCalendar))
        #expect(!snapshot.hasEvent(on: date("2026-08-13T00:00:00Z"), calendar: testCalendar))
    }

    private func record(day: Int) -> AnniversaryRecord {
        AnniversaryRecord(
            title: "Event \(day)",
            date: AnniversaryDate(year: 2026, month: 8, day: day)
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
