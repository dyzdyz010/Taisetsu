import SwiftData
import SwiftUI

@main
struct LifeTimerApp: App {
    private let container: ModelContainer?
    private let dependencies: AppDependencies?
    private let startupError: String?

    @MainActor
    init() {
        do {
            let appContainer: ModelContainer
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                appContainer = try ModelContainerFactory.makeInMemory()
            } else {
                do {
                    appContainer = try ModelContainerFactory.makePersistent(cloudSyncEnabled: true)
                } catch {
                    appContainer = try ModelContainerFactory.makePersistent(cloudSyncEnabled: false)
                }
            }
            let appDependencies = try AppDependencies(container: appContainer)
            container = appContainer
            dependencies = appDependencies
            startupError = nil
        } catch {
            container = nil
            dependencies = nil
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container, let dependencies {
                AppRootView(dependencies: dependencies)
                    .modelContainer(container)
            } else {
                ContentUnavailableView(
                    "无法打开数据",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(startupError ?? "请稍后重试")
                )
            }
        }
    }
}
