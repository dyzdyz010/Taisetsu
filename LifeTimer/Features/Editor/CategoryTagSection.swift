import SwiftUI

struct CategoryTagSection: View {
    @Bindable var viewModel: AnniversaryEditorViewModel

    var body: some View {
        Section("分类与标签") {
            Picker("分类", selection: $viewModel.draft.categoryID) {
                Text("无分类").tag(UUID?.none)
                ForEach(viewModel.categories) { category in
                    Label(category.name, systemImage: category.symbolName).tag(UUID?.some(category.id))
                }
            }
            ForEach(viewModel.tags) { tag in
                Button {
                    if viewModel.draft.tagIDs.contains(tag.id) {
                        viewModel.draft.tagIDs.remove(tag.id)
                    } else {
                        viewModel.draft.tagIDs.insert(tag.id)
                    }
                } label: {
                    HStack {
                        Text(tag.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if viewModel.draft.tagIDs.contains(tag.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}
