import EventKit
import Foundation

struct CalendarEventDraft: Equatable, Sendable {
    let title: String
    let notes: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

enum CalendarAuthorizationState: Equatable, Sendable {
    case notDetermined
    case denied
    case restricted
    case writeOnly
    case fullAccess
}

struct CalendarTarget: Equatable, Sendable {
    let identifier: String
    let title: String
}

@MainActor
protocol CalendarEventClient {
    func requestAccess() async throws -> Bool
    func upsert(_ draft: CalendarEventDraft, existingIdentifier: String?) async throws -> String
    func authorizationState() -> CalendarAuthorizationState
    func ensureManagedCalendar() async throws -> CalendarTarget
    func upsert(
        _ draft: CalendarEventDraft,
        calendar: CalendarTarget,
        existingIdentifier: String?
    ) async throws -> String
    func removeEvent(identifier: String) async throws
    func eventExists(identifier: String) -> Bool
}

extension CalendarEventClient {
    func authorizationState() -> CalendarAuthorizationState { .fullAccess }

    func ensureManagedCalendar() async throws -> CalendarTarget {
        CalendarTarget(identifier: "default", title: "Taisetsu")
    }

    func upsert(
        _ draft: CalendarEventDraft,
        calendar: CalendarTarget,
        existingIdentifier: String?
    ) async throws -> String {
        try await upsert(draft, existingIdentifier: existingIdentifier)
    }

    func removeEvent(identifier: String) async throws {}
    func eventExists(identifier: String) -> Bool { true }
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

    func authorizationState() -> CalendarAuthorizationState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .restricted: .restricted
        case .writeOnly: .writeOnly
        case .fullAccess: .fullAccess
        @unknown default: .denied
        }
    }

    func ensureManagedCalendar() async throws -> CalendarTarget {
        if let calendar = store.calendars(for: .event).first(where: { $0.title == "Taisetsu" }) {
            return CalendarTarget(identifier: calendar.calendarIdentifier, title: calendar.title)
        }
        guard let source = store.defaultCalendarForNewEvents?.source else {
            throw CalendarExportError.noWritableCalendar
        }
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Taisetsu"
        calendar.source = source
        try store.saveCalendar(calendar, commit: true)
        return CalendarTarget(identifier: calendar.calendarIdentifier, title: calendar.title)
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

    func upsert(
        _ draft: CalendarEventDraft,
        calendar target: CalendarTarget,
        existingIdentifier: String?
    ) async throws -> String {
        guard let calendar = store.calendar(withIdentifier: target.identifier) else {
            throw CalendarExportError.noWritableCalendar
        }
        let event = existingIdentifier.flatMap(store.event(withIdentifier:)) ?? EKEvent(eventStore: store)
        event.title = draft.title
        event.notes = draft.notes
        event.startDate = draft.startDate
        event.endDate = draft.endDate
        event.isAllDay = draft.isAllDay
        event.calendar = calendar
        try store.save(event, span: .thisEvent, commit: true)
        guard let identifier = event.eventIdentifier else { throw CalendarExportError.missingIdentifier }
        return identifier
    }

    func removeEvent(identifier: String) async throws {
        guard let event = store.event(withIdentifier: identifier) else { return }
        try store.remove(event, span: .thisEvent, commit: true)
    }

    func eventExists(identifier: String) -> Bool {
        store.event(withIdentifier: identifier) != nil
    }
}
