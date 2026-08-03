import SwiftUI
import TaisetsuCore

struct AnniversaryDetailView: View {
    @Environment(\.locale) private var locale
    let presentation: AnniversaryPresentation
    let onEdit: () -> Void
    let onExport: () async throws -> Void
    @State private var exportMessage: String?
    @State private var isExporting = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(presentation.record.title)
                        .font(.title2.bold())
                    Text(
                        AnniversaryFormatters.relative(
                            presentation.occurrence,
                            mode: presentation.record.displayMode,
                            locale: locale
                        )
                    )
                    .font(.largeTitle.bold().monospacedDigit())
                    if let next = presentation.occurrence.next {
                        Text(displayDate(next))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            Section("Date Rule") {
                LabeledContent("Calendar", value: calendarName)
                LabeledContent(
                    "Original Date",
                    value: displayDate(presentation.occurrence.original)
                )
                LabeledContent(
                    "Repeat",
                    value: AnniversaryFormatters.recurrence(
                        presentation.record.recurrence,
                        locale: locale
                    )
                )
                LabeledContent("Display", value: displayModeName)
            }
            if !presentation.record.reminders.isEmpty {
                Section("Reminders") {
                    ForEach(presentation.record.reminders) { reminder in
                        Label(reminderText(reminder.offsetMinutes), systemImage: "bell")
                    }
                }
            }
            Section("Organization") {
                LabeledContent(
                    "Category",
                    value: presentation.record.category?.name
                        ?? AppLocalization.string("No Category", locale: locale)
                )
                if !presentation.record.tags.isEmpty {
                    LabeledContent(
                        "Tags",
                        value: AppLocalization.list(
                            presentation.record.tags.map(\.name),
                            locale: locale
                        )
                    )
                }
                LabeledContent(
                    "Pinned",
                    value: AppLocalization.string(
                        presentation.record.isPinned ? "Yes" : "No",
                        locale: locale
                    )
                )
                LabeledContent(
                    "Widgets",
                    value: AppLocalization.string(
                        presentation.record.isVisibleInWidget ? "Shown" : "Hidden",
                        locale: locale
                    )
                )
            }
            if !presentation.record.notes.isEmpty {
                Section("Notes") { Text(presentation.record.notes) }
            }
            Section("System Calendar") {
                Button("Export Next Date to Calendar", systemImage: "calendar.badge.plus") {
                    isExporting = true
                    Task {
                        do {
                            try await onExport()
                            exportMessage = AppLocalization.string(
                                "Exported. Exporting again will update the same event.",
                                locale: locale
                            )
                        } catch {
                            exportMessage = error.localizedDescription
                        }
                        isExporting = false
                    }
                }
                .disabled(isExporting)
                if let exportMessage {
                    Text(exportMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Important Day Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Edit", action: onEdit) }
    }

    private var displayModeName: String {
        switch presentation.record.displayMode {
        case .countdown: AppLocalization.string("Countdown", locale: locale)
        case .countUp: AppLocalization.string("Count Up", locale: locale)
        case .both: AppLocalization.string("Show Both", locale: locale)
        }
    }

    private var calendarName: String {
        AppLocalization.string(
            presentation.record.calendarKind == .gregorian ? "Gregorian" : "Chinese Lunar",
            locale: locale
        )
    }

    private func reminderText(_ minutes: Int) -> String {
        AnniversaryFormatters.reminderOffset(minutes, locale: locale)
    }

    private func displayDate(_ value: Date) -> String {
        if presentation.record.calendarKind == .chinese {
            return AnniversaryFormatters.dateWithLunar(
                value,
                isAllDay: presentation.record.isAllDay,
                locale: locale
            )
        }
        return AnniversaryFormatters.date(
            value,
            isAllDay: presentation.record.isAllDay,
            locale: locale
        )
    }
}
