import Foundation
import Testing

@testable import LifeTimerCore

struct AnniversaryFilterTests {
    @Test func querySearchesTitleNotesCategoryAndTagsWithFolding() {
        let categoryID = UUID()
        let familyTag = TagReference(id: UUID(), name: "家人")
        let travelTag = TagReference(id: UUID(), name: "旅行")
        let record = AnniversaryRecord(
            title: "Café 周年",
            notes: "第一次见面",
            date: AnniversaryDate(year: 2026, month: 8, day: 8),
            category: CategoryReference(id: categoryID, name: "爱情"),
            tags: [familyTag, travelTag]
        )

        #expect(AnniversaryFilter(query: "cafe").matches(record))
        #expect(AnniversaryFilter(query: "  第一次  ").matches(record))
        #expect(AnniversaryFilter(query: "爱情").matches(record))
        #expect(AnniversaryFilter(query: "旅行").matches(record))
    }

    @Test func categoryAndAllSelectedTagsMustMatchTogether() {
        let categoryID = UUID()
        let first = TagReference(id: UUID(), name: "一")
        let second = TagReference(id: UUID(), name: "二")
        let record = AnniversaryRecord(
            title: "组合筛选",
            date: AnniversaryDate(year: 2026, month: 8, day: 8),
            category: CategoryReference(id: categoryID, name: "工作"),
            tags: [first, second]
        )

        #expect(
            AnniversaryFilter(categoryID: categoryID, requiredTagIDs: [first.id, second.id]).matches(record)
        )
        #expect(!AnniversaryFilter(categoryID: UUID(), requiredTagIDs: [first.id]).matches(record))
        #expect(!AnniversaryFilter(categoryID: categoryID, requiredTagIDs: [UUID()]).matches(record))
    }
}
