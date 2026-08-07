import SwiftUI
import TaisetsuCore

struct SettingsView: View {
    let repository: AnniversaryRepository
    let reconciliationCoordinator: ReconciliationCoordinator

    var body: some View {
        NavigationStack {
            List {
                Section("Organization") {
                    NavigationLink {
                        CategoryManagerView(repository: repository)
                    } label: {
                        Label("Manage Categories", systemImage: "folder")
                    }
                    NavigationLink {
                        TagManagerView(repository: repository)
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }
                Section("Sync & Permissions") {
                    LabeledContent("iCloud", value: "Automatic Sync")
                    Label("Notification access is requested when you add a reminder", systemImage: "bell")
                    NavigationLink {
                        CalendarSyncSettingsView(
                            repository: repository,
                            reconciliationCoordinator: reconciliationCoordinator
                        )
                    } label: {
                        Label("Calendar Sync", systemImage: "calendar.badge.clock")
                    }
                }
                Section("About") {
                    LabeledContent(
                        "Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("Your data stays on your device and in your private iCloud database.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct CalendarSyncSettingsView: View {
    let repository: AnniversaryRepository
    let reconciliationCoordinator: ReconciliationCoordinator
    @State private var settings: CalendarSyncSettings
    @State private var customScope = false
    @State private var selectedCategories: Set<UUID> = []
    @State private var selectedTags: Set<UUID> = []

    init(repository: AnniversaryRepository, reconciliationCoordinator: ReconciliationCoordinator) {
        self.repository = repository
        self.reconciliationCoordinator = reconciliationCoordinator
        let initial = reconciliationCoordinator.calendarSettings
        _settings = State(initialValue: initial)
        if case .custom(let categories, let tags, _, _) = initial.scope {
            _customScope = State(initialValue: true)
            _selectedCategories = State(initialValue: categories)
            _selectedTags = State(initialValue: tags)
        }
    }

    var body: some View {
        Form {
            Section("Status") {
                LabeledContent("Automatic Sync", value: settings.enabled ? "Enabled" : "Stopped")
                LabeledContent("Managed Events", value: "\(reconciliationCoordinator.calendarEntriesCount())")
                if let last = settings.lastSuccessfulSync {
                    LabeledContent("Last Synced", value: last.formatted(date: .abbreviated, time: .shortened))
                }
                Button(settings.enabled ? "Stop Automatic Sync" : "Enable Automatic Sync") {
                    settings.enabled.toggle()
                    try? reconciliationCoordinator.saveCalendarSettings(settings)
                    Task { await reconciliationCoordinator.reconcile() }
                }
                if let error = reconciliationCoordinator.lastError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            Section("Sync Range") {
                Stepper("\(settings.horizonYears) years", value: $settings.horizonYears, in: 1...5)
                    .onChange(of: settings.horizonYears) { _, _ in
                        try? reconciliationCoordinator.saveCalendarSettings(settings)
                        Task { await reconciliationCoordinator.reconcile() }
                    }
                Text("All future occurrences in this rolling window are managed automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Scope") {
                Picker("Records", selection: $customScope) {
                    Text("All Important Days").tag(false)
                    Text("Custom").tag(true)
                }
                .onChange(of: customScope) { _, _ in saveScope() }
                if customScope {
                    ForEach(repository.categories()) { category in
                        Toggle(
                            category.displayName(),
                            isOn: Binding(
                                get: { selectedCategories.contains(category.id) },
                                set: { enabled in
                                    if enabled {
                                        selectedCategories.insert(category.id)
                                    } else {
                                        selectedCategories.remove(category.id)
                                    }
                                    saveScope()
                                }
                            ))
                    }
                    ForEach(repository.tags()) { tag in
                        Toggle(
                            "#\(tag.name)",
                            isOn: Binding(
                                get: { selectedTags.contains(tag.id) },
                                set: { enabled in
                                    if enabled {
                                        selectedTags.insert(tag.id)
                                    } else {
                                        selectedTags.remove(tag.id)
                                    }
                                    saveScope()
                                }
                            ))
                    }
                }
            }
        }
        .navigationTitle("Calendar Sync")
        .onAppear {
            settings = reconciliationCoordinator.calendarSettings
            if case .custom(let categories, let tags, _, _) = settings.scope {
                customScope = true
                selectedCategories = categories
                selectedTags = tags
            }
        }
    }

    private func saveScope() {
        settings.scope =
            customScope
            ? .custom(
                categories: selectedCategories,
                tags: selectedTags,
                includeUncategorized: true,
                includeUntagged: true
            )
            : .all
        try? reconciliationCoordinator.saveCalendarSettings(settings)
        Task { await reconciliationCoordinator.reconcile() }
    }
}
