import LifeTimerCore
import SwiftUI

struct AnniversaryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AnniversaryEditorViewModel
    let onSaved: () -> Void

    init(
        repository: AnniversaryRepository,
        record: AnniversaryRecord? = nil,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: AnniversaryEditorViewModel(repository: repository, record: record))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $viewModel.draft.title)
                    TextField("备注", text: $viewModel.draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                DateRuleSection(draft: $viewModel.draft)
                RecurrenceSection(draft: $viewModel.draft)
                ReminderSection(viewModel: viewModel)
                CategoryTagSection(viewModel: viewModel)
                Section("显示") {
                    Toggle("置顶", isOn: $viewModel.draft.isPinned)
                    Toggle("在小组件中显示", isOn: $viewModel.draft.isVisibleInWidget)
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.draft.id == nil ? "新建纪念日" : "编辑纪念日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if viewModel.save() {
                            onSaved()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("save-anniversary")
                }
            }
        }
    }
}
