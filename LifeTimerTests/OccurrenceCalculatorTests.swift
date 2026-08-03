import Foundation
import Testing

@testable import LifeTimerCore

struct OccurrenceCalculatorTests {
    private let calculator = OccurrenceCalculator()
    private let utc = TimeZone(secondsFromGMT: 0)!

    @Test func oneTimeFutureAndPastHaveStableStates() throws {
        let record = fixture(year: 2026, month: 8, day: 10)
        let future = try calculator.calculate(
            for: record, relativeTo: date("2026-08-03T12:00:00Z"), timeZone: utc)
        let past = try calculator.calculate(
            for: record, relativeTo: date("2026-08-11T12:00:00Z"), timeZone: utc)

        #expect(future.state == .upcoming)
        #expect(future.next == date("2026-08-10T00:00:00Z"))
        #expect(past.state == .ended)
        #expect(past.previous == date("2026-08-10T00:00:00Z"))
    }

    @Test func anAllDayEventIsOngoingForItsWholeLocalDay() throws {
        let record = fixture(year: 2026, month: 8, day: 3)
        let result = try calculator.calculate(
            for: record, relativeTo: date("2026-08-03T23:59:00Z"), timeZone: utc)
        #expect(result.state == .ongoing)
        #expect(result.remaining?.day == 0)
    }

    @Test func yearlyLeapDayFallsBackToFebruary28() throws {
        let record = fixture(year: 2024, month: 2, day: 29, recurrence: .init(unit: .year, interval: 1))
        let result = try calculator.calculate(
            for: record, relativeTo: date("2025-02-01T12:00:00Z"), timeZone: utc)
        #expect(result.next == date("2025-02-28T00:00:00Z"))
    }

    @Test func monthlyRecurrenceClampsToMonthEnd() throws {
        let record = fixture(year: 2026, month: 1, day: 31, recurrence: .init(unit: .month, interval: 1))
        let result = try calculator.calculate(
            for: record, relativeTo: date("2026-02-01T00:00:00Z"), timeZone: utc)
        #expect(result.next == date("2026-02-28T00:00:00Z"))
    }

    @Test func everyTwoMonthsRemainsAnchoredToOriginal() throws {
        let record = fixture(year: 2026, month: 1, day: 31, recurrence: .init(unit: .month, interval: 2))
        let result = try calculator.calculate(
            for: record, relativeTo: date("2026-04-01T00:00:00Z"), timeZone: utc)
        #expect(result.previous == date("2026-03-31T00:00:00Z"))
        #expect(result.next == date("2026-05-31T00:00:00Z"))
    }

    @Test func exactTimePreservesWallClockAcrossDST() throws {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let record = fixture(
            year: 2025,
            month: 3,
            day: 9,
            hour: 2,
            minute: 30,
            isAllDay: false,
            recurrence: .init(unit: .year, interval: 1)
        )
        let result = try calculator.calculate(
            for: record,
            relativeTo: date("2025-03-01T00:00:00Z"),
            timeZone: losAngeles
        )
        #expect(result.next == date("2025-03-09T10:30:00Z"))
    }

    @Test func chineseNewYearRepeatsUsingChineseCalendar() throws {
        let record = fixture(
            year: 2026,
            month: 1,
            day: 1,
            calendarKind: .chinese,
            recurrence: .init(unit: .year, interval: 1)
        )
        let result = try calculator.calculate(
            for: record,
            relativeTo: date("2027-01-01T00:00:00Z"),
            timeZone: TimeZone(identifier: "Asia/Shanghai")!
        )
        #expect(result.next == date("2027-02-05T16:00:00Z"))
    }

    private func fixture(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        isAllDay: Bool = true,
        calendarKind: CalendarKind = .gregorian,
        recurrence: RecurrenceRule = .none
    ) -> AnniversaryRecord {
        AnniversaryRecord(
            id: UUID(),
            title: "测试纪念日",
            notes: "",
            calendarKind: calendarKind,
            date: AnniversaryDate(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            ),
            isAllDay: isAllDay,
            recurrence: recurrence
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
