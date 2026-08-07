import Foundation
import TaisetsuCore
import Testing

struct CalendarSyncScopeTests {
    private let categoryA = UUID()
    private let categoryB = UUID()
    private let tagA = UUID()
    private let tagB = UUID()

    @Test func allScopeIncludesEveryRecord() {
        let scope = CalendarSyncScope.all
        #expect(scope.includes(categoryID: nil, tagIDs: []))
        #expect(scope.includes(categoryID: categoryB, tagIDs: [tagB]))
    }

    @Test func customScopeUsesCategoryAndTagIntersection() {
        let scope = CalendarSyncScope.custom(
            categories: [categoryA],
            tags: [tagA],
            includeUncategorized: false,
            includeUntagged: false
        )
        #expect(scope.includes(categoryID: categoryA, tagIDs: [tagA, tagB]))
        #expect(!scope.includes(categoryID: categoryA, tagIDs: [tagB]))
        #expect(!scope.includes(categoryID: categoryB, tagIDs: [tagA]))
    }

    @Test func customScopeCanExplicitlyIncludeEmptyCategoryAndTags() {
        let scope = CalendarSyncScope.custom(
            categories: [],
            tags: [],
            includeUncategorized: true,
            includeUntagged: true
        )
        #expect(scope.includes(categoryID: nil, tagIDs: []))
        #expect(scope.includes(categoryID: categoryA, tagIDs: []))
        #expect(scope.includes(categoryID: nil, tagIDs: [tagA]))
    }
}
