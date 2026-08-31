import Foundation

public struct CalendarDayKey: Hashable, Sendable {
    public let era: Int
    public let year: Int
    public let month: Int
    public let day: Int

    public init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        era = components.era ?? 0
        year = components.year ?? 0
        month = components.month ?? 0
        day = components.day ?? 0
    }
}

public struct CalendarMonthSnapshot: Equatable, Sendable {
    public let month: Date
    public let cells: [Date?]
    public let events: [AnniversaryPresentation]
    public let eventDays: Set<CalendarDayKey>

    public init(
        month: Date,
        cells: [Date?],
        events: [AnniversaryPresentation],
        eventDays: Set<CalendarDayKey>
    ) {
        self.month = month
        self.cells = cells
        self.events = events
        self.eventDays = eventDays
    }

    public func hasEvent(on date: Date, calendar: Calendar) -> Bool {
        eventDays.contains(CalendarDayKey(date: date, calendar: calendar))
    }
}

public struct CalendarMonthBuilder: Sendable {
    typealias Calculate = @Sendable (AnniversaryRecord, Date, TimeZone) throws -> Occurrence

    private let calculate: Calculate

    public init() {
        calculate = { record, referenceDate, timeZone in
            try OccurrenceCalculator().calculate(
                for: record,
                relativeTo: referenceDate,
                timeZone: timeZone
            )
        }
    }

    init(calculate: @escaping Calculate) {
        self.calculate = calculate
    }

    public func make(
        records: [AnniversaryRecord],
        month: Date,
        calendar inputCalendar: Calendar,
        timeZone: TimeZone
    ) throws -> CalendarMonthSnapshot {
        var calendar = inputCalendar
        calendar.timeZone = timeZone
        guard
            let interval = calendar.dateInterval(of: .month, for: month),
            let dayRange = calendar.range(of: .day, in: .month, for: interval.start)
        else {
            return CalendarMonthSnapshot(month: month, cells: [], events: [], eventDays: [])
        }

        let weekday = calendar.component(.weekday, from: interval.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let days = dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
        let cells = [Date?](repeating: nil, count: leading) + days.map(Optional.some)

        var events: [AnniversaryPresentation] = []
        events.reserveCapacity(records.count)
        for record in records {
            try Task.checkCancellation()
            let occurrence = try calculate(record, interval.start, timeZone)
            guard let next = occurrence.next, interval.contains(next) else { continue }
            events.append(AnniversaryPresentation(record: record, occurrence: occurrence))
        }
        events.sort { lhs, rhs in
            let left = lhs.occurrence.next ?? .distantFuture
            let right = rhs.occurrence.next ?? .distantFuture
            if left != right { return left < right }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        let eventDays = Set(
            events.compactMap(\.occurrence.next).map {
                CalendarDayKey(date: $0, calendar: calendar)
            }
        )
        return CalendarMonthSnapshot(
            month: interval.start,
            cells: cells,
            events: events,
            eventDays: eventDays
        )
    }
}
