import Foundation
import TaisetsuCore

struct CalendarSyncSummary: Equatable, Sendable {
    let syncedCount: Int
    let deletedCount: Int
    let errorCount: Int
    let calendar: CalendarTarget?
    let lastError: String?
}

@MainActor
final class CalendarAutoSyncService {
    private let client: CalendarEventClient
    private let repository: CalendarSyncRepository
    private let calculator = OccurrenceCalculator()

    init(client: CalendarEventClient, repository: CalendarSyncRepository) {
        self.client = client
        self.repository = repository
    }

    func reconcile(
        records: [AnniversaryRecord],
        settings: CalendarSyncSettings,
        now: Date = .now,
        timeZone: TimeZone = .current
    ) async throws -> CalendarSyncSummary {
        if !settings.enabled {
            return try await removeAllManagedEvents()
        }
        if client.authorizationState() != .fullAccess {
            guard try await client.requestAccess() else { throw CalendarExportError.accessDenied }
        }
        let calendar = try await client.ensureManagedCalendar()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        guard let end = gregorian.date(byAdding: .year, value: settings.horizonYears, to: now) else {
            throw CalendarExportError.noFutureOccurrence
        }

        var desired: [(record: AnniversaryRecord, occurrence: ScheduledOccurrence)] = []
        for record in records
        where settings.scope.includes(
            categoryID: record.category?.id,
            tagIDs: record.tags.map(\.id)
        ) {
            let occurrences = try calculator.occurrences(
                for: record, from: now, through: end, maxCount: 128, timeZone: timeZone)
            desired.append(contentsOf: occurrences.map { (record, $0) })
        }
        desired.sort { $0.occurrence.date < $1.occurrence.date }
        if desired.count > 1_000 { desired = Array(desired.prefix(1_000)) }

        let existing = Dictionary(
            uniqueKeysWithValues: repository.entries().map {
                (entryKey(anniversaryID: $0.anniversaryID, occurrenceKey: $0.occurrenceKey), $0)
            })
        var desiredKeys = Set<String>()
        var syncedCount = 0
        var errorCount = 0
        var lastError: String?
        for item in desired {
            let key = entryKey(anniversaryID: item.record.id, occurrenceKey: String(item.occurrence.sequence))
            desiredKeys.insert(key)
            let old = existing[key]
            let legacyIdentifier = old?.eventIdentifier ?? item.record.calendarEventIdentifier
            let existingIdentifier = legacyIdentifier.flatMap {
                client.eventExists(identifier: $0) ? $0 : nil
            }
            do {
                let identifier = try await client.upsert(
                    draft(for: item.record, occurrence: item.occurrence, timeZone: timeZone),
                    calendar: calendar,
                    existingIdentifier: existingIdentifier
                )
                try repository.upsert(
                    entry: CalendarSyncEntry(
                        anniversaryID: item.record.id,
                        occurrenceKey: String(item.occurrence.sequence),
                        eventIdentifier: identifier,
                        calendarIdentifier: calendar.identifier,
                        occurrenceDate: item.occurrence.date,
                        lastSyncedAt: now,
                        status: .synced,
                        errorMessage: nil
                    ))
                syncedCount += 1
            } catch {
                errorCount += 1
                lastError = error.localizedDescription
                if let old { try? repository.upsert(entry: old) }
            }
        }

        var deletedCount = 0
        for entry in repository.entries()
        where !desiredKeys.contains(
            entryKey(anniversaryID: entry.anniversaryID, occurrenceKey: entry.occurrenceKey)
        ) {
            do { try await client.removeEvent(identifier: entry.eventIdentifier) } catch {}
            try repository.delete(entry: entry)
            deletedCount += 1
        }
        return CalendarSyncSummary(
            syncedCount: syncedCount,
            deletedCount: deletedCount,
            errorCount: errorCount,
            calendar: calendar,
            lastError: lastError
        )
    }

    private func removeAllManagedEvents() async throws -> CalendarSyncSummary {
        let entries = repository.entries()
        for entry in entries {
            try? await client.removeEvent(identifier: entry.eventIdentifier)
            try repository.delete(entry: entry)
        }
        return CalendarSyncSummary(
            syncedCount: 0, deletedCount: entries.count, errorCount: 0, calendar: nil, lastError: nil)
    }

    private func entryKey(anniversaryID: UUID, occurrenceKey: String) -> String {
        "\(anniversaryID.uuidString):\(occurrenceKey)"
    }

    private func draft(for record: AnniversaryRecord, occurrence: ScheduledOccurrence, timeZone: TimeZone)
        -> CalendarEventDraft
    {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let end =
            calendar.date(
                byAdding: record.isAllDay ? .day : .hour,
                value: 1,
                to: occurrence.date
            ) ?? occurrence.date.addingTimeInterval(record.isAllDay ? 86_400 : 3_600)
        let attribution = AppLocalization.string("Created with Taisetsu")
        let notes = record.notes.isEmpty ? attribution : "\(record.notes)\n\n\(attribution)"
        return CalendarEventDraft(
            title: record.title,
            notes: notes,
            startDate: occurrence.date,
            endDate: end,
            isAllDay: record.isAllDay
        )
    }
}
