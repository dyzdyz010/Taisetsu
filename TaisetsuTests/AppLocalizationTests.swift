import Foundation
import Testing

@testable import Taisetsu
@testable import TaisetsuCore

struct AppLocalizationTests {
    @Test func relativeAndRecurrenceCopyFollowTheRequestedLocale() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = date("2026-08-03T12:00:00Z")
        let next = date("2026-08-05T12:00:00Z")
        let occurrence = Occurrence(
            original: now,
            previous: nil,
            next: next,
            elapsed: nil,
            remaining: DateComponents(day: 2),
            state: .upcoming
        )

        #expect(
            AnniversaryFormatters.relative(
                occurrence,
                mode: .countdown,
                now: now,
                locale: Locale(identifier: "en_US"),
                calendar: calendar
            ) == "in 2 days"
        )
        #expect(
            AnniversaryFormatters.relative(
                occurrence,
                mode: .countdown,
                now: now,
                locale: Locale(identifier: "zh_Hans_CN"),
                calendar: calendar
            ) == "2天后"
        )
        #expect(
            AnniversaryFormatters.recurrence(
                RecurrenceRule(unit: .month, interval: 2),
                locale: Locale(identifier: "en_US")
            ) == "Every 2 months"
        )
        #expect(
            AnniversaryFormatters.recurrence(
                RecurrenceRule(unit: .month, interval: 2),
                locale: Locale(identifier: "zh_Hans_CN")
            ) == "每2个月"
        )
    }

    @Test func dateWheelOrderFollowsLocaleDateOrder() {
        #expect(DateWheelComponent.ordered(for: Locale(identifier: "en_US")) == [.month, .day, .year])
        #expect(DateWheelComponent.ordered(for: Locale(identifier: "zh_CN")) == [.year, .month, .day])
    }

    @Test func weekdaySymbolsRotateToTheCalendarsFirstWeekday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = 2

        let symbols = LocalizedCalendarLayout.weekdaySymbols(for: calendar)

        #expect(symbols.count == 7)
        #expect(symbols.first == "M")
        #expect(symbols.last == "S")
    }

    @Test func catalogResolvesARightToLeftLocale() {
        #expect(AppLocalization.string("Home", locale: Locale(identifier: "ar")) == "الرئيسية")
    }

    @Test func lunarDatesExposeTheirCalendarMeaningInEnglishAndChinese() {
        let shanghai = TimeZone(identifier: "Asia/Shanghai")!
        let ordinary = date("2026-09-13T16:00:00Z")
        let leap = date("2034-01-18T16:00:00Z")

        #expect(
            AnniversaryFormatters.lunarMonthDay(
                ordinary,
                locale: Locale(identifier: "en_US"),
                timeZone: shanghai
            ) == "Lunar month 8, day 4"
        )
        #expect(
            AnniversaryFormatters.lunarMonthDay(
                ordinary,
                locale: Locale(identifier: "zh_Hans_CN"),
                timeZone: shanghai
            ) == "农历8月4日"
        )
        #expect(
            AnniversaryFormatters.dateWithLunar(
                ordinary,
                isAllDay: true,
                locale: Locale(identifier: "en_US"),
                timeZone: shanghai
            ) == "Sep 14, 2026 · Lunar month 8, day 4"
        )
        #expect(
            AnniversaryFormatters.lunarMonthDay(
                leap,
                locale: Locale(identifier: "zh_Hans_CN"),
                timeZone: shanghai
            ) == "农历闰11月29日"
        )
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}
