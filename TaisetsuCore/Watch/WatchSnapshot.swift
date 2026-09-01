import Foundation

public struct WatchEventSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let originalDate: Date
    /// Ascending occurrences at or after the moment the snapshot was generated.
    ///
    /// Carrying more than one lets the watch roll over to the next occurrence on its own when the
    /// iPhone is out of range, instead of showing a stale day count until the next sync.
    public let upcomingDates: [Date]
    public let previousDate: Date?
    public let isAllDay: Bool
    public let displayMode: DisplayMode
    public let categorySymbolName: String
    public let categoryColorToken: String
    public let isPinned: Bool
    public let isVisibleInWidget: Bool

    public init(
        id: UUID,
        title: String,
        originalDate: Date,
        upcomingDates: [Date],
        previousDate: Date?,
        isAllDay: Bool,
        displayMode: DisplayMode,
        categorySymbolName: String,
        categoryColorToken: String,
        isPinned: Bool,
        isVisibleInWidget: Bool
    ) {
        self.id = id
        self.title = title
        self.originalDate = originalDate
        self.upcomingDates = upcomingDates
        self.previousDate = previousDate
        self.isAllDay = isAllDay
        self.displayMode = displayMode
        self.categorySymbolName = categorySymbolName
        self.categoryColorToken = categoryColorToken
        self.isPinned = isPinned
        self.isVisibleInWidget = isVisibleInWidget
    }

    public var deepLink: URL? { AnniversaryDeepLink.url(for: id) }

    /// The occurrence this surface should count against, resolved locally so an offline watch
    /// still advances past occurrences it has already stored.
    public func targetDate(relativeTo referenceDate: Date, calendar: Calendar) -> Date? {
        let threshold = isAllDay ? calendar.startOfDay(for: referenceDate) : referenceDate
        let upcoming = upcomingDates.first {
            (isAllDay ? calendar.startOfDay(for: $0) : $0) >= threshold
        }
        return upcoming ?? upcomingDates.last ?? previousDate
    }

    /// How far the current interval has run, for the ring on a circular or corner complication.
    ///
    /// `nil` when there is no earlier occurrence to measure from, such as a one-time event that has
    /// never happened yet; the ring then has no honest starting point and the view shows none.
    public func progress(relativeTo referenceDate: Date, calendar: Calendar) -> Double? {
        guard let target = targetDate(relativeTo: referenceDate, calendar: calendar) else { return nil }
        let earlier = ([previousDate].compactMap { $0 } + upcomingDates).filter { $0 < target }
        guard let start = earlier.max() else { return nil }
        let total = target.timeIntervalSince(start)
        guard total > 0 else { return nil }
        return min(1, max(0, referenceDate.timeIntervalSince(start) / total))
    }

    public func dayPresentation(relativeTo referenceDate: Date, calendar: Calendar) -> DayPresentation {
        DayPresentationCalculator.make(
            displayMode: displayMode,
            originalDate: originalDate,
            targetDate: targetDate(relativeTo: referenceDate, calendar: calendar) ?? originalDate,
            relativeTo: referenceDate,
            calendar: calendar
        )
    }
}

public struct WatchSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    /// Enough to fill the watch app list without bloating a WatchConnectivity payload.
    public static let eventCapacity = 20
    /// Roughly a year of self-sufficiency for a yearly anniversary.
    public static let occurrenceLookahead = 3
    /// Dictionary key both ends of the WatchConnectivity hop agree on.
    public static let payloadKey = "taisetsu.watchSnapshot"

    public let schemaVersion: Int
    public let generatedAt: Date
    public let timeZoneIdentifier: String
    public let localeIdentifier: String
    public let events: [WatchEventSnapshot]

    public init(
        schemaVersion: Int = currentSchemaVersion,
        generatedAt: Date,
        timeZoneIdentifier: String,
        localeIdentifier: String,
        events: [WatchEventSnapshot]
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.localeIdentifier = localeIdentifier
        self.events = events
    }

    /// Events a complication may show.
    ///
    /// The watch app itself lists everything: hiding an event from the home screen widget is about
    /// who can see the phone, not about whether the wearer can open their own watch app.
    /// The id to select, or `nil` when this snapshot has nothing to show for it.
    ///
    /// A link can outlive the day it points at: deleted on the phone, or not yet synced to a watch
    /// that has been out of range. Selecting a missing id would strand the app on a blank page.
    public func selectableID(_ id: UUID?) -> UUID? {
        guard let id, events.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    public func complicationEvents(for family: WatchComplicationFamily) -> [WatchEventSnapshot] {
        Array(events.filter(\.isVisibleInWidget).prefix(family.capacity))
    }

    /// A stable fingerprint of what the watch would actually display.
    ///
    /// `generatedAt` is deliberately excluded: it moves on every reconcile, and hashing it would
    /// make every push look like a change and burn the budgeted complication transfer.
    public var contentDigest: String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        func feed(_ value: String) {
            for byte in value.utf8 {
                hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
            }
            hash = (hash ^ 0x7c) &* 0x0000_0100_0000_01b3
        }
        func feed(_ date: Date?) { feed(date.map { String($0.timeIntervalSince1970) } ?? "-") }

        feed(String(schemaVersion))
        for event in events {
            feed(event.id.uuidString)
            feed(event.title)
            feed(event.originalDate)
            for date in event.upcomingDates { feed(date) }
            feed(event.previousDate)
            feed(String(event.isAllDay))
            feed(event.displayMode.rawValue)
            feed(event.categorySymbolName)
            feed(event.categoryColorToken)
            feed(String(event.isPinned))
            feed(String(event.isVisibleInWidget))
        }
        return String(hash, radix: 16)
    }

    /// Both ends of the WatchConnectivity hop must agree on the wire format.
    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public static func make(
        records: [AnniversaryRecord],
        relativeTo referenceDate: Date,
        timeZone: TimeZone,
        locale: Locale,
        calculator: OccurrenceCalculator = OccurrenceCalculator()
    ) throws -> WatchSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let horizon =
            calendar.date(byAdding: .year, value: 50, to: referenceDate)
            ?? referenceDate.addingTimeInterval(50 * 365 * 86_400)

        let ordered = try AnniversaryOrdering(calculator: calculator).sections(
            records: records,
            relativeTo: referenceDate,
            timeZone: timeZone
        )

        let events = try ordered.all.prefix(eventCapacity).map { presentation in
            let upcoming = try calculator.occurrences(
                for: presentation.record,
                from: referenceDate,
                through: horizon,
                maxCount: occurrenceLookahead,
                timeZone: timeZone
            ).map(\.date)
            return WatchEventSnapshot(
                id: presentation.record.id,
                title: presentation.record.title,
                originalDate: presentation.occurrence.original,
                upcomingDates: upcoming,
                previousDate: presentation.occurrence.previous,
                isAllDay: presentation.record.isAllDay,
                displayMode: presentation.record.displayMode,
                categorySymbolName: presentation.record.category?.symbolName ?? "calendar",
                categoryColorToken: presentation.record.category?.colorToken ?? "blue",
                isPinned: presentation.record.isPinned,
                isVisibleInWidget: presentation.record.isVisibleInWidget
            )
        }

        return WatchSnapshot(
            generatedAt: referenceDate,
            timeZoneIdentifier: timeZone.identifier,
            localeIdentifier: locale.identifier,
            events: Array(events)
        )
    }
}
