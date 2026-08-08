import SwiftUI

struct CategoryManagerView: View {
    private enum Field: Hashable { case name }

    let repository: AnniversaryRepository
    @FocusState private var focusedField: Field?
    @State private var categories: [CategoryModel] = []
    @State private var name = ""

    var body: some View {
        List {
            Section("New Category") {
                TextField("Category Name", text: $name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                Button("Add Category", systemImage: "plus") {
                    focusedField = nil
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
                    focusedField = nil
                    for index in offsets { try? repository.deleteCategory(id: categories[index].id) }
                    reload()
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Manage Categories")
        .onAppear(perform: reload)
    }

    private func reload() { categories = repository.categories() }
}
