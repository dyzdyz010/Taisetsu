import Foundation
import SwiftData
import Testing

@testable import Taisetsu
@testable import TaisetsuCore

@MainActor
struct CalendarViewModelTests {
    @Test func monthMovesImmediatelyAndDiscardsStaleProjection() async throws {
        let repository = AnniversaryRepository(
            context: ModelContext(try ModelContainerFactory.makeInMemory())
        )
        let probe = CalendarBuildProbe()
        let calendar = Self.calendar
        let august = Self.date(year: 2026, month: 8, calendar: calendar)
        let september = Self.date(year: 2026, month: 9, calendar: calendar)
        let viewModel = CalendarViewModel(
            repository: repository,
            displayedMonth: august,
            build: { records, month, calendar, timeZone in
                try await probe.build(
                    records: records,
                    month: month,
                    calendar: calendar,
                    timeZone: timeZone
                )
            }
        )

        let augustRefresh = Task {
            await viewModel.refresh(calendar: calendar, timeZone: calendar.timeZone)
        }
        await probe.waitForRequest(month: august, calendar: calendar)

        viewModel.moveMonth(1, calendar: calendar)
        #expect(calendar.isDate(viewModel.displayedMonth, equalTo: september, toGranularity: .month))

        let septemberRefresh = Task {
            await viewModel.refresh(calendar: calendar, timeZone: calendar.timeZone)
        }
        await probe.waitForRequest(month: september, calendar: calendar)
        await probe.resume(
            month: september,
            snapshot: CalendarMonthSnapshot(
                month: september,
                cells: [september],
                events: [],
                eventDays: []
            ),
            calendar: calendar
        )
        await septemberRefresh.value
        #expect(viewModel.snapshot?.month == september)

        await probe.resume(
            month: august,
            snapshot: CalendarMonthSnapshot(
                month: august,
                cells: [august],
                events: [],
                eventDays: []
            ),
            calendar: calendar
        )
        await augustRefresh.value
        #expect(viewModel.snapshot?.month == september)
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func date(year: Int, month: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }
}

private actor CalendarBuildProbe {
    typealias Continuation = CheckedContinuation<CalendarMonthSnapshot, any Error>

    private var continuations: [CalendarDayKey: Continuation] = [:]

    func build(
        records _: [AnniversaryRecord],
        month: Date,
        calendar: Calendar,
        timeZone _: TimeZone
    ) async throws -> CalendarMonthSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            continuations[CalendarDayKey(date: month, calendar: calendar)] = continuation
        }
    }

    func waitForRequest(month: Date, calendar: Calendar) async {
        let key = CalendarDayKey(date: month, calendar: calendar)
        while continuations[key] == nil {
            await Task.yield()
        }
    }

    func resume(
        month: Date,
        snapshot: CalendarMonthSnapshot,
        calendar: Calendar
    ) {
        continuations.removeValue(forKey: CalendarDayKey(date: month, calendar: calendar))?
            .resume(returning: snapshot)
    }
}
