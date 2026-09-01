import Foundation

/// How strongly the Smart Stack should surface Taisetsu, and for how long that judgement holds.
public struct WatchRelevanceWindow: Equatable, Sendable {
    public let score: Double
    public let duration: TimeInterval

    public init(score: Double, duration: TimeInterval) {
        self.score = score
        self.duration = duration
    }
}

public enum WatchRelevance {
    public static let maximumScore: Double = 100
    public static let pinnedBonus: Double = 10
    /// Counting up has no deadline, so it never competes with an imminent countdown.
    public static let countUpScore: Double = 10

    public static func score(
        for event: WatchEventSnapshot,
        relativeTo referenceDate: Date,
        calendar: Calendar
    ) -> Double {
        let presentation = event.dayPresentation(relativeTo: referenceDate, calendar: calendar)
        let base: Double
        switch presentation.direction {
        case .countUp:
            base = countUpScore
        case .countdown:
            switch presentation.value {
            case 0: base = 100
            case 1: base = 80
            case 2...3: base = 60
            case 4...7: base = 40
            case 8...30: base = 20
            default: base = 5
            }
        }
        return min(maximumScore, base + (event.isPinned ? pinnedBonus : 0))
    }

    public static func window(
        for snapshot: WatchSnapshot,
        relativeTo referenceDate: Date,
        calendar: Calendar
    ) -> WatchRelevanceWindow {
        let best =
            snapshot.events
            .filter(\.isVisibleInWidget)
            .map { score(for: $0, relativeTo: referenceDate, calendar: calendar) }
            .max() ?? 0
        return WatchRelevanceWindow(
            score: best,
            duration: secondsUntilNextDay(after: referenceDate, calendar: calendar)
        )
    }

    /// Day buckets only change at midnight, so a window that expires then is both accurate and cheap.
    private static func secondsUntilNextDay(after referenceDate: Date, calendar: Calendar) -> TimeInterval {
        guard
            let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: referenceDate)
            )
        else { return 3_600 }
        return max(60, nextDay.timeIntervalSince(referenceDate))
    }
}
