import LifeTimerCore
import SwiftUI

struct AnniversaryDetailView: View {
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
                            presentation.occurrence, mode: presentation.record.displayMode)
                    )
                    .font(.largeTitle.bold().monospacedDigit())
                    if let next = presentation.occurrence.next {
                        Text(AnniversaryFormatters.date(next, isAllDay: presentation.record.isAllDay))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            Section("日期规则") {
                LabeledContent("历法", value: presentation.record.calendarKind == .gregorian ? "公历" : "农历")
                LabeledContent(
                    "原始日期",
                    value: AnniversaryFormatters.date(
                        presentation.occurrence.original, isAllDay: presentation.record.isAllDay))
                LabeledContent("重复", value: AnniversaryFormatters.recurrence(presentation.record.recurrence))
                LabeledContent("显示", value: displayModeName)
            }
            if !presentation.record.reminders.isEmpty {
                Section("提醒") {
                    ForEach(presentation.record.reminders) { reminder in
                        Label(reminderText(reminder.offsetMinutes), systemImage: "bell")
                    }
                }
            }
            Section("整理") {
                LabeledContent("分类", value: presentation.record.category?.name ?? "无分类")
                if !presentation.record.tags.isEmpty {
                    LabeledContent("标签", value: presentation.record.tags.map(\.name).joined(separator: "、"))
                }
                LabeledContent("置顶", value: presentation.record.isPinned ? "是" : "否")
                LabeledContent("小组件", value: presentation.record.isVisibleInWidget ? "显示" : "隐藏")
            }
            if !presentation.record.notes.isEmpty {
                Section("备注") { Text(presentation.record.notes) }
            }
            Section("系统日历") {
                Button("导出下一次到日历", systemImage: "calendar.badge.plus") {
                    isExporting = true
                    Task {
                        do {
                            try await onExport()
                            exportMessage = "已导出；再次导出会更新同一事件"
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
        .navigationTitle("纪念日详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("编辑", action: onEdit) }
    }

    private var displayModeName: String {
        switch presentation.record.displayMode {
        case .countdown: "倒计时"
        case .countUp: "正计时"
        case .both: "同时显示"
        }
    }

    private func reminderText(_ minutes: Int) -> String {
        if minutes == 0 { return "事件发生时" }
        if minutes % 1_440 == 0 { return "提前 \(abs(minutes / 1_440)) 天" }
        if minutes % 60 == 0 { return "提前 \(abs(minutes / 60)) 小时" }
        return "提前 \(abs(minutes)) 分钟"
    }
}
