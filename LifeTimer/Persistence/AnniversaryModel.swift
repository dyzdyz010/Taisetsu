import Foundation
import SwiftData

@Model
final class AnniversaryModel {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var calendarKindRaw: String = "gregorian"
    var year: Int = 2001
    var month: Int = 1
    var day: Int = 1
    var hour: Int = 0
    var minute: Int = 0
    var isLeapMonth: Bool = false
    var isAllDay: Bool = true
    var recurrenceUnitRaw: String?
    var recurrenceInterval: Int = 1
    var displayModeRaw: String = "countdown"
    var isPinned: Bool = false
    var isVisibleInWidget: Bool = true
    var calendarEventIdentifier: String?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var category: CategoryModel?
    @Relationship(deleteRule: .nullify, inverse: \TagModel.anniversaries) var tags: [TagModel]?
    @Relationship(deleteRule: .cascade, inverse: \ReminderRuleModel.anniversary) var reminders:
        [ReminderRuleModel]?

    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}
