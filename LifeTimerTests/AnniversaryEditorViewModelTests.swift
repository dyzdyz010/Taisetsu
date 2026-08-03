import SwiftData
import Testing

@testable import LifeTimer
@testable import LifeTimerCore

@MainActor
struct AnniversaryEditorViewModelTests {
    @Test func invalidDraftIsPreservedAndValidDraftSavesAllChoices() throws {
        let repository = try makeRepository()
        let viewModel = AnniversaryEditorViewModel(repository: repository)
        viewModel.draft.title = "   "
        #expect(viewModel.save() == false)
        #expect(viewModel.draft.title == "   ")
        #expect(viewModel.errorMessage != nil)

        viewModel.draft.title = "农历生日"
        viewModel.draft.calendarKind = .chinese
        viewModel.draft.date = AnniversaryDate(year: 2026, month: 8, day: 15)
        viewModel.draft.recurrenceUnit = .year
        viewModel.draft.recurrenceInterval = 2
        viewModel.draft.displayMode = .both
        viewModel.draft.reminders = [ReminderSpec(offsetMinutes: -60), ReminderSpec(offsetMinutes: -10_080)]
        viewModel.draft.isPinned = true
        viewModel.draft.isVisibleInWidget = false
        #expect(viewModel.save())

        let saved = try #require(repository.fetch().first)
        #expect(saved.calendarKind == .chinese)
        #expect(saved.recurrence == RecurrenceRule(unit: .year, interval: 2))
        #expect(saved.displayMode == .both)
        #expect(saved.reminders.count == 2)
        #expect(saved.isPinned)
        #expect(!saved.isVisibleInWidget)
    }

    @Test func editingStartsFromExistingRecord() throws {
        let repository = try makeRepository()
        var draft = AnniversaryDraft()
        draft.title = "旧名称"
        let record = try repository.save(draft: draft)
        let viewModel = AnniversaryEditorViewModel(repository: repository, record: record)
        #expect(viewModel.draft.id == record.id)
        #expect(viewModel.draft.title == "旧名称")
    }

    @Test func dateWheelClampsGregorianDayWhenMonthOrYearChanges() {
        var date = AnniversaryDate(year: 2024, month: 2, day: 31)
        DateWheelSelection.normalize(&date, calendarKind: .gregorian)
        #expect(date.day == 29)

        date.year = 2023
        DateWheelSelection.normalize(&date, calendarKind: .gregorian)
        #expect(date.day == 28)
    }

    @Test func recurrenceToggleUsesYearlyDefaultAndCanonicalNoneState() {
        var draft = AnniversaryDraft()
        RecurrenceEditorSelection.setEnabled(true, draft: &draft)
        #expect(draft.recurrenceUnit == .year)
        #expect(draft.recurrenceInterval == 1)

        draft.recurrenceInterval = 3
        RecurrenceEditorSelection.setEnabled(false, draft: &draft)
        #expect(draft.recurrenceUnit == nil)
        #expect(draft.recurrenceInterval == 1)
    }

    private func makeRepository() throws -> AnniversaryRepository {
        AnniversaryRepository(context: ModelContext(try ModelContainerFactory.makeInMemory()))
    }
}
