import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView(
                    repository: dependencies.repository,
                    reconciliationCoordinator: dependencies.reconciliationCoordinator
                )
            }
            Tab("Calendar", systemImage: "calendar") {
                CalendarView(repository: dependencies.repository)
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView(repository: dependencies.repository)
            }
        }
        .task { await dependencies.reconciliationCoordinator.reconcile() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await dependencies.reconciliationCoordinator.reconcile() }
        }
    }
}
