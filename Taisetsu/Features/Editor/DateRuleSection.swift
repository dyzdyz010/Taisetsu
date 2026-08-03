import Foundation
import SwiftUI
import TaisetsuCore

enum DateWheelSelection {
    static func yearRange(
        containing selectedYear: Int,
        referenceDate: Date = .now,
        timeZone: TimeZone = .current
    ) -> ClosedRange<Int> {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let currentYear = calendar.component(.year, from: referenceDate)
        return min(1900, selectedYear)...max(currentYear + 100, selectedYear)
    }

    static func dayRange(for date: AnniversaryDate, calendarKind: CalendarKind) -> ClosedRange<Int> {
        1...maximumDay(for: date, calendarKind: calendarKind)
    }

    static func normalize(_ date: inout AnniversaryDate, calendarKind: CalendarKind) {
        date.month = min(max(date.month, 1), 12)
        let validDays = dayRange(for: date, calendarKind: calendarKind)
        date.day = min(max(date.day, validDays.lowerBound), validDays.upperBound)
    }

    private static func maximumDay(for date: AnniversaryDate, calendarKind: CalendarKind) -> Int {
        switch calendarKind {
        case .gregorian:
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            guard
                let monthStart = calendar.date(
                    from: DateComponents(year: date.year, month: date.month, day: 1)
                ),
                let range = calendar.range(of: .day, in: .month, for: monthStart)
            else { return 31 }
            return range.count
        case .chinese:
            return chineseMonthLength(for: date)
        }
    }

    private static func chineseMonthLength(for date: AnniversaryDate) -> Int {
        ChineseCalendarDateResolver.monthLength(
            gregorianAnchorYear: date.year,
            lunarMonth: date.month,
            prefersLeapMonth: date.isLeapMonth
        ) ?? 30
    }
}

enum DateWheelComponent: Hashable {
    case year
    case month
    case day

    static func ordered(for locale: Locale) -> [DateWheelComponent] {
        let format = DateFormatter.dateFormat(fromTemplate: "yMd", options: 0, locale: locale) ?? "yMd"
        return [DateWheelComponent.year, .month, .day].sorted {
            (format.firstIndex(of: $0.formatCharacter) ?? format.endIndex)
                < (format.firstIndex(of: $1.formatCharacter) ?? format.endIndex)
        }
    }

    private var formatCharacter: Character {
        switch self {
        case .year: "y"
        case .month: "M"
        case .day: "d"
        }
    }
}

struct DateRuleSection: View {
    @Environment(\.locale) private var locale
    @Binding var draft: AnniversaryDraft

    var body: some View {
        Section("Date") {
            Picker("Calendar", selection: calendarKindBinding) {
                Text("Gregorian").tag(CalendarKind.gregorian)
                Text("Chinese Lunar").tag(CalendarKind.chinese)
            }

            HStack(spacing: 0) {
                ForEach(DateWheelComponent.ordered(for: locale), id: \.self) { component in
                    datePicker(for: component)
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 170)
            .clipped()

            if draft.calendarKind == .chinese {
                Toggle("Leap Month", isOn: leapMonthBinding)
            }
            Toggle("All Day", isOn: $draft.isAllDay)
            if !draft.isAllDay {
                HStack {
                    Stepper("Hour: \(draft.date.hour)", value: $draft.date.hour, in: 0...23)
                    Stepper("Minute: \(draft.date.minute)", value: $draft.date.minute, in: 0...59, step: 5)
                }
            }
        }
        .onAppear(perform: normalizeDate)
    }

    @ViewBuilder
    private func datePicker(for component: DateWheelComponent) -> some View {
        switch component {
        case .year:
            Picker("Year", selection: yearBinding) {
                ForEach(DateWheelSelection.yearRange(containing: draft.date.year), id: \.self) {
                    Text($0, format: .number.grouping(.never)).tag($0)
                }
            }
            .accessibilityIdentifier("date-wheel-year")
        case .month:
            Picker("Month", selection: monthBinding) {
                ForEach(1...12, id: \.self) {
                    Text($0, format: .number.grouping(.never)).tag($0)
                }
            }
            .accessibilityIdentifier("date-wheel-month")
        case .day:
            Picker("Day", selection: $draft.date.day) {
                ForEach(
                    DateWheelSelection.dayRange(for: draft.date, calendarKind: draft.calendarKind),
                    id: \.self
                ) {
                    Text($0, format: .number.grouping(.never)).tag($0)
                }
            }
            .accessibilityIdentifier("date-wheel-day")
        }
    }

    private var calendarKindBinding: Binding<CalendarKind> {
        Binding(
            get: { draft.calendarKind },
            set: {
                draft.calendarKind = $0
                normalizeDate()
            }
        )
    }

    private var yearBinding: Binding<Int> {
        Binding(
            get: { draft.date.year },
            set: {
                draft.date.year = $0
                normalizeDate()
            }
        )
    }

    private var monthBinding: Binding<Int> {
        Binding(
            get: { draft.date.month },
            set: {
                draft.date.month = $0
                normalizeDate()
            }
        )
    }

    private var leapMonthBinding: Binding<Bool> {
        Binding(
            get: { draft.date.isLeapMonth },
            set: {
                draft.date.isLeapMonth = $0
                normalizeDate()
            }
        )
    }

    private func normalizeDate() {
        var date = draft.date
        DateWheelSelection.normalize(&date, calendarKind: draft.calendarKind)
        draft.date = date
    }
}
