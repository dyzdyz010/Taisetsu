import SwiftUI
import TaisetsuCore

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let repository: AnniversaryRepository
    let reconciliationCoordinator: ReconciliationCoordinator
    @State private var viewModel: HomeViewModel
    @State private var navigationPath: [UUID] = []
    @State private var showingNew = false
    @State private var editingRecord: AnniversaryRecord?
    @State private var showingFilters = false

    init(
        repository: AnniversaryRepository,
        reconciliationCoordinator: ReconciliationCoordinator
    ) {
        self.repository = repository
        self.reconciliationCoordinator = reconciliationCoordinator
        _viewModel = State(initialValue: HomeViewModel(repository: repository))
        #if DEBUG
            let screenshotSection = AppStoreScreenshotData.initialSection(in: CommandLine.arguments)
            _editingRecord = State(
                initialValue: screenshotSection == "editor"
                    ? repository.fetch().first(where: \.isPinned)
                    : nil
            )
        #endif
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("Loading important days…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .empty:
                    ContentUnavailableView {
                        Label("No important days yet", systemImage: "calendar.badge.plus")
                    } description: {
                        Text("Keep birthdays, anniversaries, and every day worth looking forward to close.")
                    } actions: {
                        Button("Add Important Day") { showingNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                case .failed(let message):
                    ContentUnavailableView(
                        "Unable to Load Important Days",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
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
            .navigationDestination(for: UUID.self) { id in
                if let presentation = viewModel.sections.all.first(where: { $0.id == id }) {
                    AnniversaryDetailView(
                        presentation: presentation,
                        onEdit: { editingRecord = presentation.record },
                        onSync: { await reconciliationCoordinator.reconcile() }
                    )
                }
            }
            .onAppear(perform: viewModel.load)
            .sheet(isPresented: $showingNew) {
                AnniversaryEditorView(repository: repository) { _, _ in
                    viewModel.load()
                    Task { await reconciliationCoordinator.reconcile() }
                }
            }
            .sheet(item: $editingRecord) { record in
                AnniversaryEditorView(
                    repository: repository,
                    record: record,
                    onDeleted: {
                        navigationPath.removeAll()
                        viewModel.load()
                        Task { await reconciliationCoordinator.reconcile() }
                    }
                ) { _, _ in
                    viewModel.load()
                    Task { await reconciliationCoordinator.reconcile() }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
        }
    }

    private var content: some View {
        GeometryReader { proxy in
            let composition = TaisetsuAdaptiveLayout.contentComposition(
                availableWidth: proxy.size.width,
                horizontalSizeClass: horizontalSizeClass
            )

            ScrollView {
                Group {
                    if composition == .twoColumns, let hero = viewModel.hero {
                        if hasSecondaryItems {
                            HStack(alignment: .top, spacing: TaisetsuAdaptiveLayout.columnSpacing) {
                                heroLink(hero)
                                    .frame(width: 360)
                                eventSections
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                        } else {
                            heroLink(hero)
                                .frame(maxWidth: 620)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            if let hero = viewModel.hero {
                                heroLink(hero)
                            }
                            eventSections
                        }
                    }
                }
                .frame(maxWidth: TaisetsuAdaptiveLayout.dashboardMaxWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(
                    .horizontal,
                    TaisetsuAdaptiveLayout.horizontalPadding(
                        horizontalSizeClass: horizontalSizeClass
                    )
                )
                .padding(.vertical, 20)
            }
        }
        .refreshable { viewModel.load() }
    }

    private var eventSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            section("Pinned", items: withoutHero(viewModel.sections.pinned))
            section("Upcoming", items: withoutHero(viewModel.sections.upcoming))
            section("Ongoing", items: withoutHero(viewModel.sections.ongoing))
            section("Past", items: withoutHero(viewModel.sections.ended))
        }
    }

    private var hasSecondaryItems: Bool {
        [
            viewModel.sections.pinned,
            viewModel.sections.upcoming,
            viewModel.sections.ongoing,
            viewModel.sections.ended,
        ]
        .contains { !$0.allSatisfy { $0.id == viewModel.hero?.id } }
    }

    private func withoutHero(_ items: [AnniversaryPresentation]) -> [AnniversaryPresentation] {
        items.filter { $0.id != viewModel.hero?.id }
    }

    private func heroLink(_ hero: AnniversaryPresentation) -> some View {
        NavigationLink(value: hero.id) {
            AnniversaryHeroCard(presentation: hero)
        }
        .buttonStyle(.plain)
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
                    NavigationLink(value: presentation.id) {
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
    @Environment(\.locale) private var locale
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Category (single selection)") {
                    filterRow(
                        AppLocalization.string("All Categories", locale: locale),
                        selected: viewModel.categoryID == nil
                    ) {
                        viewModel.categoryID = nil
                    }
                    ForEach(viewModel.categories) { category in
                        filterRow(category.displayName(), selected: viewModel.categoryID == category.id) {
                            viewModel.categoryID = category.id
                        }
                    }
                }
                Section("Tags (multiple selection)") {
                    ForEach(viewModel.tags) { tag in
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
            .taisetsuReadableForm()
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
