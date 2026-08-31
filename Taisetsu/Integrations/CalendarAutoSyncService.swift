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
        let locale = Locale.current
        let planningTask = Task.detached(priority: .utility) {
            try CalendarSyncPlanBuilder().make(
                records: records,
                settings: settings,
                now: now,
                timeZone: timeZone,
                locale: locale
            )
        }
        let calendar: CalendarTarget
        let plan: CalendarSyncPlan
        do {
            if client.authorizationState() != .fullAccess {
                guard try await client.requestAccess() else { throw CalendarExportError.accessDenied }
            }
            calendar = try await client.ensureManagedCalendar()
            plan = try await planningTask.value
        } catch {
            planningTask.cancel()
            throw error
        }

        let existingEntries = repository.entries()
        var entries = Dictionary(
            existingEntries.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var syncedCount = 0
        var errorCount = 0
        var lastError: String?
        for item in plan.events {
            let old = entries[item.entryKey]
            let legacyIdentifier = old?.eventIdentifier ?? item.legacyEventIdentifier
            let existingIdentifier = legacyIdentifier.flatMap {
                client.eventExists(identifier: $0) ? $0 : nil
            }
            do {
                let identifier = try await client.upsert(
                    item.draft,
                    calendar: calendar,
                    existingIdentifier: existingIdentifier
                )
                entries[item.entryKey] = CalendarSyncEntry(
                    anniversaryID: item.anniversaryID,
                    occurrenceKey: item.occurrenceKey,
                    eventIdentifier: identifier,
                    calendarIdentifier: calendar.identifier,
                    occurrenceDate: item.occurrenceDate,
                    lastSyncedAt: now,
                    status: .synced,
                    errorMessage: nil
                )
                syncedCount += 1
            } catch {
                errorCount += 1
                lastError = error.localizedDescription
            }
        }

        var deletedCount = 0
        for entry in existingEntries where !plan.desiredEntryKeys.contains(entry.id) {
            do { try await client.removeEvent(identifier: entry.eventIdentifier) } catch {}
            entries.removeValue(forKey: entry.id)
            deletedCount += 1
        }
        try repository.replaceEntries(with: Array(entries.values))
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
        }
        try repository.replaceEntries(with: [])
        return CalendarSyncSummary(
            syncedCount: 0, deletedCount: entries.count, errorCount: 0, calendar: nil, lastError: nil)
    }
}
