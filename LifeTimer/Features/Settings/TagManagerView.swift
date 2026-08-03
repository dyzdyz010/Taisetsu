import SwiftUI

struct TagManagerView: View {
    let repository: AnniversaryRepository
    @State private var tags: [TagModel] = []
    @State private var name = ""

    var body: some View {
        List {
            Section("新标签") {
                TextField("标签名称", text: $name)
                Button("添加标签", systemImage: "plus") {
                    try? repository.saveTag(name: name)
                    name = ""
                    reload()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("已有标签") {
                ForEach(tags) { tag in Label(tag.name, systemImage: "tag") }
                    .onDelete { offsets in
                        for index in offsets { try? repository.deleteTag(id: tags[index].id) }
                        reload()
                    }
            }
        }
        .navigationTitle("标签管理")
        .onAppear(perform: reload)
    }

    private func reload() { tags = repository.tags() }
}
