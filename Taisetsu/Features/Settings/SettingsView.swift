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
                    LabeledContent {
                        Text("Automatic Sync")
                    } label: {
                        Text(verbatim: "iCloud")
                    }
                    Label("Notification access is requested when you add a reminder", systemImage: "bell")
                    NavigationLink {
                        CalendarSyncSettingsView(
                            repository: repository,
                            reconciliationCoordinator: reconciliationCoordinator
                        )
                    } label: {
                        Label("Calendar Sync", systemImage: "calendar.badge.clock")
                    }
                    .accessibilityIdentifier("calendar-sync-settings")
                }
                Section("About") {
                    LabeledContent(
                        "Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("Your data stays on your device and in your private iCloud database.")
                        .foregroundStyle(.secondary)
                }
            }
            .taisetsuReadableForm()
            .navigationTitle("Settings")
        }
    }
}

private struct CalendarSyncSettingsView: View {
    @Environment(\.locale) private var locale
    let repository: AnniversaryRepository
    let reconciliationCoordinator: ReconciliationCoordinator
    @State private var settings = CalendarSyncSettings()
    @State private var customScope = false
    @State private var selectedCategories: Set<UUID> = []
    @State private var selectedTags: Set<UUID> = []
    @State private var categories: [CategoryModel] = []
    @State private var tags: [TagModel] = []
    @State private var managedEventsCount = 0

    var body: some View {
        Form {
            Section("Status") {
                LabeledContent {
                    Text(
                        AppLocalization.string(
                            settings.enabled ? "Enabled" : "Stopped",
                            locale: locale
                        )
                    )
                    .accessibilityIdentifier("calendar-sync-status")
                } label: {
                    Text("Automatic Sync")
                }
                LabeledContent("Managed Events", value: "\(managedEventsCount)")
                if let last = settings.lastSuccessfulSync {
                    LabeledContent("Last Synced", value: last.formatted(date: .abbreviated, time: .shortened))
                }
                Button(
                    AppLocalization.string(
                        settings.enabled ? "Stop Automatic Sync" : "Enable Automatic Sync",
                        locale: locale
                    )
                ) {
                    settings.enabled.toggle()
                    try? reconciliationCoordinator.saveCalendarSettings(settings)
                    reconcile()
                }
                if let error = reconciliationCoordinator.lastError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            Section("Sync Range") {
                Stepper(
                    AppLocalization.yearDuration(settings.horizonYears, locale: locale),
                    value: Binding(
                        get: { settings.horizonYears },
                        set: { value in
                            settings.horizonYears = value
                            try? reconciliationCoordinator.saveCalendarSettings(settings)
                            reconcile()
                        }
                    ),
                    in: 1...5
                )
                Text("All future occurrences in this rolling window are managed automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Scope") {
                Picker(
                    "Records",
                    selection: Binding(
                        get: { customScope },
                        set: { value in
                            customScope = value
                            saveScope()
                        }
                    )
                ) {
                    Text("All Important Days").tag(false)
                    Text("Custom").tag(true)
                }
                if customScope {
                    ForEach(categories) { category in
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
                    ForEach(tags) { tag in
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
        .taisetsuReadableForm()
        .navigationTitle("Calendar Sync")
        .onAppear(perform: reload)
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
        reconcile()
    }

    private func reconcile() {
        Task {
            await reconciliationCoordinator.reconcile()
            reload()
        }
    }

    private func reload() {
        settings = reconciliationCoordinator.calendarSettings
        categories = repository.categories()
        tags = repository.tags()
        managedEventsCount = reconciliationCoordinator.calendarEntriesCount()
        switch settings.scope {
        case .all:
            customScope = false
            selectedCategories = []
            selectedTags = []
        case .custom(let categories, let tags, _, _):
            customScope = true
            selectedCategories = categories
            selectedTags = tags
        }
    }
}
