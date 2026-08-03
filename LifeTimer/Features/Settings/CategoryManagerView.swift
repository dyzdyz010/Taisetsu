import SwiftUI

struct CategoryManagerView: View {
    let repository: AnniversaryRepository
    @State private var categories: [CategoryModel] = []
    @State private var name = ""

    var body: some View {
        List {
            Section("新分类") {
                TextField("分类名称", text: $name)
                Button("添加分类", systemImage: "plus") {
                    _ = try? repository.saveCategory(
                        name: name,
                        symbolName: "folder",
                        colorToken: "blue"
                    )
                    name = ""
                    reload()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("已有分类") {
                ForEach(categories) { category in
                    Label(category.name, systemImage: category.symbolName)
                }
                .onDelete { offsets in
                    for index in offsets { try? repository.deleteCategory(id: categories[index].id) }
                    reload()
                }
            }
        }
        .navigationTitle("分类管理")
        .onAppear(perform: reload)
    }

    private func reload() { categories = repository.categories() }
}
