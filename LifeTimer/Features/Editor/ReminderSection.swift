import LifeTimerCore
import SwiftUI

struct ReminderSection: View {
    @Bindable var viewModel: AnniversaryEditorViewModel

    var body: some View {
        Section("提醒") {
            ForEach(viewModel.draft.reminders) { reminder in
                Text(label(for: reminder.offsetMinutes))
            }
            .onDelete(perform: viewModel.removeReminders)
            Menu("添加提醒", systemImage: "bell.badge") {
                Button("事件发生时") { viewModel.addReminder(offsetMinutes: 0) }
                    .disabled(viewModel.draft.isAllDay)
                Button("提前 1 小时") { viewModel.addReminder(offsetMinutes: -60) }
                Button("提前 1 天") { viewModel.addReminder(offsetMinutes: -1_440) }
                Button("提前 1 周") { viewModel.addReminder(offsetMinutes: -10_080) }
            }
        }
    }

    private func label(for minutes: Int) -> String {
        switch minutes {
        case 0: "事件发生时"
        case -60: "提前 1 小时"
        case -1_440: "提前 1 天"
        case -10_080: "提前 1 周"
        default: "提前 \(abs(minutes)) 分钟"
        }
    }
}
