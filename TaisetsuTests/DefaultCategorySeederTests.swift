import Foundation
import SwiftData
import Testing

@testable import Taisetsu

@MainActor
struct DefaultCategorySeederTests {
    @Test func seedingTwiceCreatesExactlyFiveStableCategories() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        try DefaultCategorySeeder.seed(in: context)
        try DefaultCategorySeeder.seed(in: context)
        let categories = try context.fetch(FetchDescriptor<CategoryModel>())
        #expect(categories.count == 5)
        #expect(Set(categories.map(\.name)) == ["家庭", "爱情", "生日", "健康", "工作"])
        #expect(Set(categories.map(\.id)).count == 5)
    }

    @Test func builtInCategoryNamesFollowTheDisplayLocaleWithoutChangingStoredData() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        try DefaultCategorySeeder.seed(in: context)
        let categories = try context.fetch(FetchDescriptor<CategoryModel>())
        let family = try #require(categories.first { $0.symbolName == "house" })

        #expect(family.name == "家庭")
        #expect(family.displayName(locale: Locale(identifier: "en_US")) == "Family")
        #expect(family.displayName(locale: Locale(identifier: "zh_Hans_CN")) == "家庭")
    }
}
