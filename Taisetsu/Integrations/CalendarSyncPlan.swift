import Foundation
import TaisetsuCore

struct CalendarSyncPlannedEvent: Sendable {
    let anniversaryID: UUID
    let occurrenceKey: String
    let occurrenceDate: Date
    let legacyEventIdentifier: String?
    let draft: CalendarEventDraft

    var entryKey: String { "\(anniversaryID.uuidString):\(occurrenceKey)" }
}

struct CalendarSyncPlan: Sendable {
    let events: [CalendarSyncPlannedEvent]
    let desiredEntryKeys: Set<String>
}

struct CalendarSyncPlanBuilder: Sendable {
    private let calculator = OccurrenceCalculator()

    func make(
        records: [AnniversaryRecord],
        settings: CalendarSyncSettings,
        now: Date,
        timeZone: TimeZone,
        locale: Locale
    ) throws -> CalendarSyncPlan {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let end = calendar.date(byAdding: .year, value: settings.horizonYears, to: now)!

        var events: [CalendarSyncPlannedEvent] = []
        for record in records
        where settings.scope.includes(
            categoryID: record.category?.id,
            tagIDs: record.tags.map(\.id)
        ) {
            try Task.checkCancellation()
            let occurrences = try calculator.occurrences(
                for: record,
                from: now,
                through: end,
                maxCount: 128,
                timeZone: timeZone
            )
            events.append(
                contentsOf: occurrences.map { occurrence in
                    CalendarSyncPlannedEvent(
                        anniversaryID: record.id,
                        occurrenceKey: String(occurrence.sequence),
                        occurrenceDate: occurrence.date,
                        legacyEventIdentifier: record.calendarEventIdentifier,
                        draft: draft(
                            for: record,
                            occurrence: occurrence,
                            calendar: calendar,
                            locale: locale
                        )
                    )
                }
            )
        }
        events.sort {
            $0.occurrenceDate == $1.occurrenceDate
                ? $0.entryKey < $1.entryKey
                : $0.occurrenceDate < $1.occurrenceDate
        }
        events = Array(events.prefix(1_000))
        return CalendarSyncPlan(
            events: events,
            desiredEntryKeys: Set(events.map(\.entryKey))
        )
    }

    private func draft(
        for record: AnniversaryRecord,
        occurrence: ScheduledOccurrence,
        calendar: Calendar,
        locale: Locale
    ) -> CalendarEventDraft {
        let end = calendar.date(
            byAdding: record.isAllDay ? .day : .hour,
            value: 1,
            to: occurrence.date
        )!
        let attribution = AppLocalization.string("Created with Taisetsu", locale: locale)
        let notes = record.notes.isEmpty ? attribution : "\(record.notes)\n\n\(attribution)"
        return CalendarEventDraft(
            title: record.title,
            notes: notes,
            startDate: occurrence.date,
            endDate: end,
            isAllDay: record.isAllDay
        )
    }
}
