import Foundation
import TaisetsuCore
import UserNotifications

struct ScheduledReminder: Equatable, Sendable {
    let identifier: String
    let anniversaryID: UUID
    let fireDate: Date
    let title: String
    let body: String
}

struct ReminderScheduler: Sendable {
    static let systemLimit = 64

    func makeSchedule(
        records: [AnniversaryRecord],
        relativeTo referenceDate: Date,
        timeZone: TimeZone,
        locale: Locale = .current,
        horizonDays: Int = 400
    ) throws -> [ScheduledReminder] {
        let horizon =
            Calendar.current.date(byAdding: .day, value: horizonDays, to: referenceDate)
            ?? referenceDate.addingTimeInterval(TimeInterval(horizonDays * 86_400))
        var scheduled: [ScheduledReminder] = []
        for record in records where record.reminders.contains(where: { $0.isEnabled }) {
            var cursor = referenceDate
            var occurrenceCount = 0
            while cursor <= horizon && occurrenceCount < Self.systemLimit {
                let occurrence = try OccurrenceCalculator().calculate(
                    for: record,
                    relativeTo: cursor,
                    timeZone: timeZone
                )
                guard let eventDate = occurrence.next, eventDate <= horizon else { break }
                for reminder in record.reminders where reminder.isEnabled {
                    let fireDate = eventDate.addingTimeInterval(TimeInterval(reminder.offsetMinutes * 60))
                    guard fireDate > referenceDate else { continue }
                    scheduled.append(
                        ScheduledReminder(
                            identifier: identifier(
                                anniversaryID: record.id,
                                reminderID: reminder.id,
                                fireDate: fireDate
                            ),
                            anniversaryID: record.id,
                            fireDate: fireDate,
                            title: record.title,
                            body: notificationBody(
                                eventDate: eventDate,
                                referenceDate: fireDate,
                                locale: locale
                            )
                        )
                    )
                }
                guard record.recurrence.unit != nil else { break }
                cursor = eventDate.addingTimeInterval(record.isAllDay ? 86_400 : 60)
                occurrenceCount += 1
            }
        }
        return Array(
            scheduled.sorted {
                $0.fireDate == $1.fireDate ? $0.identifier < $1.identifier : $0.fireDate < $1.fireDate
            }.prefix(Self.systemLimit)
        )
    }

    @MainActor
    func reconcile(
        records: [AnniversaryRecord],
        client: NotificationCenterClientProtocol,
        relativeTo referenceDate: Date = .now,
        timeZone: TimeZone = .current,
        locale: Locale = .current
    ) async throws {
        let requests = try makeSchedule(
            records: records,
            relativeTo: referenceDate,
            timeZone: timeZone,
            locale: locale
        )
        if requests.isEmpty {
            try await client.replaceTaisetsuRequests(with: [])
            return
        }
        let status = await client.authorizationStatus()
        let authorized: Bool
        switch status {
        case .notDetermined:
            authorized = try await client.requestAuthorization()
        case .authorized, .provisional, .ephemeral:
            authorized = true
        default:
            authorized = false
        }
        if authorized { try await client.replaceTaisetsuRequests(with: requests) }
    }

    private func identifier(anniversaryID: UUID, reminderID: UUID, fireDate: Date) -> String {
        "taisetsu.\(anniversaryID.uuidString).\(reminderID.uuidString).\(Int(fireDate.timeIntervalSince1970))"
    }

    private func notificationBody(eventDate: Date, referenceDate: Date, locale: Locale) -> String {
        let days = Calendar.current.dateComponents([.day], from: referenceDate, to: eventDate).day ?? 0
        return days > 0
            ? AnniversaryFormatters.relativeDays(days, locale: locale)
            : AppLocalization.string("Coming up", locale: locale)
    }
}
