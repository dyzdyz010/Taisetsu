import SwiftData
import Testing

@testable import Taisetsu

@MainActor
struct AppStoreScreenshotDataTests {
    @Test func seedPopulatesAnEmptyRepositoryExactlyOnce() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let dependencies = try AppDependencies(container: container)

        try AppStoreScreenshotData.seed(repository: dependencies.repository)
        try AppStoreScreenshotData.seed(repository: dependencies.repository)

        let records = dependencies.repository.fetch()
        #expect(records.count == 6)
        #expect(records.filter(\.isPinned).count == 1)
        #expect(records.contains { $0.title == "我们的纪念日" })
        #expect(records.contains { $0.displayMode == .countUp })
    }

    @Test func initialSectionReadsTheValueFollowingItsLaunchArgument() {
        #expect(
            AppStoreScreenshotData.initialSection(
                in: ["Taisetsu", "-app-store-section", "calendar"]
            ) == "calendar"
        )
        #expect(AppStoreScreenshotData.initialSection(in: ["Taisetsu"]) == nil)
        #expect(
            AppStoreScreenshotData.initialSection(
                in: ["Taisetsu", "-app-store-section"]
            ) == nil
        )
    }
}
