import SwiftUI

struct AppRootView: View {
    private enum AppSection: String, CaseIterable, Identifiable {
        case home
        case calendar
        case settings

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .home: "Home"
            case .calendar: "Calendar"
            case .settings: "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .home: "house"
            case .calendar: "calendar"
            case .settings: "gearshape"
            }
        }

        var accessibilityIdentifier: String { "sidebar-\(rawValue)" }
    }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let dependencies: AppDependencies
    @State private var selectedSection: AppSection

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        #if DEBUG
            let initialSection =
                AppStoreScreenshotData.initialSection(in: CommandLine.arguments)
                .flatMap(AppSection.init(rawValue:)) ?? .home
        #else
            let initialSection = AppSection.home
        #endif
        _selectedSection = State(initialValue: initialSection)
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularRoot
            } else {
                compactRoot
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            #if DEBUG
                guard !CommandLine.arguments.contains("-app-store-screenshots") else { return }
            #endif
            await dependencies.reconciliationCoordinator.reconcile()
        }
        .sheet(
            isPresented: Binding(
                get: { dependencies.calendarPromptCoordinator.isPresented },
                set: { dependencies.calendarPromptCoordinator.isPresented = $0 }
            )
        ) {
            CalendarSyncPromptView(prompt: dependencies.calendarPromptCoordinator)
        }
    }

    private var compactRoot: some View {
        TabView(selection: $selectedSection) {
            Tab("Home", systemImage: "house", value: .home) {
                destination(for: .home)
            }
            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                destination(for: .calendar)
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                destination(for: .settings)
            }
        }
    }

    private var regularRoot: some View {
        NavigationSplitView {
            List(selection: sidebarSelection) {
                ForEach(AppSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label(section.title, systemImage: section.systemImage)
                    }
                    .accessibilityIdentifier(section.accessibilityIdentifier)
                }
            }
            .accessibilityIdentifier("app-sidebar")
            .navigationTitle("Taisetsu")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            destination(for: selectedSection)
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebarSelection: Binding<AppSection?> {
        Binding(
            get: { selectedSection },
            set: { selection in
                if let selection {
                    selectedSection = selection
                }
            }
        )
    }

    @ViewBuilder
    private func destination(for section: AppSection) -> some View {
        switch section {
        case .home:
            HomeView(
                repository: dependencies.repository,
                reconciliationCoordinator: dependencies.reconciliationCoordinator,
                calendarPromptCoordinator: dependencies.calendarPromptCoordinator
            )
        case .calendar:
            CalendarView(repository: dependencies.repository)
        case .settings:
            SettingsView(
                repository: dependencies.repository,
                reconciliationCoordinator: dependencies.reconciliationCoordinator
            )
        }
    }
}
