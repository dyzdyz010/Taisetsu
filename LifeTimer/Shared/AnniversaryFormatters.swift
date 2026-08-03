import Foundation
import LifeTimerCore

enum AnniversaryFormatters {
    static func date(_ value: Date, isAllDay: Bool) -> String {
        value.formatted(
            isAllDay
                ? Date.FormatStyle(date: .abbreviated, time: .omitted)
                : Date.FormatStyle(date: .abbreviated, time: .shortened)
        )
    }

    static func relative(_ occurrence: Occurrence, mode: DisplayMode, now: Date = .now) -> String {
        switch mode {
        case .countUp:
            return elapsedText(from: occurrence.original, to: now)
        case .countdown, .both:
            guard let next = occurrence.next else { return elapsedText(from: occurrence.original, to: now) }
            let days =
                Calendar.current.dateComponents(
                    [.day],
                    from: Calendar.current.startOfDay(for: now),
                    to: Calendar.current.startOfDay(for: next)
                ).day ?? 0
            if days == 0 { return "就是今天" }
            return "还有 \(max(0, days)) 天"
        }
    }

    static func recurrence(_ rule: RecurrenceRule) -> String {
        guard let unit = rule.unit else { return "不重复" }
        let unitName: String
        switch unit {
        case .day: unitName = "天"
        case .week: unitName = "周"
        case .month: unitName = "月"
        case .year: unitName = "年"
        }
        return rule.interval == 1 ? "每\(unitName)" : "每 \(rule.interval) \(unitName)"
    }

    private static func elapsedText(from start: Date, to end: Date) -> String {
        let days = max(
            0,
            Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: start),
                to: Calendar.current.startOfDay(for: end)
            ).day ?? 0
        )
        return "已经 \(days) 天"
    }
}
