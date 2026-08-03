import SwiftUI

struct TagManagerView: View {
    let repository: AnniversaryRepository
    @State private var tags: [TagModel] = []
    @State private var name = ""

    var body: some View {
        List {
            Section("New Tag") {
                TextField("Tag Name", text: $name)
                Button("Add Tag", systemImage: "plus") {
                    _ = try? repository.saveTag(name: name)
                    name = ""
                    reload()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("Tags") {
                ForEach(tags) { tag in Label(tag.name, systemImage: "tag") }
                    .onDelete { offsets in
                        for index in offsets { try? repository.deleteTag(id: tags[index].id) }
                        reload()
                    }
            }
        }
        .navigationTitle("Manage Tags")
        .onAppear(perform: reload)
    }

    private func reload() { tags = repository.tags() }
}
