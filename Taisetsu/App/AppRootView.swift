import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView(
                    repository: dependencies.repository,
                    reconciliationCoordinator: dependencies.reconciliationCoordinator,
                    calendarPromptCoordinator: dependencies.calendarPromptCoordinator
                )
            }
            Tab("Calendar", systemImage: "calendar") {
                CalendarView(repository: dependencies.repository)
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView(
                    repository: dependencies.repository,
                    reconciliationCoordinator: dependencies.reconciliationCoordinator
                )
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
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
}
