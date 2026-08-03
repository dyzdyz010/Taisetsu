import Foundation
import LifeTimerCore

enum CalendarExportError: Error, LocalizedError {
    case accessDenied
    case noFutureOccurrence
    case missingIdentifier

    var errorDescription: String? {
        switch self {
        case .accessDenied: AppLocalization.string("Calendar access is not available")
        case .noFutureOccurrence: AppLocalization.string("This important day has no upcoming date to export")
        case .missingIdentifier: AppLocalization.string("Calendar did not return an event identifier")
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
        timeZone: TimeZone = .current,
        locale: Locale = .current
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
        let attribution = AppLocalization.string("Created with Taisetsu", locale: locale)
        let sourceNote = record.notes.isEmpty ? attribution : "\(record.notes)\n\n\(attribution)"
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
