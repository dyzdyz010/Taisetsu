import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            Tab("首页", systemImage: "house") {
                HomeView(
                    repository: dependencies.repository,
                    reconciliationCoordinator: dependencies.reconciliationCoordinator
                )
            }
            Tab("日历", systemImage: "calendar") {
                CalendarView(repository: dependencies.repository)
            }
            Tab("设置", systemImage: "gearshape") {
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
