import Foundation

public enum WidgetSnapshotFamily: Sendable {
    case small
    case medium
    case large

    public var capacity: Int {
        switch self {
        case .small, .medium: 4
        case .large: 5
        }
    }
}

public enum WidgetDayDirection: Equatable, Sendable {
    case countdown
    case countUp
}

public struct WidgetDayPresentation: Equatable, Sendable {
    public let value: Int
    public let direction: WidgetDayDirection

    public init(value: Int, direction: WidgetDayDirection) {
        self.value = value
        self.direction = direction
    }
}

public struct WidgetEventSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let targetDate: Date
    public let originalDate: Date
    public let isAllDay: Bool
    public let displayMode: DisplayMode
    public let categorySymbolName: String
    public let categoryColorToken: String
    public let isPinned: Bool

    public init(
        id: UUID,
        title: String,
        targetDate: Date,
        originalDate: Date,
        isAllDay: Bool,
        displayMode: DisplayMode,
        categorySymbolName: String,
        categoryColorToken: String,
        isPinned: Bool
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.originalDate = originalDate
        self.isAllDay = isAllDay
        self.displayMode = displayMode
        self.categorySymbolName = categorySymbolName
        self.categoryColorToken = categoryColorToken
        self.isPinned = isPinned
    }

    public var deepLink: URL? { URL(string: "taisetsu://anniversary/\(id.uuidString)") }

    public func dayPresentation(
        relativeTo referenceDate: Date,
        calendar: Calendar
    ) -> WidgetDayPresentation {
        switch displayMode {
        case .countUp:
            let days =
                calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: originalDate),
                    to: calendar.startOfDay(for: referenceDate)
                ).day ?? 0
            return WidgetDayPresentation(value: max(0, days), direction: .countUp)
        case .countdown, .both:
            let days =
                calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: referenceDate),
                    to: calendar.startOfDay(for: targetDate)
                ).day ?? 0
            return WidgetDayPresentation(value: max(0, days), direction: .countdown)
        }
    }
}

public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let generatedAt: Date
    public let timeZoneIdentifier: String
    public let localeIdentifier: String
    public let events: [WidgetEventSnapshot]

    public init(
        schemaVersion: Int = currentSchemaVersion,
        generatedAt: Date,
        timeZoneIdentifier: String,
        localeIdentifier: String,
        events: [WidgetEventSnapshot]
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.localeIdentifier = localeIdentifier
        self.events = events
    }

    public func events(for family: WidgetSnapshotFamily) -> [WidgetEventSnapshot] {
        Array(events.prefix(family.capacity))
    }

    public static func make(
        records: [AnniversaryRecord],
        relativeTo referenceDate: Date,
        timeZone: TimeZone,
        locale: Locale
    ) throws -> WidgetSnapshot {
        let visible = records.filter(\.isVisibleInWidget)
        let ordered = try AnniversaryOrdering().sections(
            records: visible,
            relativeTo: referenceDate,
            timeZone: timeZone
        )
        let events: [WidgetEventSnapshot] = ordered.all.prefix(WidgetSnapshotFamily.large.capacity).compactMap
        {
            presentation in
            let target = presentation.occurrence.next ?? presentation.occurrence.previous
            guard let target else { return nil }
            return WidgetEventSnapshot(
                id: presentation.record.id,
                title: presentation.record.title,
                targetDate: target,
                originalDate: presentation.occurrence.original,
                isAllDay: presentation.record.isAllDay,
                displayMode: presentation.record.displayMode,
                categorySymbolName: presentation.record.category?.symbolName ?? "calendar",
                categoryColorToken: presentation.record.category?.colorToken ?? "blue",
                isPinned: presentation.record.isPinned
            )
        }
        return WidgetSnapshot(
            generatedAt: referenceDate,
            timeZoneIdentifier: timeZone.identifier,
            localeIdentifier: locale.identifier,
            events: events
        )
    }
}
