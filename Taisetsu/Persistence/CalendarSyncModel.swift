import Foundation
import SwiftData
import TaisetsuCore

@Model
final class CalendarSyncEntryModel {
    var anniversaryID: UUID = UUID()
    var occurrenceKey: String = ""
    var eventIdentifier: String = ""
    var calendarIdentifier: String = ""
    var occurrenceDate: Date = Date.now
    var lastSyncedAt: Date?
    var statusRaw: String = CalendarSyncEntry.Status.synced.rawValue
    var errorMessage: String?

    init(entry: CalendarSyncEntry) {
        anniversaryID = entry.anniversaryID
        occurrenceKey = entry.occurrenceKey
        eventIdentifier = entry.eventIdentifier
        calendarIdentifier = entry.calendarIdentifier
        occurrenceDate = entry.occurrenceDate
        lastSyncedAt = entry.lastSyncedAt
        statusRaw = entry.status.rawValue
        errorMessage = entry.errorMessage
    }

    func map() -> CalendarSyncEntry {
        CalendarSyncEntry(
            anniversaryID: anniversaryID,
            occurrenceKey: occurrenceKey,
            eventIdentifier: eventIdentifier,
            calendarIdentifier: calendarIdentifier,
            occurrenceDate: occurrenceDate,
            lastSyncedAt: lastSyncedAt,
            status: CalendarSyncEntry.Status(rawValue: statusRaw) ?? .error,
            errorMessage: errorMessage
        )
    }
}

@Model
final class CalendarSyncSettingsModel {
    var id: String = "default"
    var enabled: Bool = false
    var scopeKindRaw: String = "all"
    var categoryIDs: [UUID] = []
    var tagIDs: [UUID] = []
    var includeUncategorized: Bool = false
    var includeUntagged: Bool = false
    var horizonYears: Int = 2
    var deferralCount: Int = 0
    var nextPromptDate: Date?
    var neverRemind: Bool = false
    var lastSuccessfulSync: Date?

    init() {}

    func map() -> CalendarSyncSettings {
        let scope: CalendarSyncScope =
            scopeKindRaw == "custom"
            ? .custom(
                categories: Set(categoryIDs),
                tags: Set(tagIDs),
                includeUncategorized: includeUncategorized,
                includeUntagged: includeUntagged
            )
            : .all
        return CalendarSyncSettings(
            enabled: enabled,
            scope: scope,
            horizonYears: horizonYears,
            backoff: CalendarSyncBackoff(
                deferralCount: deferralCount,
                nextEligibleDate: nextPromptDate,
                isNeverRemind: neverRemind
            ),
            lastSuccessfulSync: lastSuccessfulSync
        )
    }

    func update(from settings: CalendarSyncSettings) {
        enabled = settings.enabled
        horizonYears = settings.horizonYears
        deferralCount = settings.backoff.deferralCount
        nextPromptDate = settings.backoff.nextEligibleDate
        neverRemind = settings.backoff.isNeverRemind
        lastSuccessfulSync = settings.lastSuccessfulSync
        switch settings.scope {
        case .all:
            scopeKindRaw = "all"
            categoryIDs = []
            tagIDs = []
            includeUncategorized = false
            includeUntagged = false
        case .custom(let categories, let tags, let includeUncategorized, let includeUntagged):
            scopeKindRaw = "custom"
            categoryIDs = Array(categories)
            tagIDs = Array(tags)
            self.includeUncategorized = includeUncategorized
            self.includeUntagged = includeUntagged
        }
    }
}
