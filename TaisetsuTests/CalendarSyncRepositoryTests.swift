import Foundation
import SwiftData
import TaisetsuCore
import Testing

@testable import Taisetsu

@MainActor
struct CalendarSyncRepositoryTests {
    @Test func settingsAndEntriesRoundTripInMemory() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = CalendarSyncRepository(context: ModelContext(container))
        let settings = CalendarSyncSettings(
            enabled: true,
            scope: .custom(
                categories: [UUID()],
                tags: [UUID()],
                includeUncategorized: true,
                includeUntagged: false
            ),
            horizonYears: 2
        )

        try repository.save(settings: settings)
        let entry = CalendarSyncEntry(
            anniversaryID: UUID(),
            occurrenceKey: "occurrence-key",
            eventIdentifier: "event-id",
            calendarIdentifier: "calendar-id",
            occurrenceDate: Date(timeIntervalSince1970: 100),
            lastSyncedAt: Date(timeIntervalSince1970: 200),
            status: .synced,
            errorMessage: nil
        )
        try repository.upsert(entry: entry)

        #expect(repository.loadSettings() == settings)
        #expect(repository.entries(for: entry.anniversaryID) == [entry])
    }

    @Test func upsertReplacesSameOccurrenceAndDeleteRemovesIt() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = CalendarSyncRepository(context: ModelContext(container))
        let anniversaryID = UUID()
        let first = CalendarSyncEntry(
            anniversaryID: anniversaryID, occurrenceKey: "same", eventIdentifier: "old",
            calendarIdentifier: "calendar", occurrenceDate: .now, lastSyncedAt: .now,
            status: .error, errorMessage: "temporary"
        )
        var replacement = first
        replacement.eventIdentifier = "new"
        replacement.status = .synced
        replacement.errorMessage = nil

        try repository.upsert(entry: first)
        try repository.upsert(entry: replacement)
        #expect(repository.entries(for: anniversaryID) == [replacement])
        try repository.delete(entry: replacement)
        #expect(repository.entries(for: anniversaryID).isEmpty)
    }
}
