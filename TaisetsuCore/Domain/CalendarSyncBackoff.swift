import Foundation

public struct CalendarSyncBackoff: Codable, Equatable, Sendable {
    public private(set) var deferralCount: Int
    public private(set) var nextEligibleDate: Date?
    public private(set) var isNeverRemind: Bool

    public init(deferralCount: Int = 0, nextEligibleDate: Date? = nil, isNeverRemind: Bool = false) {
        self.deferralCount = max(0, deferralCount)
        self.nextEligibleDate = nextEligibleDate
        self.isNeverRemind = isNeverRemind
    }

    public func isEligible(at date: Date) -> Bool {
        !isNeverRemind && (nextEligibleDate == nil || date >= nextEligibleDate!)
    }

    public mutating func recordDeferral(at date: Date) {
        guard !isNeverRemind else { return }
        deferralCount += 1
        let delayDays: Int
        if deferralCount <= 7 {
            delayDays = 1 << (deferralCount - 1)
        } else {
            delayDays = 90
        }
        nextEligibleDate = date.addingTimeInterval(TimeInterval(delayDays) * 86_400)
    }

    public mutating func neverRemind() {
        isNeverRemind = true
        nextEligibleDate = nil
    }
}

public struct ScheduledOccurrence: Equatable, Sendable {
    public let sequence: Int
    public let date: Date

    public init(sequence: Int, date: Date) {
        self.sequence = sequence
        self.date = date
    }
}
