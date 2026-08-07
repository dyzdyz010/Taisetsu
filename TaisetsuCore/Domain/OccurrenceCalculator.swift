import Foundation

public enum ChineseCalendarDateResolver {
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

        let clampedDay = min(max(day, 1), dates.count)
        return dates[clampedDay - 1]
    }

    private static func logicalMonthDates(
        gregorianAnchorYear: Int,
        lunarMonth: Int,
        prefersLeapMonth: Bool,
        timeZone: TimeZone
    ) -> [Date]? {
        guard (1...12).contains(lunarMonth) else { return nil }

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = timeZone
        guard
            let yearStart = gregorian.date(
                from: DateComponents(year: gregorianAnchorYear, month: 1, day: 1)
            ),
            let yearEnd = gregorian.date(
                from: DateComponents(year: gregorianAnchorYear + 1, month: 1, day: 1)
            )
        else { return nil }

        var ordinaryStart: Date?
        var leapStart: Date?
        var cursor = yearStart
        while cursor < yearEnd {
            let components = chinese.dateComponents([.month, .day, .isLeapMonth], from: cursor)
            if components.month == lunarMonth, components.day == 1 {
                if components.isLeapMonth == true, leapStart == nil {
                    leapStart = cursor
                } else if components.isLeapMonth != true, ordinaryStart == nil {
                    ordinaryStart = cursor
                }
            }
            guard let next = gregorian.date(byAdding: .day, value: 1, to: cursor) else { return nil }
            cursor = next
        }

        let usesLeapMonth = prefersLeapMonth && leapStart != nil
        guard let monthStart = usesLeapMonth ? leapStart : ordinaryStart else { return nil }

        var dates: [Date] = []
        cursor = monthStart
        while dates.count < 30 {
            let components = chinese.dateComponents([.month, .day, .isLeapMonth], from: cursor)
            guard
                components.month == lunarMonth,
                components.isLeapMonth == usesLeapMonth,
                components.day == dates.count + 1
            else { break }
            dates.append(cursor)
            guard let next = gregorian.date(byAdding: .day, value: 1, to: cursor) else { return nil }
            cursor = next
        }

        return dates.isEmpty ? nil : dates
    }
}

public struct OccurrenceCalculator: Sendable {
    public init() {}

    public func occurrences(
        for anniversary: AnniversaryRecord,
        from start: Date,
        through end: Date,
        maxCount: Int,
        timeZone: TimeZone
    ) throws -> [ScheduledOccurrence] {
        guard maxCount > 0, start <= end else { return [] }
        var calendar = Calendar(identifier: anniversary.calendarKind == .gregorian ? .gregorian : .chinese)
        calendar.timeZone = timeZone
        let lowerBound = anniversary.isAllDay ? calendar.startOfDay(for: start) : start
        let upperBound = anniversary.isAllDay ? calendar.startOfDay(for: end) : end
        let original = try occurrenceDate(for: anniversary, sequence: 0, calendar: calendar)

        guard anniversary.recurrence.unit != nil else {
            let candidate = anniversary.isAllDay ? calendar.startOfDay(for: original) : original
            guard candidate >= lowerBound, candidate <= upperBound else { return [] }
            return [ScheduledOccurrence(sequence: 0, date: original)]
        }

        var sequence = max(
            0,
            sequenceEstimate(
                for: anniversary,
                original: original,
                reference: lowerBound,
                calendar: calendar
            ) - 2
        )
        var result: [ScheduledOccurrence] = []
        var guardIterations = 0
        while result.count < maxCount && guardIterations < 1_000_000 {
            let candidate = try occurrenceDate(for: anniversary, sequence: sequence, calendar: calendar)
            let comparable = anniversary.isAllDay ? calendar.startOfDay(for: candidate) : candidate
            if comparable >= lowerBound, comparable <= upperBound {
                result.append(ScheduledOccurrence(sequence: sequence, date: candidate))
            }
            if comparable > upperBound { break }
            sequence += 1
            guardIterations += 1
        }
        return result
    }

