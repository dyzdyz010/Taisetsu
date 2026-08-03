import SwiftUI

struct AppRootView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            Tab("首页", systemImage: "house") {
                HomeView(repository: dependencies.repository)
            }
            Tab("日历", systemImage: "calendar") {
                CalendarView(repository: dependencies.repository)
            }
            Tab("设置", systemImage: "gearshape") {
                SettingsView(repository: dependencies.repository)
            }
        }
    }
}
