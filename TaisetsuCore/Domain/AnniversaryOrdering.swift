import Foundation

public struct AnniversaryPresentation: Equatable, Identifiable, Sendable {
    public var id: UUID { record.id }
    public let record: AnniversaryRecord
    public let occurrence: Occurrence

    public init(record: AnniversaryRecord, occurrence: Occurrence) {
        self.record = record
        self.occurrence = occurrence
    }
}

public struct AnniversarySections: Equatable, Sendable {
    public let pinned: [AnniversaryPresentation]
    public let upcoming: [AnniversaryPresentation]
    public let ongoing: [AnniversaryPresentation]
    public let ended: [AnniversaryPresentation]

    public init(
        pinned: [AnniversaryPresentation],
        upcoming: [AnniversaryPresentation],
        ongoing: [AnniversaryPresentation],
        ended: [AnniversaryPresentation]
    ) {
        self.pinned = pinned
        self.upcoming = upcoming
        self.ongoing = ongoing
        self.ended = ended
    }

    public var all: [AnniversaryPresentation] { pinned + upcoming + ongoing + ended }
}

public struct AnniversaryOrdering: Sendable {
    private let calculator: OccurrenceCalculator

    public init(calculator: OccurrenceCalculator = OccurrenceCalculator()) {
        self.calculator = calculator
    }

    public func sections(
        records: [AnniversaryRecord],
        relativeTo referenceDate: Date,
        timeZone: TimeZone
    ) throws -> AnniversarySections {
        let presentations = try records.map {
            AnniversaryPresentation(
                record: $0,
                occurrence: try calculator.calculate(for: $0, relativeTo: referenceDate, timeZone: timeZone)
            )
        }
        let pinned = presentations.filter(\.record.isPinned).sorted(by: upcomingFirst)
        let unpinned = presentations.filter { !$0.record.isPinned }
        let ongoing = unpinned.filter { presentation in
            presentation.occurrence.state == .ongoing
                || (presentation.record.displayMode == .countUp && presentation.occurrence.elapsed != nil)
        }
        let ongoingIDs = Set(ongoing.map(\.id))
        let upcoming = unpinned.filter {
            !ongoingIDs.contains($0.id) && $0.occurrence.state == .upcoming
        }
        let ended = unpinned.filter {
            !ongoingIDs.contains($0.id) && $0.occurrence.state == .ended
        }
        return AnniversarySections(
            pinned: pinned,
            upcoming: upcoming.sorted(by: upcomingFirst),
            ongoing: ongoing.sorted(by: mostRecentFirst),
            ended: ended.sorted(by: mostRecentFirst)
        )
    }

    private func upcomingFirst(_ lhs: AnniversaryPresentation, _ rhs: AnniversaryPresentation) -> Bool {
        switch (lhs.occurrence.next, rhs.occurrence.next) {
        case (let left?, let right?) where left != right: return left < right
        case (_?, nil): return true
        case (nil, _?): return false
        default: return tieBreak(lhs, rhs)
        }
    }

    private func mostRecentFirst(_ lhs: AnniversaryPresentation, _ rhs: AnniversaryPresentation) -> Bool {
        let left = lhs.occurrence.previous ?? lhs.occurrence.original
        let right = rhs.occurrence.previous ?? rhs.occurrence.original
        return left == right ? tieBreak(lhs, rhs) : left > right
    }

    private func tieBreak(_ lhs: AnniversaryPresentation, _ rhs: AnniversaryPresentation) -> Bool {
        if lhs.record.title != rhs.record.title { return lhs.record.title < rhs.record.title }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
