import Foundation
import SwiftData

@Model
final class TagModel {
    var id: UUID = UUID()
    var name: String = ""
    var anniversaries: [AnniversaryModel]?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
