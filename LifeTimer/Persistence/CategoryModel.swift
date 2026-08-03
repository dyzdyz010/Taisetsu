import Foundation
import SwiftData

@Model
final class CategoryModel {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "calendar"
    var colorToken: String = "blue"
    var sortOrder: Int = 0
    @Relationship(inverse: \AnniversaryModel.category) var anniversaries: [AnniversaryModel]?

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "calendar",
        colorToken: String = "blue",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorToken = colorToken
        self.sortOrder = sortOrder
    }
}

extension CategoryModel {
    @MainActor
    func displayName(locale: Locale = .current) -> String {
        DefaultCategorySeeder.localizedName(for: id, locale: locale) ?? name
    }
}
