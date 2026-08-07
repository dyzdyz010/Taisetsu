import SwiftUI
import TaisetsuCore

struct ReminderSection: View {
    @Environment(\.locale) private var locale
    @Bindable var viewModel: AnniversaryEditorViewModel
    @State private var sameDayTime = Self.defaultSameDayTime
    @State private var isShowingSameDayTime = false

    var body: some View {
        Section("Reminders") {
            ForEach(viewModel.draft.reminders) { reminder in
                Text(label(for: reminder))
            }
            .onDelete(perform: viewModel.removeReminders)
            Menu("Add Reminder", systemImage: "bell.badge") {
                Button("Same Day") {
                    isShowingSameDayTime = true
                }
                .disabled(viewModel.draft.reminders.contains { $0.timeOfDayMinutes != nil })
                Button("At Event Time") {
                    viewModel.addReminder(offsetMinutes: 0)
                }
                .disabled(
                    viewModel.draft.isAllDay
                        || viewModel.draft.reminders.contains {
                            $0.offsetMinutes == 0 && $0.timeOfDayMinutes == nil
                        }
                )
                Button("1 Hour Before") { viewModel.addReminder(offsetMinutes: -60) }
                Button("1 Day Before") { viewModel.addReminder(offsetMinutes: -1_440) }
                Button("1 Week Before") { viewModel.addReminder(offsetMinutes: -10_080) }
            }
        }
        .sheet(isPresented: $isShowingSameDayTime) {
            NavigationStack {
                Form {
                    DatePicker(
                        "Time",
                        selection: $sameDayTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                }
                .navigationTitle("Same Day")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isShowingSameDayTime = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            viewModel.addReminder(
                                offsetMinutes: 0,
                                timeOfDayMinutes: timeMinutes(from: sameDayTime)
                            )
                            isShowingSameDayTime = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.height(220)])
        }
    }

    private func label(for reminder: ReminderSpec) -> String {
        guard let minutes = reminder.timeOfDayMinutes else {
            return AnniversaryFormatters.reminderOffset(reminder.offsetMinutes, locale: locale)
        }
        let time = sameDayDate(minutes: minutes).formatted(
            .dateTime.hour().minute().locale(locale)
        )
        return "(AppLocalization.string("Same Day", locale: locale)) · (time)"
    }

    private func sameDayDate(minutes: Int) -> Date {
        Calendar.current.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: .now
        ) ?? .now
    }

    private func timeMinutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 9) * 60 + (components.minute ?? 0)
    }

    private static var defaultSameDayTime: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    }
}
