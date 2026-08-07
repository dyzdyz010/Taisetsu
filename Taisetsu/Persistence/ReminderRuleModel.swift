import Foundation
import SwiftData

@Model
final class ReminderRuleModel {
    var id: UUID = UUID()
    var offsetMinutes: Int = 0
    var timeOfDayMinutes: Int?
    var isEnabled: Bool = true
    var anniversary: AnniversaryModel?

    init(
        id: UUID = UUID(),
        offsetMinutes: Int,
        timeOfDayMinutes: Int? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.offsetMinutes = offsetMinutes
        self.timeOfDayMinutes = timeOfDayMinutes
        self.isEnabled = isEnabled
    }
}
