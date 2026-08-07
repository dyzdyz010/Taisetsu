import Foundation
import SwiftData
import TaisetsuCore
import Testing

@testable import Taisetsu

@MainActor
struct CalendarAutoSyncServiceTests {
    @Test func reconcileCreatesBoundedEventsAndIsIdempotent() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = CalendarSyncRepository(context: ModelContext(container))
        let client = CalendarSyncClientSpy()
        let service = CalendarAutoSyncService(client: client, repository: repository)
        let record = AnniversaryRecord(
            title: "生日",
            date: AnniversaryDate(year: 2026, month: 8, day: 7),
            recurrence: .init(unit: .day, interval: 1)
        )
        let settings = CalendarSyncSettings(enabled: true, horizonYears: 2)

        let first = try await service.reconcile(
            records: [record], settings: settings,
            now: date("2026-08-07T00:00:00Z"), timeZone: TimeZone(secondsFromGMT: 0)!
        )
        let eventCount = client.upserted.count
        let second = try await service.reconcile(
            records: [record], settings: settings,
            now: date("2026-08-07T00:00:00Z"), timeZone: TimeZone(secondsFromGMT: 0)!
        )

        #expect(first.syncedCount == 128)
        #expect(second.syncedCount == 128)
        #expect(eventCount == 128)
        #expect(client.upserted.count == 128)
        #expect(repository.entries(for: record.id).count == 128)
    }

    @Test func reconcileDeletesEventsThatFallOutOfScope() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = CalendarSyncRepository(context: ModelContext(container))
        let client = CalendarSyncClientSpy()
        let service = CalendarAutoSyncService(client: client, repository: repository)
        let category = CategoryReference(id: UUID(), name: "家庭")
        let record = AnniversaryRecord(
            title: "生日", date: AnniversaryDate(year: 2026, month: 8, day: 7), category: category
        )
        let enabled = CalendarSyncSettings(enabled: true)
        _ = try await service.reconcile(
            records: [record], settings: enabled,
            now: date("2026-08-07T00:00:00Z"), timeZone: TimeZone(secondsFromGMT: 0)!
        )

        let excluded = CalendarSyncSettings(
            enabled: true,
            scope: .custom(categories: [], tags: [UUID()], includeUncategorized: true, includeUntagged: false)
        )
        _ = try await service.reconcile(
            records: [record], settings: excluded,
            now: date("2026-08-07T00:00:00Z"), timeZone: TimeZone(secondsFromGMT: 0)!
        )
        #expect(!client.deleted.isEmpty)
        #expect(repository.entries(for: record.id).isEmpty)
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}

@MainActor
private final class CalendarSyncClientSpy: CalendarEventClient {
    var upserted: [String: CalendarEventDraft] = [:]
    var deleted: [String] = []

    func requestAccess() async throws -> Bool { true }
    func authorizationState() -> CalendarAuthorizationState { .fullAccess }
    func upsert(_ draft: CalendarEventDraft, existingIdentifier: String?) async throws -> String {
        try await upsert(
            draft, calendar: CalendarTarget(identifier: "calendar", title: "Taisetsu"),
            existingIdentifier: existingIdentifier)
    }
    func ensureManagedCalendar() async throws -> CalendarTarget {
        CalendarTarget(identifier: "calendar", title: "Taisetsu")
    }
    func upsert(_ draft: CalendarEventDraft, calendar: CalendarTarget, existingIdentifier: String?)
        async throws -> String
    {
        let identifier = existingIdentifier ?? UUID().uuidString
        upserted[identifier] = draft
        return identifier
    }
    func removeEvent(identifier: String) async throws {
        deleted.append(identifier)
        upserted.removeValue(forKey: identifier)
    }
    func eventExists(identifier: String) -> Bool { upserted[identifier] != nil }
}