    public func calculate(
        for anniversary: AnniversaryRecord,
        relativeTo referenceDate: Date,
        timeZone: TimeZone
    ) throws -> Occurrence {
        var calendar = Calendar(identifier: anniversary.calendarKind == .gregorian ? .gregorian : .chinese)
        calendar.timeZone = timeZone

        let original = try occurrenceDate(for: anniversary, sequence: 0, calendar: calendar)
        let comparisonReference =
            anniversary.isAllDay ? calendar.startOfDay(for: referenceDate) : referenceDate
        let originalComparison = anniversary.isAllDay ? calendar.startOfDay(for: original) : original

        guard anniversary.recurrence.unit != nil else {
            return oneTimeOccurrence(
                original: original,
                originalComparison: originalComparison,
                reference: comparisonReference,
                isAllDay: anniversary.isAllDay,
                calendar: calendar
            )
        }

        let estimate = sequenceEstimate(
            for: anniversary,
            original: original,
            reference: comparisonReference,
            calendar: calendar
        )
        var candidates: [(Int, Date)] = []
        var lower = max(0, estimate - 2)
        var upper = max(4, estimate + 3)

        while candidates.isEmpty || candidates.last!.1 < comparisonReference {
            candidates = try (lower...upper).map { sequence in
                (sequence, try occurrenceDate(for: anniversary, sequence: sequence, calendar: calendar))
            }
            .sorted { $0.1 < $1.1 }
            if let last = candidates.last, last.1 >= comparisonReference { break }
            lower = upper + 1
            upper += 8
        }

        let sameOccurrence: (Date) -> Bool = { candidate in
            if anniversary.isAllDay {
                return calendar.isDate(candidate, inSameDayAs: comparisonReference)
            }
            return abs(candidate.timeIntervalSince(comparisonReference)) < 60
        }
        let current = candidates.first(where: { sameOccurrence($0.1) })?.1
        let next = current ?? candidates.first(where: { $0.1 > comparisonReference })?.1
        let previous = current ?? candidates.last(where: { $0.1 < comparisonReference })?.1
        let state: OccurrenceState = current == nil ? .upcoming : .ongoing

        return Occurrence(
            original: original,
            previous: previous,
            next: next,
            elapsed: comparisonReference >= originalComparison
                ? difference(from: originalComparison, to: comparisonReference, calendar: calendar) : nil,
            remaining: next.map { difference(from: comparisonReference, to: $0, calendar: calendar) },
            state: state
        )
    }

    private func oneTimeOccurrence(
        original: Date,
        originalComparison: Date,
        reference: Date,
        isAllDay: Bool,
        calendar: Calendar
    ) -> Occurrence {
        let isCurrent =
            isAllDay
            ? calendar.isDate(originalComparison, inSameDayAs: reference)
            : abs(originalComparison.timeIntervalSince(reference)) < 60
        let state: OccurrenceState =
            isCurrent ? .ongoing : (reference < originalComparison ? .upcoming : .ended)
        return Occurrence(
            original: original,
            previous: reference >= originalComparison ? original : nil,
            next: reference <= originalComparison ? original : nil,
            elapsed: reference >= originalComparison
                ? difference(from: originalComparison, to: reference, calendar: calendar) : nil,
            remaining: reference <= originalComparison
                ? difference(from: reference, to: originalComparison, calendar: calendar) : nil,
            state: state
        )
    }

    private func occurrenceDate(
        for anniversary: AnniversaryRecord,
        sequence: Int,
        calendar: Calendar
    ) throws -> Date {
        if anniversary.calendarKind == .chinese,
            anniversary.recurrence.unit == .year || sequence == 0
        {
            let targetYear = anniversary.date.year + sequence * anniversary.recurrence.interval
            return try chineseDate(for: anniversary, gregorianYear: targetYear, timeZone: calendar.timeZone)
        }

        let interval = anniversary.recurrence.interval * sequence
        guard let unit = anniversary.recurrence.unit else {
            return try gregorianDate(
                for: anniversary.date, isAllDay: anniversary.isAllDay, calendar: calendar)
        }
        switch unit {
        case .day, .week:
            let original = try baseDate(for: anniversary, calendar: calendar)
            let days = unit == .week ? interval * 7 : interval
            guard let result = calendar.date(byAdding: .day, value: days, to: original) else {
                throw OccurrenceCalculationError.invalidDate
            }
            return result
        case .month:
            if anniversary.calendarKind == .gregorian {
                let monthIndex = anniversary.date.year * 12 + anniversary.date.month - 1 + interval
                var date = anniversary.date
                date.year = monthIndex / 12
                date.month = monthIndex % 12 + 1
                return try gregorianDate(for: date, isAllDay: anniversary.isAllDay, calendar: calendar)
            }
            return try addingChineseMonths(interval, to: anniversary, calendar: calendar)
        case .year:
            var date = anniversary.date
            date.year += interval
            return try gregorianDate(for: date, isAllDay: anniversary.isAllDay, calendar: calendar)
        }
    }

