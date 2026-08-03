import Foundation

public struct ReminderSpec: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let offsetMinutes: Int
    public let isEnabled: Bool

    public init(id: UUID = UUID(), offsetMinutes: Int, isEnabled: Bool = true) {
        self.id = id
        self.offsetMinutes = offsetMinutes
        self.isEnabled = isEnabled
    }
}
