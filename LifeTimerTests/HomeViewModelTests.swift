import Foundation
import SwiftData
import Testing

@testable import LifeTimer
@testable import LifeTimerCore

@MainActor
struct HomeViewModelTests {
    @Test func loadMovesFromEmptyToContent() throws {
        let repository = try makeRepository()
        let viewModel = HomeViewModel(repository: repository, now: { Self.referenceDate })
        viewModel.load()
        #expect(viewModel.state == .empty)

        var draft = AnniversaryDraft()
        draft.title = "明天"
        draft.date = AnniversaryDate(year: 2026, month: 8, day: 4)
        _ = try repository.save(draft: draft)
        viewModel.load()
        #expect(viewModel.state == .content)
        #expect(viewModel.hero?.record.title == "明天")
    }

    @Test func queryAndPinRefreshVisibleSections() throws {
        let repository = try makeRepository()
        for (title, day) in [("生日", 4), ("旅行", 5)] {
            var draft = AnniversaryDraft()
            draft.title = title
            draft.date = AnniversaryDate(year: 2026, month: 8, day: day)
            _ = try repository.save(draft: draft)
        }
        let viewModel = HomeViewModel(repository: repository, now: { Self.referenceDate })
        viewModel.load()
        viewModel.query = "旅行"
        #expect(viewModel.sections.upcoming.map(\.record.title) == ["旅行"])

        let travelID = try #require(viewModel.sections.upcoming.first?.id)
        try viewModel.setPinned(id: travelID, isPinned: true)
        #expect(viewModel.sections.pinned.map(\.record.title) == ["旅行"])
    }

    private func makeRepository() throws -> AnniversaryRepository {
        AnniversaryRepository(context: ModelContext(try ModelContainerFactory.makeInMemory()))
    }

    private static let referenceDate = ISO8601DateFormatter().date(from: "2026-08-03T00:00:00Z")!
}
