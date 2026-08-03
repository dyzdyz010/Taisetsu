import LifeTimerCore
import SwiftUI

struct CalendarView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    let repository: AnniversaryRepository
    @State private var displayedMonth = Calendar.current.startOfDay(for: .now)
    @State private var records: [AnniversaryRecord] = []

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayHeader
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(monthCells, id: \.self) { cell in
                            if let date = cell {
                                dayCell(date)
                            } else {
                                Color.clear.frame(height: 52)
                            }
                        }
                    }
                    .padding(.horizontal)
                    Divider().padding(.horizontal)
                    monthEvents
                }
                .padding(.vertical)
            }
            .navigationTitle("Calendar")
            .onAppear { records = repository.fetch() }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button("Previous Month", systemImage: "chevron.left") { moveMonth(-1) }
                .labelStyle(.iconOnly)
            Spacer()
            Text(displayedMonth, format: .dateTime.year().month(.wide))
                .font(.title3.bold())
            Spacer()
            Button("Next Month", systemImage: "chevron.right") { moveMonth(1) }
                .labelStyle(.iconOnly)
        }
        .padding(.horizontal)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns) {
            ForEach(LocalizedCalendarLayout.weekdaySymbols(for: localizedCalendar), id: \.self) { symbol in
                Text(symbol).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var monthEvents: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Important Days This Month").font(.headline)
            if eventsInMonth.isEmpty {
                Text("No important days this month").foregroundStyle(.secondary)
            } else {
                ForEach(eventsInMonth) { item in
                    HStack {
                        Image(systemName: item.record.category?.symbolName ?? "calendar")
                            .foregroundStyle(
                                CategoryStyle.color(for: item.record.category?.colorToken ?? "blue"))
                        Text(item.record.title)
                        Spacer()
                        if let next = item.occurrence.next {
                            Text(next, format: .dateTime.month().day())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private func dayCell(_ date: Date) -> some View {
        let hasEvent = eventsInMonth.contains { item in
            item.occurrence.next.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        }
        return VStack(spacing: 5) {
            Text(date, format: .dateTime.day())
                .font(.body.monospacedDigit())
            Circle()
                .fill(hasEvent ? Color.accentColor : .clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(
            Calendar.current.isDateInToday(date) ? Color.accentColor.opacity(0.12) : .clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .accessibilityLabel(
            date.formatted(date: .complete, time: .omitted)
                + (hasEvent ? ", " + AppLocalization.string("has an important day", locale: locale) : "")
        )
    }

    private var eventsInMonth: [AnniversaryPresentation] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: displayedMonth) else { return [] }
        return records.compactMap { record in
            guard
                let occurrence = try? OccurrenceCalculator().calculate(
                    for: record,
                    relativeTo: interval.start,
                    timeZone: .current
                ), let next = occurrence.next, interval.contains(next)
            else { return nil }
            return AnniversaryPresentation(record: record, occurrence: occurrence)
        }
        .sorted { ($0.occurrence.next ?? .distantFuture) < ($1.occurrence.next ?? .distantFuture) }
    }

    private var monthCells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth),
            let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth)
        else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading)
            + dayRange.compactMap { day in calendar.date(byAdding: .day, value: day - 1, to: interval.start) }
            .map(Optional.some)
    }

    private func moveMonth(_ value: Int) {
        displayedMonth =
            Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private var localizedCalendar: Calendar {
        var value = calendar
        value.locale = locale
        return value
    }
}
