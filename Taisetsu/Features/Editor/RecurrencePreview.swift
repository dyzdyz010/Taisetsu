import Foundation
import TaisetsuCore

enum RecurrencePreview {
    static func nextOccurrence(
        for draft: AnniversaryDraft,
        relativeTo referenceDate: Date = .now,
        timeZone: TimeZone = .current
    ) -> Date? {
        guard draft.recurrenceUnit != nil else { return nil }

        let record = AnniversaryRecord(
            title: draft.title,
            calendarKind: draft.calendarKind,
            date: draft.date,
            isAllDay: draft.isAllDay,
            recurrence: RecurrenceRule(
                unit: draft.recurrenceUnit,
                interval: draft.recurrenceInterval
            ),
            displayMode: draft.displayMode
        )

        guard
            let occurrence = try? OccurrenceCalculator().calculate(
                for: record,
                relativeTo: referenceDate,
                timeZone: timeZone
            )
        else { return nil }

        return occurrence.next
    }

    static func explainsLunarMonthInterval(for draft: AnniversaryDraft) -> Bool {
        draft.calendarKind == .chinese && draft.recurrenceUnit == .month
    }
}
