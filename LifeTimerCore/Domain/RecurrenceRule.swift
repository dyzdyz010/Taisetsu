public struct RecurrenceRule: Codable, Equatable, Sendable {
    public enum Unit: String, Codable, CaseIterable, Sendable {
        case day
        case week
        case month
        case year
    }

    public static let none = RecurrenceRule(unit: nil, interval: 1)

    public let unit: Unit?
    public let interval: Int

    public init(unit: Unit?, interval: Int) {
        self.unit = unit
        self.interval = max(1, interval)
    }
}
