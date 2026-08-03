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
                Section("Basics") {
                    TextField("Name", text: $viewModel.draft.title)
                    TextField("Notes", text: $viewModel.draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                DateRuleSection(draft: $viewModel.draft)
                RecurrenceSection(draft: $viewModel.draft)
                ReminderSection(viewModel: viewModel)
                CategoryTagSection(viewModel: viewModel)
                Section("Display") {
                    Toggle("Pin", isOn: $viewModel.draft.isPinned)
                    Toggle("Show in Widgets", isOn: $viewModel.draft.isVisibleInWidget)
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(
                viewModel.draft.id == nil
                    ? Text("New Important Day")
                    : Text("Edit Important Day")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
