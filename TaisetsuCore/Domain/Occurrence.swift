import Foundation

public enum OccurrenceState: String, Codable, Sendable {
    case upcoming
    case ongoing
    case ended
}

public struct Occurrence: Equatable, Sendable {
    public let original: Date
    public let previous: Date?
    public let next: Date?
    public let elapsed: DateComponents?
    public let remaining: DateComponents?
    public let state: OccurrenceState

    public init(
        original: Date,
        previous: Date?,
        next: Date?,
        elapsed: DateComponents?,
        remaining: DateComponents?,
        state: OccurrenceState
    ) {
        self.original = original
        self.previous = previous
        self.next = next
        self.elapsed = elapsed
        self.remaining = remaining
        self.state = state
    }
}

public enum OccurrenceCalculationError: Error, Equatable {
    case invalidDate
}
