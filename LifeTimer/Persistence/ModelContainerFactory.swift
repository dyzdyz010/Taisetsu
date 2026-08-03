import LifeTimerCore
import SwiftData

enum ModelContainerFactory {
    static let schema = Schema([
        AnniversaryModel.self,
        CategoryModel.self,
        TagModel.self,
        ReminderRuleModel.self,
    ])

    static func makePersistent(cloudSyncEnabled: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "LifeTimer",
            schema: schema,
            groupContainer: .identifier(AppConfiguration.appGroupIdentifier),
            cloudKitDatabase: cloudSyncEnabled
                ? .private(AppConfiguration.cloudContainerIdentifier) : .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "LifeTimerTests",
            schema: schema,
            isStoredInMemoryOnly: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
