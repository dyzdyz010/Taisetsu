import Foundation

public struct CalendarSyncSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var scope: CalendarSyncScope
    public var horizonYears: Int
    public var backoff: CalendarSyncBackoff
    public var lastSuccessfulSync: Date?

    public init(
        enabled: Bool = false,
        scope: CalendarSyncScope = .all,
        horizonYears: Int = 2,
        backoff: CalendarSyncBackoff = CalendarSyncBackoff(),
        lastSuccessfulSync: Date? = nil
    ) {
        self.enabled = enabled
        self.scope = scope
        self.horizonYears = max(1, horizonYears)
        self.backoff = backoff
        self.lastSuccessfulSync = lastSuccessfulSync
    }
}

public struct CalendarSyncEntry: Codable, Equatable, Identifiable, Sendable {
    public enum Status: String, Codable, Sendable {
        case synced
        case error
    }

    public var id: String { "\(anniversaryID.uuidString):\(occurrenceKey)" }
    public let anniversaryID: UUID
    public let occurrenceKey: String
    public var eventIdentifier: String
    public var calendarIdentifier: String
    public var occurrenceDate: Date
    public var lastSyncedAt: Date?
    public var status: Status
    public var errorMessage: String?

    public init(
        anniversaryID: UUID,
        occurrenceKey: String,
        eventIdentifier: String,
        calendarIdentifier: String,
        occurrenceDate: Date,
        lastSyncedAt: Date?,
        status: Status,
        errorMessage: String?
    ) {
        self.anniversaryID = anniversaryID
        self.occurrenceKey = occurrenceKey
        self.eventIdentifier = eventIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.occurrenceDate = occurrenceDate
        self.lastSyncedAt = lastSyncedAt
        self.status = status
        self.errorMessage = errorMessage
    }
}
