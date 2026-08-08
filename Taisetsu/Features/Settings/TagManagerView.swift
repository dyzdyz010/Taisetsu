import SwiftUI

struct TagManagerView: View {
    private enum Field: Hashable { case name }

    let repository: AnniversaryRepository
    @FocusState private var focusedField: Field?
    @State private var tags: [TagModel] = []
    @State private var name = ""

    var body: some View {
        List {
            Section("New Tag") {
                TextField("Tag Name", text: $name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                Button("Add Tag", systemImage: "plus") {
                    focusedField = nil
                    _ = try? repository.saveTag(name: name)
                    name = ""
                    reload()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("Tags") {
                ForEach(tags) { tag in Label(tag.name, systemImage: "tag") }
                    .onDelete { offsets in
                        focusedField = nil
                        for index in offsets { try? repository.deleteTag(id: tags[index].id) }
                        reload()
                    }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Manage Tags")
        .onAppear(perform: reload)
    }

    private func reload() { tags = repository.tags() }
}
