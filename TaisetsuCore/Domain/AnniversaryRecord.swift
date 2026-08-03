import Foundation

public struct AnniversaryDate: Codable, Equatable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int
    public var hour: Int
    public var minute: Int
    public var isLeapMonth: Bool

    public init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        isLeapMonth: Bool = false
    ) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.isLeapMonth = isLeapMonth
    }
}

public struct CategoryReference: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let symbolName: String
    public let colorToken: String

    public init(id: UUID, name: String, symbolName: String = "calendar", colorToken: String = "blue") {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorToken = colorToken
    }
}

public struct TagReference: Codable, Equatable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

public struct AnniversaryRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var calendarKind: CalendarKind
    public var date: AnniversaryDate
    public var isAllDay: Bool
    public var recurrence: RecurrenceRule
    public var displayMode: DisplayMode
    public var reminders: [ReminderSpec]
    public var category: CategoryReference?
    public var tags: [TagReference]
    public var isPinned: Bool
    public var isVisibleInWidget: Bool
    public var calendarEventIdentifier: String?

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        calendarKind: CalendarKind = .gregorian,
        date: AnniversaryDate,
        isAllDay: Bool = true,
        recurrence: RecurrenceRule = .none,
        displayMode: DisplayMode = .countdown,
        reminders: [ReminderSpec] = [],
        category: CategoryReference? = nil,
        tags: [TagReference] = [],
        isPinned: Bool = false,
        isVisibleInWidget: Bool = true,
        calendarEventIdentifier: String? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.calendarKind = calendarKind
        self.date = date
        self.isAllDay = isAllDay
        self.recurrence = recurrence
        self.displayMode = displayMode
        self.reminders = reminders
        self.category = category
        self.tags = tags
        self.isPinned = isPinned
        self.isVisibleInWidget = isVisibleInWidget
        self.calendarEventIdentifier = calendarEventIdentifier
    }
}
