import LifeTimerCore
import SwiftUI

struct RecurrenceSection: View {
    @Binding var draft: AnniversaryDraft

    var body: some View {
        Section("重复与显示") {
            Picker("重复", selection: $draft.recurrenceUnit) {
                Text("不重复").tag(RecurrenceRule.Unit?.none)
                Text("每天").tag(RecurrenceRule.Unit?.some(.day))
                Text("每周").tag(RecurrenceRule.Unit?.some(.week))
                Text("每月").tag(RecurrenceRule.Unit?.some(.month))
                Text("每年").tag(RecurrenceRule.Unit?.some(.year))
            }
            if draft.recurrenceUnit != nil {
                Stepper("每 \(draft.recurrenceInterval) 个周期", value: $draft.recurrenceInterval, in: 1...999)
            }
            Picker("计时方式", selection: $draft.displayMode) {
                Text("倒计时").tag(DisplayMode.countdown)
                Text("正计时").tag(DisplayMode.countUp)
                Text("同时显示").tag(DisplayMode.both)
            }
        }
    }
}
