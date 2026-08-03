import LifeTimerCore
import SwiftUI

struct DateRuleSection: View {
    @Binding var draft: AnniversaryDraft

    var body: some View {
        Section("日期") {
            Picker("历法", selection: $draft.calendarKind) {
                Text("公历").tag(CalendarKind.gregorian)
                Text("农历").tag(CalendarKind.chinese)
            }
            HStack {
                Text("年份")
                Spacer()
                TextField("年份", value: $draft.date.year, format: .number)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
            Stepper("月份：\(draft.date.month)", value: $draft.date.month, in: 1...12)
            Stepper("日期：\(draft.date.day)", value: $draft.date.day, in: 1...31)
            if draft.calendarKind == .chinese {
                Toggle("闰月", isOn: $draft.date.isLeapMonth)
            }
            Toggle("全天", isOn: $draft.isAllDay)
            if !draft.isAllDay {
                HStack {
                    Stepper("时：\(draft.date.hour)", value: $draft.date.hour, in: 0...23)
                    Stepper("分：\(draft.date.minute)", value: $draft.date.minute, in: 0...59, step: 5)
                }
            }
        }
    }
}
