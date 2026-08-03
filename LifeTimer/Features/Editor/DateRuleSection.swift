import Foundation
import LifeTimerCore
import SwiftUI

enum DateWheelSelection {
    static func yearRange(containing selectedYear: Int, referenceDate: Date = .now) -> ClosedRange<Int> {
        let currentYear = Calendar.current.component(.year, from: referenceDate)
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
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .current
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = .current
        guard
            let start = gregorian.date(from: DateComponents(year: date.year, month: 1, day: 1)),
            let end = gregorian.date(from: DateComponents(year: date.year + 1, month: 1, day: 1))
        else { return 30 }

        var ordinaryMaximum = 0
        var leapMaximum = 0
        var cursor = start
        while cursor < end {
            let components = chinese.dateComponents([.month, .day, .isLeapMonth], from: cursor)
            if components.month == date.month, let day = components.day {
                if components.isLeapMonth == true {
                    leapMaximum = max(leapMaximum, day)
                } else {
                    ordinaryMaximum = max(ordinaryMaximum, day)
                }
            }
            guard let next = gregorian.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        if date.isLeapMonth, leapMaximum > 0 { return leapMaximum }
        return ordinaryMaximum > 0 ? ordinaryMaximum : 30
    }
}

struct DateRuleSection: View {
    @Binding var draft: AnniversaryDraft

    var body: some View {
        Section("日期") {
            Picker("历法", selection: calendarKindBinding) {
                Text("公历").tag(CalendarKind.gregorian)
                Text("农历").tag(CalendarKind.chinese)
            }

            HStack(spacing: 0) {
                Picker("年份", selection: yearBinding) {
                    ForEach(DateWheelSelection.yearRange(containing: draft.date.year), id: \.self) {
                        Text("\($0) 年").tag($0)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .accessibilityLabel("年份")
                .accessibilityIdentifier("date-wheel-year")

                Picker("月份", selection: monthBinding) {
                    ForEach(1...12, id: \.self) {
                        Text("\($0) 月").tag($0)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .accessibilityLabel("月份")
                .accessibilityIdentifier("date-wheel-month")

                Picker("日期", selection: $draft.date.day) {
                    ForEach(
                        DateWheelSelection.dayRange(for: draft.date, calendarKind: draft.calendarKind),
                        id: \.self
                    ) {
                        Text("\($0) 日").tag($0)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .accessibilityLabel("日期")
                .accessibilityIdentifier("date-wheel-day")
            }
            .frame(height: 170)
            .clipped()

            if draft.calendarKind == .chinese {
                Toggle("闰月", isOn: leapMonthBinding)
            }
            Toggle("全天", isOn: $draft.isAllDay)
            if !draft.isAllDay {
                HStack {
                    Stepper("时：\(draft.date.hour)", value: $draft.date.hour, in: 0...23)
                    Stepper("分：\(draft.date.minute)", value: $draft.date.minute, in: 0...59, step: 5)
                }
            }
        }
        .onAppear(perform: normalizeDate)
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
