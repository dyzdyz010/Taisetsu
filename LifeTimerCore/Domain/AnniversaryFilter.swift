import Foundation

public struct AnniversaryFilter: Equatable, Sendable {
    public var query: String
    public var categoryID: UUID?
    public var requiredTagIDs: Set<UUID>

    public init(query: String = "", categoryID: UUID? = nil, requiredTagIDs: Set<UUID> = []) {
        self.query = query
        self.categoryID = categoryID
        self.requiredTagIDs = requiredTagIDs
    }

    public func matches(_ record: AnniversaryRecord) -> Bool {
        if let categoryID, record.category?.id != categoryID { return false }
        let tagIDs = Set(record.tags.map(\.id))
        guard requiredTagIDs.isSubset(of: tagIDs) else { return false }

        let needle = Self.normalized(query)
        guard !needle.isEmpty else { return true }
        let fields = [record.title, record.notes, record.category?.name ?? ""] + record.tags.map(\.name)
        return fields.contains { Self.normalized($0).contains(needle) }
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
    }
}
