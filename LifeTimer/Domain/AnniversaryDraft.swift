import Foundation
import LifeTimerCore

struct AnniversaryDraft: Equatable {
    var id: UUID?
    var title = ""
    var notes = ""
    var calendarKind = CalendarKind.gregorian
    var date: AnniversaryDate
    var isAllDay = true
    var recurrenceUnit: RecurrenceRule.Unit?
    var recurrenceInterval = 1
    var displayMode = DisplayMode.countdown
    var reminders: [ReminderSpec] = []
    var categoryID: UUID?
    var tagIDs: Set<UUID> = []
    var isPinned = false
    var isVisibleInWidget = true
    var calendarEventIdentifier: String?

    init(referenceDate: Date = .now, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        date = AnniversaryDate(
            year: components.year ?? 2026,
            month: components.month ?? 1,
            day: components.day ?? 1
        )
    }

    init(record: AnniversaryRecord) {
        id = record.id
        title = record.title
        notes = record.notes
        calendarKind = record.calendarKind
        date = record.date
        isAllDay = record.isAllDay
        recurrenceUnit = record.recurrence.unit
        recurrenceInterval = record.recurrence.interval
        displayMode = record.displayMode
        reminders = record.reminders
        categoryID = record.category?.id
        tagIDs = Set(record.tags.map(\.id))
        isPinned = record.isPinned
        isVisibleInWidget = record.isVisibleInWidget
        calendarEventIdentifier = record.calendarEventIdentifier
    }
}

enum AnniversaryValidationError: Error, Equatable, LocalizedError {
    case emptyTitle
    case invalidRecurrenceInterval

    var errorDescription: String? {
        switch self {
        case .emptyTitle: "请输入纪念日名称"
        case .invalidRecurrenceInterval: "重复间隔必须大于零"
        }
    }
}
