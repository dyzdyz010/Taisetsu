import Foundation
import LifeTimerCore

enum CalendarExportError: Error, LocalizedError {
    case accessDenied
    case noFutureOccurrence
    case missingIdentifier

    var errorDescription: String? {
        switch self {
        case .accessDenied: "没有日历访问权限"
        case .noFutureOccurrence: "这个纪念日没有可导出的下一次日期"
        case .missingIdentifier: "系统日历没有返回事件标识"
        }
    }
}

@MainActor
struct CalendarExportService {
    let client: CalendarEventClient

    init(client: CalendarEventClient = EventStoreClient()) {
        self.client = client
    }

    func export(
        record: AnniversaryRecord,
        relativeTo referenceDate: Date = .now,
        timeZone: TimeZone = .current
    ) async throws -> String {
        guard try await client.requestAccess() else { throw CalendarExportError.accessDenied }
        let occurrence = try OccurrenceCalculator().calculate(
            for: record,
            relativeTo: referenceDate,
            timeZone: timeZone
        )
        guard let startDate = occurrence.next else { throw CalendarExportError.noFutureOccurrence }
        let endDate =
            Calendar.current.date(
                byAdding: record.isAllDay ? .day : .hour,
                value: 1,
                to: startDate
            ) ?? startDate.addingTimeInterval(record.isAllDay ? 86_400 : 3_600)
        let sourceNote = record.notes.isEmpty ? "来自生命倒计时" : "\(record.notes)\n\n来自生命倒计时"
        return try await client.upsert(
            CalendarEventDraft(
                title: record.title,
                notes: sourceNote,
                startDate: startDate,
                endDate: endDate,
                isAllDay: record.isAllDay
            ),
            existingIdentifier: record.calendarEventIdentifier
        )
    }
}
