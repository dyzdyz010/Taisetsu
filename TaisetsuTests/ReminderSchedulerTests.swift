import Foundation
import Testing

@testable import Taisetsu
@testable import TaisetsuCore

struct ReminderSchedulerTests {
    @Test func scheduleIncludesEveryEnabledFutureReminderAndUsesStableIDs() throws {
        let record = AnniversaryRecord(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000111")!,
            title: "生日",
            date: AnniversaryDate(year: 2026, month: 8, day: 10),
            reminders: [
                ReminderSpec(
                    id: UUID(uuidString: "00000000-0000-4000-8000-000000000211")!, offsetMinutes: -1_440),
                ReminderSpec(
                    id: UUID(uuidString: "00000000-0000-4000-8000-000000000212")!, offsetMinutes: -60),
                ReminderSpec(offsetMinutes: -30, isEnabled: false),
            ]
        )
        let schedule = try ReminderScheduler().makeSchedule(
            records: [record],
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        #expect(schedule.map(\.fireDate) == [date("2026-08-09T00:00:00Z"), date("2026-08-09T23:00:00Z")])
        #expect(Set(schedule.map(\.identifier)).count == 2)
        #expect(schedule.allSatisfy { $0.identifier.hasPrefix("taisetsu.") })
    }

    @Test func rollingScheduleIsChronologicalAndCappedAtSixtyFour() throws {
        let records = (0..<80).map { index in
            AnniversaryRecord(
                title: "事件 \(index)",
                date: AnniversaryDate(year: 2026, month: 8, day: 4),
                recurrence: RecurrenceRule(unit: .day, interval: 1),
                reminders: [ReminderSpec(offsetMinutes: 0)]
            )
        }
        let schedule = try ReminderScheduler().makeSchedule(
            records: records,
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        #expect(schedule.count == 64)
        #expect(schedule.map(\.fireDate) == schedule.map(\.fireDate).sorted())
    }

    @Test func notificationBodyUsesTheRequestedLocale() throws {
        let record = AnniversaryRecord(
            title: "Trip",
            date: AnniversaryDate(year: 2026, month: 8, day: 10),
            reminders: [ReminderSpec(offsetMinutes: -2_880)]
        )

        let schedule = try ReminderScheduler().makeSchedule(
            records: [record],
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "en_US")
        )

        #expect(schedule.first?.body == "in 2 days")
    }

    @Test func sameDayReminderUsesConfiguredTime() throws {
        let record = AnniversaryRecord(
            title: "Trip",
            date: AnniversaryDate(year: 2026, month: 8, day: 10),
            isAllDay: true,
            reminders: [ReminderSpec(offsetMinutes: 0, timeOfDayMinutes: 9 * 60 + 30)]
        )

        let schedule = try ReminderScheduler().makeSchedule(
            records: [record],
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        #expect(schedule.first?.fireDate == date("2026-08-10T09:30:00Z"))
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}
