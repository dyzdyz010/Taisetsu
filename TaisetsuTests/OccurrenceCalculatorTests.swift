import Foundation
import Testing

@testable import TaisetsuCore

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

    @Test func yearlyLunarAnniversaryKeepsTheSameLunarMonthAndDay() throws {
        let record = fixture(
            year: 1992,
            month: 8,
            day: 4,
            calendarKind: .chinese,
            recurrence: .init(unit: .year, interval: 1)
        )

        let result = try calculator.calculate(
            for: record,
            relativeTo: date("2026-08-03T04:00:00Z"),
            timeZone: TimeZone(identifier: "Asia/Shanghai")!
        )

        #expect(result.next == date("2026-09-13T16:00:00Z"))
    }

    @Test func chineseMonthAtGregorianYearBoundaryMatchesTheExactLunarDay() throws {
        let record = fixture(
            year: 2026,
            month: 11,
            day: 1,
            calendarKind: .chinese
        )
        let result = try calculator.calculate(
            for: record,
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: utc
        )

        #expect(result.original == date("2026-12-09T00:00:00Z"))
        #expect(result.next == date("2026-12-09T00:00:00Z"))
    }

    @Test func chineseLeapMonthAtYearBoundaryUsesTheCompleteLogicalMonth() throws {
        let leapMonth = fixture(
            year: 2033,
            month: 11,
            day: 29,
            isLeapMonth: true,
            calendarKind: .chinese
        )
        let missingLeapMonthFallsBackToOrdinary = fixture(
            year: 2034,
            month: 11,
            day: 1,
            isLeapMonth: true,
            calendarKind: .chinese
        )

        let leapResult = try calculator.calculate(
            for: leapMonth,
            relativeTo: date("2033-01-01T00:00:00Z"),
            timeZone: utc
        )
        let fallbackResult = try calculator.calculate(
            for: missingLeapMonthFallsBackToOrdinary,
            relativeTo: date("2034-01-01T00:00:00Z"),
            timeZone: utc
        )

        #expect(leapResult.original == date("2034-01-19T00:00:00Z"))
        #expect(fallbackResult.original == date("2034-12-11T00:00:00Z"))
    }

    @Test func chineseDuplicateMonthStartKeepsTheFirstOccurrenceInTheAnchorYear() throws {
        let record = fixture(
            year: 2024,
            month: 12,
            day: 30,
            calendarKind: .chinese
        )
        let result = try calculator.calculate(
            for: record,
            relativeTo: date("2024-01-01T00:00:00Z"),
            timeZone: utc
        )

        #expect(result.original == date("2024-02-09T00:00:00Z"))
    }

    @Test func rollingWindowReturnsOnlyBoundedOccurrencesAndHonorsCap() throws {
        let record = fixture(
            year: 2026,
            month: 8,
            day: 1,
            recurrence: .init(unit: .day, interval: 1)
        )
        let result = try calculator.occurrences(
            for: record,
            from: date("2026-08-03T00:00:00Z"),
            through: date("2026-08-10T00:00:00Z"),
            maxCount: 3,
            timeZone: utc
        )

        #expect(result.map(\.sequence) == [2, 3, 4])
        #expect(
            result.map(\.date) == [
                date("2026-08-03T00:00:00Z"),
                date("2026-08-04T00:00:00Z"),
                date("2026-08-05T00:00:00Z"),
            ])
    }

    @Test func rollingWindowIncludesOneTimeDateOnlyWhenItFallsInsideWindow() throws {
        let record = fixture(year: 2026, month: 8, day: 10)
        let result = try calculator.occurrences(
            for: record,
            from: date("2026-08-03T00:00:00Z"),
            through: date("2026-08-10T00:00:00Z"),
            maxCount: 128,
            timeZone: utc
        )

        #expect(result.count == 1)
        #expect(result[0].sequence == 0)
    }

    private func fixture(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        isLeapMonth: Bool = false,
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
                minute: minute,
                isLeapMonth: isLeapMonth
            ),
            isAllDay: isAllDay,
            recurrence: recurrence
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
