import SwiftUI
import TaisetsuCore

struct HomeView: View {
    let repository: AnniversaryRepository
    let reconciliationCoordinator: ReconciliationCoordinator
    let calendarPromptCoordinator: CalendarSyncPromptCoordinator
    @State private var viewModel: HomeViewModel
    @State private var showingNew = false
    @State private var editingRecord: AnniversaryRecord?
    @State private var showingFilters = false

    init(
        repository: AnniversaryRepository,
        reconciliationCoordinator: ReconciliationCoordinator,
        calendarPromptCoordinator: CalendarSyncPromptCoordinator
    ) {
        self.repository = repository
        self.reconciliationCoordinator = reconciliationCoordinator
        self.calendarPromptCoordinator = calendarPromptCoordinator
        _viewModel = State(initialValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("Loading important days…")
                case .empty:
                    ContentUnavailableView {
                        Label("No important days yet", systemImage: "calendar.badge.plus")
                    } description: {
                        Text("Keep birthdays, anniversaries, and every day worth looking forward to close.")
                    } actions: {
                        Button("Add Important Day") { showingNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                case .failed(let message):
                    ContentUnavailableView(
                        "Unable to Load Important Days",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                case .content:
                    content
                }
            }
            .navigationTitle("Taisetsu")
            .searchable(text: $viewModel.query, prompt: "Search names, notes, categories, or tags")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        showingFilters = true
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Important Day", systemImage: "plus") { showingNew = true }
                        .accessibilityIdentifier("add-anniversary")
                }
            }
            .onAppear(perform: viewModel.load)
            .sheet(isPresented: $showingNew) {
                AnniversaryEditorView(repository: repository) { record, isNew in
                    viewModel.load()
                    Task { await reconciliationCoordinator.reconcile() }
                    calendarPromptCoordinator.consider(afterSaving: record, isNew: isNew)
                }
            }
            .sheet(item: $editingRecord) { record in
                AnniversaryEditorView(repository: repository, record: record) { savedRecord, isNew in
                    viewModel.load()
                    Task { await reconciliationCoordinator.reconcile() }
                    calendarPromptCoordinator.consider(afterSaving: savedRecord, isNew: isNew)
                }
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
                        AnniversaryDetailView(
                            presentation: hero,
                            onEdit: { editingRecord = hero.record },
                            onSync: { await reconciliationCoordinator.reconcile() }
                        )
                    } label: {
                        AnniversaryHeroCard(presentation: hero)
                    }
                    .buttonStyle(.plain)
                }
                section(
                    "Pinned",
                    items: viewModel.sections.pinned.dropFirst(
                        viewModel.hero?.record.isPinned == true ? 1 : 0))
                section(
                    "Upcoming",
                    items: viewModel.sections.upcoming.dropFirst(
                        viewModel.hero?.record.isPinned == false ? 1 : 0))
                section("Ongoing", items: viewModel.sections.ongoing)
                section("Past", items: viewModel.sections.ended)
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
                        AnniversaryDetailView(
                            presentation: presentation,
                            onEdit: { editingRecord = presentation.record },
                            onSync: { await reconciliationCoordinator.reconcile() }
                        )
                    } label: {
                        AnniversaryRow(presentation: presentation)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            try? viewModel.setPinned(
                                id: presentation.id,
                                isPinned: !presentation.record.isPinned
                            )
                            Task { await reconciliationCoordinator.reconcile() }
                        } label: {
                            if presentation.record.isPinned {
                                Label("Unpin", systemImage: "pin")
                            } else {
                                Label("Pin", systemImage: "pin")
                            }
                        }
                        Button("Edit", systemImage: "pencil") { editingRecord = presentation.record }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            try? viewModel.delete(id: presentation.id)
                            Task { await reconciliationCoordinator.reconcile() }
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
                Section("Category (single selection)") {
                    filterRow("All Categories", selected: viewModel.categoryID == nil) {
                        viewModel.categoryID = nil
                    }
                    ForEach(repository.categories()) { category in
                        filterRow(category.displayName(), selected: viewModel.categoryID == category.id) {
                            viewModel.categoryID = category.id
                        }
                    }
                }
                Section("Tags (multiple selection)") {
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
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
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
