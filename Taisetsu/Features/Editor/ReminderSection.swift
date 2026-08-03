import SwiftUI
import TaisetsuCore

struct ReminderSection: View {
    @Environment(\.locale) private var locale
    @Bindable var viewModel: AnniversaryEditorViewModel

    var body: some View {
        Section("Reminders") {
            ForEach(viewModel.draft.reminders) { reminder in
                Text(label(for: reminder.offsetMinutes))
            }
            .onDelete(perform: viewModel.removeReminders)
            Menu("Add Reminder", systemImage: "bell.badge") {
                Button("At Event Time") { viewModel.addReminder(offsetMinutes: 0) }
                    .disabled(viewModel.draft.isAllDay)
                Button("1 Hour Before") { viewModel.addReminder(offsetMinutes: -60) }
                Button("1 Day Before") { viewModel.addReminder(offsetMinutes: -1_440) }
                Button("1 Week Before") { viewModel.addReminder(offsetMinutes: -10_080) }
            }
        }
    }

    private func label(for minutes: Int) -> String {
        AnniversaryFormatters.reminderOffset(minutes, locale: locale)
    }
}
