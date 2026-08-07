import SwiftUI
import TaisetsuCore

struct AnniversaryEditorView: View {
    private enum Field: Hashable {
        case name
        case notes
    }

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var viewModel: AnniversaryEditorViewModel
    let onSaved: (AnniversaryRecord, Bool) -> Void

    init(
        repository: AnniversaryRepository,
        record: AnniversaryRecord? = nil,
        onSaved: @escaping (AnniversaryRecord, Bool) -> Void
    ) {
        _viewModel = State(initialValue: AnniversaryEditorViewModel(repository: repository, record: record))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.draft.title)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .notes }
                    TextField("Notes", text: $viewModel.draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
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
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { focusedField = nil }
            .navigationTitle(
                viewModel.draft.id == nil
                    ? Text("New Important Day")
                    : Text("Edit Important Day")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        focusedField = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        focusedField = nil
                        let isNew = viewModel.draft.id == nil
                        if viewModel.save() {
                            if let savedRecord = viewModel.savedRecord {
                                onSaved(savedRecord, isNew)
                            }
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
