import Foundation

public enum CalendarSyncScope: Codable, Equatable, Sendable {
    case all
    case custom(
        categories: Set<UUID>,
        tags: Set<UUID>,
        includeUncategorized: Bool,
        includeUntagged: Bool
    )

    public func includes(categoryID: UUID?, tagIDs: [UUID]) -> Bool {
        switch self {
        case .all:
            return true
        case .custom(let categories, let tags, let includeUncategorized, let includeUntagged):
            let categoryMatches: Bool
            if let categoryID {
                categoryMatches = categories.isEmpty || categories.contains(categoryID)
            } else {
                categoryMatches = includeUncategorized
            }
            let recordTags = Set(tagIDs)
            let tagMatches: Bool
            if recordTags.isEmpty {
                tagMatches = tags.isEmpty ? includeUntagged : includeUntagged
            } else {
                tagMatches = tags.isEmpty || !recordTags.isDisjoint(with: tags)
            }
            return categoryMatches && tagMatches
        }
    }
}
