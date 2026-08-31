import Foundation
import Synchronization

struct ChineseCalendarYearKey: Hashable, Sendable {
    let gregorianYear: Int
    let timeZoneIdentifier: String
}

struct ChineseCalendarMonthKey: Hashable, Sendable {
    let month: Int
    let isLeapMonth: Bool
}

struct ChineseCalendarYearIndex: Equatable, Sendable {
    let months: [ChineseCalendarMonthKey: [Date]]
}

final class ChineseCalendarYearCache: Sendable {
    private struct State: Sendable {
        var values: [ChineseCalendarYearKey: ChineseCalendarYearIndex] = [:]
        var recency: [ChineseCalendarYearKey] = []
    }

    private let limit: Int
    private let state = Mutex(State())

    init(limit: Int) {
        self.limit = max(1, limit)
    }

    func value(
        for key: ChineseCalendarYearKey,
        build: @Sendable () -> ChineseCalendarYearIndex
    ) -> ChineseCalendarYearIndex {
        state.withLock { state in
            if let value = state.values[key] {
                state.recency.removeAll { $0 == key }
                state.recency.append(key)
                return value
            }

            let value = build()
            if state.values.count == limit, let oldest = state.recency.first {
                state.values.removeValue(forKey: oldest)
                state.recency.removeFirst()
            }
            state.values[key] = value
            state.recency.append(key)
            return value
        }
    }
}

public enum ChineseCalendarDateResolver {
    private static let cache = ChineseCalendarYearCache(limit: 32)

    public static func monthLength(
        gregorianAnchorYear: Int,
        lunarMonth: Int,
        prefersLeapMonth: Bool,
        timeZone: TimeZone = .current
    ) -> Int? {
        logicalMonthDates(
            gregorianAnchorYear: gregorianAnchorYear,
            lunarMonth: lunarMonth,
            prefersLeapMonth: prefersLeapMonth,
            timeZone: timeZone
        )?.count
    }

    public static func date(
        gregorianAnchorYear: Int,
        lunarMonth: Int,
        day: Int,
        prefersLeapMonth: Bool,
        timeZone: TimeZone
    ) -> Date? {
        guard
            let dates = logicalMonthDates(
                gregorianAnchorYear: gregorianAnchorYear,
                lunarMonth: lunarMonth,
                prefersLeapMonth: prefersLeapMonth,
                timeZone: timeZone
            ),
            !dates.isEmpty
        else { return nil }

        return dates[min(max(day, 1), dates.count) - 1]
    }

    private static func logicalMonthDates(
        gregorianAnchorYear: Int,
        lunarMonth: Int,
        prefersLeapMonth: Bool,
        timeZone: TimeZone
    ) -> [Date]? {
        guard (1...12).contains(lunarMonth) else { return nil }
        let yearKey = ChineseCalendarYearKey(
            gregorianYear: gregorianAnchorYear,
            timeZoneIdentifier: timeZone.identifier
        )
        let index = cache.value(for: yearKey) {
            makeYearIndex(gregorianYear: gregorianAnchorYear, timeZone: timeZone)
        }
        let ordinaryKey = ChineseCalendarMonthKey(month: lunarMonth, isLeapMonth: false)
        let leapKey = ChineseCalendarMonthKey(month: lunarMonth, isLeapMonth: true)
        if prefersLeapMonth, let leapDates = index.months[leapKey] {
            return leapDates
        }
        return index.months[ordinaryKey]
    }

    private static func makeYearIndex(
        gregorianYear: Int,
        timeZone: TimeZone
    ) -> ChineseCalendarYearIndex {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = timeZone
        guard
            let yearStart = gregorian.date(
                from: DateComponents(year: gregorianYear, month: 1, day: 1)
            ),
            let yearEnd = gregorian.date(
                from: DateComponents(year: gregorianYear + 1, month: 1, day: 1)
            )
        else { return ChineseCalendarYearIndex(months: [:]) }

        var starts: [ChineseCalendarMonthKey: Date] = [:]
        var cursor = yearStart
        while cursor < yearEnd {
            let components = chinese.dateComponents([.month, .day, .isLeapMonth], from: cursor)
            if let month = components.month, components.day == 1 {
                let key = ChineseCalendarMonthKey(
                    month: month,
                    isLeapMonth: components.isLeapMonth == true
                )
                if starts[key] == nil { starts[key] = cursor }
            }
            guard let next = gregorian.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        let months = starts.mapValues { start in
            logicalMonthDates(
                startingAt: start,
                gregorian: gregorian,
                chinese: chinese
            )
        }
        return ChineseCalendarYearIndex(months: months)
    }

    private static func logicalMonthDates(
        startingAt start: Date,
        gregorian: Calendar,
        chinese: Calendar
    ) -> [Date] {
        let first = chinese.dateComponents([.month, .isLeapMonth], from: start)
        var dates: [Date] = []
        var cursor = start
        while dates.count < 30 {
            let components = chinese.dateComponents([.month, .day, .isLeapMonth], from: cursor)
            guard
                components.month == first.month,
                components.isLeapMonth == first.isLeapMonth,
                components.day == dates.count + 1
            else { break }
            dates.append(cursor)
            guard let next = gregorian.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return dates
    }
}
