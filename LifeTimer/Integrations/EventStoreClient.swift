import EventKit
import Foundation

struct CalendarEventDraft: Equatable, Sendable {
    let title: String
    let notes: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

@MainActor
protocol CalendarEventClient {
    func requestAccess() async throws -> Bool
    func upsert(_ draft: CalendarEventDraft, existingIdentifier: String?) async throws -> String
}

@MainActor
final class EventStoreClient: CalendarEventClient {
    private let store: EKEventStore

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    func upsert(_ draft: CalendarEventDraft, existingIdentifier: String?) async throws -> String {
        let event = existingIdentifier.flatMap(store.event(withIdentifier:)) ?? EKEvent(eventStore: store)
        event.title = draft.title
        event.notes = draft.notes
        event.startDate = draft.startDate
        event.endDate = draft.endDate
        event.isAllDay = draft.isAllDay
        event.calendar = event.calendar ?? store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent, commit: true)
        guard let identifier = event.eventIdentifier else { throw CalendarExportError.missingIdentifier }
        return identifier
    }
}
