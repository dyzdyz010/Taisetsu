import Foundation
import TaisetsuCore

struct ReconciliationPlan: Sendable {
    let widgetSnapshot: WidgetSnapshot?
    let watchSnapshot: WatchSnapshot?
    let reminders: [ScheduledReminder]

    static func make(
        records: [AnniversaryRecord],
        referenceDate: Date,
        timeZone: TimeZone,
        locale: Locale,
        includesWidgetSnapshot: Bool,
        includesWatchSnapshot: Bool = false,
        reminderScheduler: ReminderScheduler
    ) throws -> ReconciliationPlan {
        let snapshot: WidgetSnapshot? =
            if includesWidgetSnapshot {
                try WidgetSnapshot.make(
                    records: records,
                    relativeTo: referenceDate,
                    timeZone: timeZone,
                    locale: locale
                )
            } else {
                nil
            }
        let watchSnapshot: WatchSnapshot? =
            if includesWatchSnapshot {
                try WatchSnapshot.make(
                    records: records,
                    relativeTo: referenceDate,
                    timeZone: timeZone,
                    locale: locale
                )
            } else {
                nil
            }
        let reminders = try reminderScheduler.makeSchedule(
            records: records,
            relativeTo: referenceDate,
            timeZone: timeZone,
            locale: locale
        )
        return ReconciliationPlan(
            widgetSnapshot: snapshot,
            watchSnapshot: watchSnapshot,
            reminders: reminders
        )
    }
}
