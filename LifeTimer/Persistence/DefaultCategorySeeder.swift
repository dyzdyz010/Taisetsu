import Foundation
import SwiftData

@MainActor
enum DefaultCategorySeeder {
    private struct Seed {
        let id: UUID
        let name: String
        let symbolName: String
        let colorToken: String
    }

    private static let seeds = [
        Seed(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!, name: "家庭", symbolName: "house",
            colorToken: "orange"),
        Seed(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000002")!, name: "爱情", symbolName: "heart",
            colorToken: "pink"),
        Seed(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000003")!, name: "生日",
            symbolName: "birthday.cake", colorToken: "purple"),
        Seed(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000004")!, name: "健康",
            symbolName: "heart.text.square", colorToken: "green"),
        Seed(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000005")!, name: "工作",
            symbolName: "briefcase", colorToken: "blue"),
    ]

    static func seed(in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<CategoryModel>())
        let existingIDs = Set(existing.map(\.id))
        for (index, seed) in seeds.enumerated() where !existingIDs.contains(seed.id) {
            context.insert(
                CategoryModel(
                    id: seed.id,
                    name: seed.name,
                    symbolName: seed.symbolName,
                    colorToken: seed.colorToken,
                    sortOrder: index
                )
            )
        }
        try context.save()
    }
}
