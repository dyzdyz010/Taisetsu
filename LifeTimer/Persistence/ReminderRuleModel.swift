import Foundation
import SwiftData

@Model
final class ReminderRuleModel {
    var id: UUID = UUID()
    var offsetMinutes: Int = 0
    var isEnabled: Bool = true
    var anniversary: AnniversaryModel?

    init(id: UUID = UUID(), offsetMinutes: Int, isEnabled: Bool = true) {
        self.id = id
        self.offsetMinutes = offsetMinutes
        self.isEnabled = isEnabled
    }
}