    private func baseDate(for anniversary: AnniversaryRecord, calendar: Calendar) throws -> Date {
        if anniversary.calendarKind == .chinese {
            return try chineseDate(
                for: anniversary, gregorianYear: anniversary.date.year, timeZone: calendar.timeZone)
        }
        return try gregorianDate(for: anniversary.date, isAllDay: anniversary.isAllDay, calendar: calendar)
    }

    private func gregorianDate(
        for value: AnniversaryDate,
        isAllDay: Bool,
        calendar inputCalendar: Calendar
    ) throws -> Date {
        var calendar = inputCalendar
        calendar.identifier == .gregorian ? () : (calendar = Calendar(identifier: .gregorian))
        calendar.timeZone = inputCalendar.timeZone
        let monthStart = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: value.year,
            month: value.month,
            day: 1
        )
        guard let start = calendar.date(from: monthStart),
            let range = calendar.range(of: .day, in: .month, for: start)
        else {
            throw OccurrenceCalculationError.invalidDate
        }
        let day = min(max(value.day, 1), range.count)
        if isAllDay {
            guard
                let result = calendar.date(
                    from: DateComponents(year: value.year, month: value.month, day: day))
            else { throw OccurrenceCalculationError.invalidDate }
            return result
        }
        guard
            let dayStart = calendar.date(
                from: DateComponents(year: value.year, month: value.month, day: day)),
            let result = calendar.nextDate(
                after: dayStart.addingTimeInterval(-1),
                matching: DateComponents(hour: value.hour, minute: value.minute),
                matchingPolicy: .nextTimePreservingSmallerComponents,
                repeatedTimePolicy: .first,
                direction: .forward
            ),
            calendar.isDate(result, inSameDayAs: dayStart)
        else {
            throw OccurrenceCalculationError.invalidDate
        }
        return result
    }

    private func chineseDate(
        for anniversary: AnniversaryRecord,
        gregorianYear: Int,
        timeZone: TimeZone
    ) throws -> Date {
        guard
            let dayStart = ChineseCalendarDateResolver.date(
                gregorianAnchorYear: gregorianYear,
                lunarMonth: anniversary.date.month,
                day: anniversary.date.day,
                prefersLeapMonth: anniversary.date.isLeapMonth,
                timeZone: timeZone
            )
        else {
            throw OccurrenceCalculationError.invalidDate
        }
        if anniversary.isAllDay { return dayStart }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        guard
            let result = gregorian.nextDate(
                after: dayStart.addingTimeInterval(-1),
                matching: DateComponents(hour: anniversary.date.hour, minute: anniversary.date.minute),
                matchingPolicy: .nextTimePreservingSmallerComponents
            )
        else { throw OccurrenceCalculationError.invalidDate }
        return result
    }

    private func addingChineseMonths(
        _ months: Int,
        to anniversary: AnniversaryRecord,
        calendar: Calendar
    ) throws -> Date {
        let original = try baseDate(for: anniversary, calendar: calendar)
        guard let rough = calendar.date(byAdding: .month, value: months, to: original),
            let monthRange = calendar.range(of: .day, in: .month, for: rough)
        else { throw OccurrenceCalculationError.invalidDate }
        let components = calendar.dateComponents([.era, .year, .month, .isLeapMonth], from: rough)
        var target = components
        target.day = min(anniversary.date.day, monthRange.count)
        target.hour = anniversary.isAllDay ? 0 : anniversary.date.hour
        target.minute = anniversary.isAllDay ? 0 : anniversary.date.minute
        guard let result = calendar.date(from: target) else { throw OccurrenceCalculationError.invalidDate }
        return result
    }

    private func sequenceEstimate(
        for anniversary: AnniversaryRecord,
        original: Date,
        reference: Date,
        calendar: Calendar
    ) -> Int {
        guard let unit = anniversary.recurrence.unit, reference > original else { return 0 }
        let component: Calendar.Component
        switch unit {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        let difference =
            calendar.dateComponents([component], from: original, to: reference).value(for: component) ?? 0
        return max(0, difference / anniversary.recurrence.interval)
    }

    private func difference(from start: Date, to end: Date, calendar: Calendar) -> DateComponents {
        calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start, to: end)
    }
}
