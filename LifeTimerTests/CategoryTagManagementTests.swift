import SwiftData
import Testing

@testable import LifeTimer

@MainActor
struct CategoryTagManagementTests {
    @Test func categoryAndTagNamesAreTrimmedAndDuplicatesAreMerged() throws {
        let repository = AnniversaryRepository(
            context: ModelContext(try ModelContainerFactory.makeInMemory())
        )
        let firstCategory = try repository.saveCategory(
            name: "  家庭  ", symbolName: "house", colorToken: "orange")
        let secondCategory = try repository.saveCategory(name: "家庭", symbolName: "heart", colorToken: "pink")
        let firstTag = try repository.saveTag(name: "  旅行 ")
        let secondTag = try repository.saveTag(name: "旅行")

        #expect(firstCategory.id == secondCategory.id)
        #expect(firstTag.id == secondTag.id)
        #expect(repository.categories().count == 1)
        #expect(repository.tags().count == 1)
        #expect(repository.categories().first?.name == "家庭")
        #expect(repository.tags().first?.name == "旅行")
    }
}
