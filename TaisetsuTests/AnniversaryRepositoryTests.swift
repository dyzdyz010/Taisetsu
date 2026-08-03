import Foundation
import SwiftData
import Testing

@testable import Taisetsu
@testable import TaisetsuCore

@MainActor
struct AnniversaryRepositoryTests {
    @Test func emptyTitleAndInvalidIntervalAreRejected() throws {
        let repository = try makeRepository()
        var draft = AnniversaryDraft()
        draft.title = "   "
        #expect(throws: AnniversaryValidationError.emptyTitle) {
            try repository.save(draft: draft)
        }
        draft.title = "纪念日"
        draft.recurrenceUnit = .month
        draft.recurrenceInterval = 0
        #expect(throws: AnniversaryValidationError.invalidRecurrenceInterval) {
            try repository.save(draft: draft)
        }
    }

    @Test func createUpdatePinAndDeleteRoundTrip() throws {
        let repository = try makeRepository()
        var draft = AnniversaryDraft()
        draft.title = "相识纪念日"
        draft.notes = "第一次见面的日子"
        draft.date = AnniversaryDate(year: 2026, month: 8, day: 8)

        let created = try repository.save(draft: draft)
        #expect(repository.fetch().map(\.title) == ["相识纪念日"])

        draft = AnniversaryDraft(record: created)
        draft.title = "我们的相识纪念日"
        _ = try repository.save(draft: draft)
        try repository.setPinned(id: created.id, isPinned: true)
        #expect(repository.fetch().first?.title == "我们的相识纪念日")
        #expect(repository.fetch().first?.isPinned == true)

        try repository.delete(id: created.id)
        #expect(repository.fetch().isEmpty)
    }

    @Test func categoryTagsAndRemindersMapToDomainRecord() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        let category = CategoryModel(name: "爱情", symbolName: "heart", colorToken: "pink")
        let firstTag = TagModel(name: "家人")
        let secondTag = TagModel(name: "旅行")
        context.insert(category)
        context.insert(firstTag)
        context.insert(secondTag)
        try context.save()
        let repository = AnniversaryRepository(context: context)
        var draft = AnniversaryDraft()
        draft.title = "组合关系"
        draft.categoryID = category.id
        draft.tagIDs = [firstTag.id, secondTag.id]
        draft.reminders = [ReminderSpec(offsetMinutes: -1_440), ReminderSpec(offsetMinutes: -60)]

        let record = try repository.save(draft: draft)
        #expect(record.category?.name == "爱情")
        #expect(Set(record.tags.map(\.name)) == ["家人", "旅行"])
        #expect(record.reminders.map(\.offsetMinutes).sorted() == [-1_440, -60])
    }

    private func makeRepository() throws -> AnniversaryRepository {
        AnniversaryRepository(context: ModelContext(try ModelContainerFactory.makeInMemory()))
    }
}
