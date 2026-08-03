import Foundation
import Testing

@testable import LifeTimer
@testable import LifeTimerCore

@MainActor
struct CalendarExportServiceTests {
    @Test func exportUsesOnlyNextOccurrenceAndReusesExistingIdentifier() async throws {
        let client = CalendarClientSpy()
        let service = CalendarExportService(client: client)
        let record = AnniversaryRecord(
            title: "结婚纪念日",
            notes: "晚餐",
            date: AnniversaryDate(year: 2024, month: 8, day: 8),
            recurrence: RecurrenceRule(unit: .year, interval: 1),
            calendarEventIdentifier: "existing-event"
        )
        let identifier = try await service.export(
            record: record,
            relativeTo: date("2026-08-03T00:00:00Z"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        #expect(identifier == "saved-event")
        #expect(client.existingIdentifier == "existing-event")
        #expect(client.draft?.startDate == date("2026-08-08T00:00:00Z"))
        #expect(client.draft?.endDate == date("2026-08-09T00:00:00Z"))
        #expect(client.draft?.isAllDay == true)
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}

@MainActor
private final class CalendarClientSpy: CalendarEventClient {
    var draft: CalendarEventDraft?
    var existingIdentifier: String?

    func requestAccess() async throws -> Bool { true }

    func upsert(_ draft: CalendarEventDraft, existingIdentifier: String?) async throws -> String {
        self.draft = draft
        self.existingIdentifier = existingIdentifier
        return "saved-event"
    }
}
