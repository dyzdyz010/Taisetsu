import LifeTimerCore
import SwiftUI

struct HomeView: View {
    let repository: AnniversaryRepository
    @State private var viewModel: HomeViewModel
    @State private var showingNew = false
    @State private var editingRecord: AnniversaryRecord?
    @State private var showingFilters = false

    init(repository: AnniversaryRepository) {
        self.repository = repository
        _viewModel = State(initialValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("正在读取纪念日…")
                case .empty:
                    ContentUnavailableView {
                        Label("还没有纪念日", systemImage: "calendar.badge.plus")
                    } description: {
                        Text("记录生日、相识日或任何值得期待的日子。")
                    } actions: {
                        Button("新建纪念日") { showingNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                case .failed(let message):
                    ContentUnavailableView(
                        "无法读取纪念日", systemImage: "exclamationmark.triangle", description: Text(message))
                case .content:
                    content
                }
            }
            .navigationTitle("生命倒计时")
            .searchable(text: $viewModel.query, prompt: "搜索名称、备注、分类或标签")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("筛选", systemImage: "line.3.horizontal.decrease.circle") { showingFilters = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("新建纪念日", systemImage: "plus") { showingNew = true }
                        .accessibilityIdentifier("add-anniversary")
                }
            }
            .onAppear(perform: viewModel.load)
            .sheet(isPresented: $showingNew) {
                AnniversaryEditorView(repository: repository) { viewModel.load() }
            }
            .sheet(item: $editingRecord) { record in
                AnniversaryEditorView(repository: repository, record: record) { viewModel.load() }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(repository: repository, viewModel: viewModel)
            }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if let hero = viewModel.hero {
                    NavigationLink {
                        AnniversaryDetailView(presentation: hero) { editingRecord = hero.record }
                    } label: {
                        AnniversaryHeroCard(presentation: hero)
                    }
                    .buttonStyle(.plain)
                }
                section(
                    "置顶",
                    items: viewModel.sections.pinned.dropFirst(
                        viewModel.hero?.record.isPinned == true ? 1 : 0))
                section(
                    "即将到来",
                    items: viewModel.sections.upcoming.dropFirst(
                        viewModel.hero?.record.isPinned == false ? 1 : 0))
                section("正在进行", items: viewModel.sections.ongoing)
                section("已经结束", items: viewModel.sections.ended)
            }
            .padding()
        }
        .refreshable { viewModel.load() }
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, items: some Collection<AnniversaryPresentation>)
        -> some View
    {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                ForEach(Array(items)) { presentation in
                    NavigationLink {
                        AnniversaryDetailView(presentation: presentation) {
                            editingRecord = presentation.record
                        }
                    } label: {
                        AnniversaryRow(presentation: presentation)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(presentation.record.isPinned ? "取消置顶" : "置顶", systemImage: "pin") {
                            try? viewModel.setPinned(
                                id: presentation.id, isPinned: !presentation.record.isPinned)
                        }
                        Button("编辑", systemImage: "pencil") { editingRecord = presentation.record }
                        Button("删除", systemImage: "trash", role: .destructive) {
                            try? viewModel.delete(id: presentation.id)
                        }
                    }
                    Divider()
                }
            }
        }
    }
}

private struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: AnniversaryRepository
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("分类（单选）") {
                    filterRow("全部分类", selected: viewModel.categoryID == nil) { viewModel.categoryID = nil }
                    ForEach(repository.categories()) { category in
                        filterRow(category.name, selected: viewModel.categoryID == category.id) {
                            viewModel.categoryID = category.id
                        }
                    }
                }
                Section("标签（可多选）") {
                    ForEach(repository.tags()) { tag in
                        filterRow(tag.name, selected: viewModel.requiredTagIDs.contains(tag.id)) {
                            if viewModel.requiredTagIDs.contains(tag.id) {
                                viewModel.requiredTagIDs.remove(tag.id)
                            } else {
                                viewModel.requiredTagIDs.insert(tag.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("完成") { dismiss() } }
        }
    }

    private func filterRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                if selected { Image(systemName: "checkmark") }
            }
        }
    }
}
