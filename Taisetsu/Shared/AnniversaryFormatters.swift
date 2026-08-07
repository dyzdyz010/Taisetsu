import Foundation
import TaisetsuCore

enum AnniversaryFormatters {
    static func date(
        _ value: Date,
        isAllDay: Bool,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        var style =
            isAllDay
            ? Date.FormatStyle(date: .abbreviated, time: .omitted).locale(locale)
            : Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale)
        style.timeZone = timeZone
        return value.formatted(style)
    }

    static func lunarMonthDay(
        _ value: Date,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.month, .day], from: value)
        guard let month = components.month, let day = components.day else { return "" }
        let key =
            components.isLeapMonth == true
            ? "Leap lunar month %lld, day %lld"
            : "Lunar month %lld, day %lld"
        return AppLocalization.format(key, month, day, locale: locale)
    }

    static func dateWithLunar(
        _ value: Date,
        isAllDay: Bool,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        let gregorian = date(value, isAllDay: isAllDay, locale: locale, timeZone: timeZone)
        let lunar = lunarMonthDay(value, locale: locale, timeZone: timeZone)
        return "\(gregorian) · \(lunar)"
    }

    static func relative(
        _ occurrence: Occurrence,
        mode: DisplayMode,
        now: Date = .now,
        locale: Locale = .current,
        calendar: Calendar = .current
    ) -> String {
        switch mode {
        case .countUp:
            return relativeDayText(
                days: -dayDistance(from: occurrence.original, to: now, calendar: calendar),
                locale: locale
            )
        case .countdown, .both:
            guard let next = occurrence.next else {
                return relativeDayText(
                    days: -dayDistance(from: occurrence.original, to: now, calendar: calendar),
                    locale: locale
                )
            }
            return relativeDayText(
                days: max(0, dayDistance(from: now, to: next, calendar: calendar)),
                locale: locale
            )
        }
    }

    static func recurrence(_ rule: RecurrenceRule, locale: Locale = .current) -> String {
        guard let unit = rule.unit else { return AppLocalization.string("Does not repeat", locale: locale) }
        var components = DateComponents()
        switch unit {
        case .day: components.day = rule.interval
        case .week: components.weekOfYear = rule.interval
        case .month: components.month = rule.interval
        case .year: components.year = rule.interval
        }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = allowedUnit(for: unit)
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar
        let interval = formatter.string(from: components) ?? String(rule.interval)
        return AppLocalization.format("Every %@", interval, locale: locale)
    }

    static func relativeDays(_ days: Int, locale: Locale = .current) -> String {
        relativeDayText(days: days, locale: locale)
    }

    static func reminderOffset(_ minutes: Int, locale: Locale = .current) -> String {
        guard minutes != 0 else { return AppLocalization.string("At Event Time", locale: locale) }
        let magnitude = abs(minutes)
        if magnitude == 10_080 {
            return AppLocalization.string("1 Week Before", locale: locale)
        }
        var components = DateComponents()
        let unit: NSCalendar.Unit
        if magnitude.isMultiple(of: 10_080) {
            components.weekOfYear = magnitude / 10_080
            unit = .weekOfYear
        } else if magnitude.isMultiple(of: 1_440) {
            components.day = magnitude / 1_440
            unit = .day
        } else if magnitude.isMultiple(of: 60) {
            components.hour = magnitude / 60
            unit = .hour
        } else {
            components.minute = magnitude
            unit = .minute
        }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = unit
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar
        let interval = formatter.string(from: components) ?? String(magnitude)
        return AppLocalization.format("%@ before", interval, locale: locale)
    }

    private static func relativeDayText(days: Int, locale: Locale) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .full
        return formatter.localizedString(from: DateComponents(day: days))
    }

    private static func dayDistance(from start: Date, to end: Date, calendar: Calendar) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: end)
        ).day ?? 0
    }

    private static func allowedUnit(for unit: RecurrenceRule.Unit) -> NSCalendar.Unit {
        switch unit {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}
