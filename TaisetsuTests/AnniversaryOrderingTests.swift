import Foundation
import Testing

@testable import TaisetsuCore

struct AnniversaryOrderingTests {
    @Test func pinnedItemsLeadAndUpcomingItemsUseNearestFirst() throws {
        let reference = date("2026-08-03T00:00:00Z")
        let pinned = record("置顶", day: 20, isPinned: true)
        let near = record("最近", day: 4)
        let far = record("稍后", day: 12)

        let sections = try AnniversaryOrdering().sections(
            records: [far, pinned, near],
            relativeTo: reference,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        #expect(sections.pinned.map(\.record.title) == ["置顶"])
        #expect(sections.upcoming.map(\.record.title) == ["最近", "稍后"])
    }

    @Test func endedAndCountUpRecordsUseTheirOwnSections() throws {
        let ended = record("已经结束", day: 1)
        var countUp = record("已经相伴", day: 1)
        countUp.displayMode = .countUp
        let sections = try AnniversaryOrdering().sections(
            records: [ended, countUp],
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        #expect(sections.ongoing.map(\.record.title) == ["已经相伴"])
        #expect(sections.ended.map(\.record.title) == ["已经结束"])
    }

    private func record(_ title: String, day: Int, isPinned: Bool = false) -> AnniversaryRecord {
        AnniversaryRecord(
            title: title,
            date: AnniversaryDate(year: 2026, month: 8, day: day),
            isPinned: isPinned
        )
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}
