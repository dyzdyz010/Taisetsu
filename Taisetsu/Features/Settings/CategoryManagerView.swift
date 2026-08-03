import SwiftUI

struct CategoryManagerView: View {
    let repository: AnniversaryRepository
    @State private var categories: [CategoryModel] = []
    @State private var name = ""

    var body: some View {
        List {
            Section("New Category") {
                TextField("Category Name", text: $name)
                Button("Add Category", systemImage: "plus") {
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
            Section("Categories") {
                ForEach(categories) { category in
                    Label(category.displayName(), systemImage: category.symbolName)
                }
                .onDelete { offsets in
                    for index in offsets { try? repository.deleteCategory(id: categories[index].id) }
                    reload()
                }
            }
        }
        .navigationTitle("Manage Categories")
        .onAppear(perform: reload)
    }

    private func reload() { categories = repository.categories() }
}
