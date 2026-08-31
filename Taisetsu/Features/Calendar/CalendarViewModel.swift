import Foundation
import Observation
import TaisetsuCore

@MainActor
@Observable
final class CalendarViewModel {
    typealias Build =
        @Sendable (
            [AnniversaryRecord], Date, Calendar, TimeZone
        ) async throws -> CalendarMonthSnapshot

    private let repository: AnniversaryRepository
    private let build: Build
    private var requestID: UUID?

    private(set) var displayedMonth: Date
    private(set) var snapshot: CalendarMonthSnapshot?

    init(
        repository: AnniversaryRepository,
        displayedMonth: Date = Calendar.current.startOfDay(for: .now),
        build: @escaping Build = { records, month, calendar, timeZone in
            let task = Task.detached(priority: .userInitiated) {
                try CalendarMonthBuilder().make(
                    records: records,
                    month: month,
                    calendar: calendar,
                    timeZone: timeZone
                )
            }
            return try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
        }
    ) {
        self.repository = repository
        self.displayedMonth = displayedMonth
        self.build = build
    }

    func moveMonth(_ value: Int, calendar: Calendar) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth)!
    }

    func refresh(calendar: Calendar, timeZone: TimeZone) async {
        let requestedMonth = displayedMonth
        let currentRequestID = UUID()
        requestID = currentRequestID
        let records = repository.fetch()

        do {
            let result = try await build(records, requestedMonth, calendar, timeZone)
            guard
                requestID == currentRequestID,
                calendar.isDate(displayedMonth, equalTo: requestedMonth, toGranularity: .month)
            else { return }
            snapshot = result
        } catch {
            return
        }
    }

    func currentSnapshot(calendar: Calendar) -> CalendarMonthSnapshot? {
        guard let snapshot,
            calendar.isDate(snapshot.month, equalTo: displayedMonth, toGranularity: .month)
        else { return nil }
        return snapshot
    }
}
