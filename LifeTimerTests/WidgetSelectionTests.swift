import Foundation
import Testing

@testable import LifeTimerCore

struct WidgetSelectionTests {
    @Test func hiddenEventsAreExcludedAndPinnedEventsLead() throws {
        let hidden = record("隐藏", day: 4, visible: false)
        let nearest = record("最近", day: 5)
        let pinned = record("置顶", day: 20, pinned: true)
        let snapshot = try WidgetSnapshot.make(
            records: [hidden, nearest, pinned],
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "zh-Hans")
        )

        #expect(snapshot.events.map(\.title) == ["置顶", "最近"])
    }

    @Test func familiesReturnOneFourAndFiveEvents() throws {
        let records = (4...10).map { record("\($0)", day: $0) }
        let snapshot = try WidgetSnapshot.make(
            records: records,
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "zh-Hans")
        )
        #expect(snapshot.events(for: .small).count == 1)
        #expect(snapshot.events(for: .medium).count == 4)
        #expect(snapshot.events(for: .large).count == 5)
    }

    private func record(
        _ title: String,
        day: Int,
        pinned: Bool = false,
        visible: Bool = true
    ) -> AnniversaryRecord {
        AnniversaryRecord(
            title: title,
            date: AnniversaryDate(year: 2026, month: 8, day: day),
            isPinned: pinned,
            isVisibleInWidget: visible
        )
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}
