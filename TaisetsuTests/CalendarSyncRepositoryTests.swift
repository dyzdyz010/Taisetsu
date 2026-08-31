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
        try repository.replaceEntries(with: [entry])

        #expect(repository.loadSettings() == settings)
        #expect(repository.entries(for: entry.anniversaryID) == [entry])
    }

    @Test func replacementUpdatesSameOccurrenceAndCanRemoveIt() throws {
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

        try repository.replaceEntries(with: [first])
        try repository.replaceEntries(with: [replacement])
        #expect(repository.entries(for: anniversaryID) == [replacement])
        try repository.replaceEntries(with: [])
        #expect(repository.entries(for: anniversaryID).isEmpty)
    }

    @Test func replaceEntriesUpdatesInsertsAndDeletesInOneSnapshot() throws {
        let repository = CalendarSyncRepository(
            context: ModelContext(try ModelContainerFactory.makeInMemory())
        )
        let first = entry(anniversaryID: UUID(), occurrenceKey: "first", eventIdentifier: "old")
        let second = entry(anniversaryID: UUID(), occurrenceKey: "second", eventIdentifier: "second")
        try repository.replaceEntries(with: [first, second])

        var updated = first
        updated.eventIdentifier = "updated"
        let inserted = entry(anniversaryID: UUID(), occurrenceKey: "third", eventIdentifier: "third")
        try repository.replaceEntries(with: [updated, inserted])
        #expect(Set(repository.entries().map(\.eventIdentifier)) == ["updated", "third"])

        try repository.replaceEntries(with: [inserted])
        #expect(repository.entries() == [inserted])
    }

    private func entry(
        anniversaryID: UUID,
        occurrenceKey: String,
        eventIdentifier: String
    ) -> CalendarSyncEntry {
        CalendarSyncEntry(
            anniversaryID: anniversaryID,
            occurrenceKey: occurrenceKey,
            eventIdentifier: eventIdentifier,
            calendarIdentifier: "calendar",
            occurrenceDate: Date(timeIntervalSince1970: 100),
            lastSyncedAt: Date(timeIntervalSince1970: 200),
            status: .synced,
            errorMessage: nil
        )
    }
}
