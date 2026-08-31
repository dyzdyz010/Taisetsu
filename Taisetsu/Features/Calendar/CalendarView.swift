import SwiftUI
import TaisetsuCore

struct CalendarView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @State private var viewModel: CalendarViewModel

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    init(repository: AnniversaryRepository) {
        _viewModel = State(initialValue: CalendarViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayHeader
                    if let snapshot = viewModel.currentSnapshot(calendar: localizedCalendar) {
                        monthGrid(snapshot)
                        Divider().padding(.horizontal)
                        monthEvents(snapshot.events)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 280)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Calendar")
            .task(id: viewModel.displayedMonth) {
                await viewModel.refresh(calendar: localizedCalendar, timeZone: .current)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button("Previous Month", systemImage: "chevron.left") {
                viewModel.moveMonth(-1, calendar: localizedCalendar)
            }
            .labelStyle(.iconOnly)
            .accessibilityIdentifier("calendar-previous-month")
            Spacer()
            Text(viewModel.displayedMonth, format: .dateTime.year().month(.wide))
                .font(.title3.bold())
                .accessibilityIdentifier("calendar-month-title")
            Spacer()
            Button("Next Month", systemImage: "chevron.right") {
                viewModel.moveMonth(1, calendar: localizedCalendar)
            }
            .labelStyle(.iconOnly)
            .accessibilityIdentifier("calendar-next-month")
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

    private func monthGrid(_ snapshot: CalendarMonthSnapshot) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(snapshot.cells, id: \.self) { cell in
                if let date = cell {
                    dayCell(date, hasEvent: snapshot.hasEvent(on: date, calendar: localizedCalendar))
                } else {
                    Color.clear.frame(height: 52)
                }
            }
        }
        .padding(.horizontal)
    }

    private func monthEvents(_ events: [AnniversaryPresentation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Important Days This Month").font(.headline)
            if events.isEmpty {
                Text("No important days this month").foregroundStyle(.secondary)
            } else {
                ForEach(events) { item in
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

    private func dayCell(_ date: Date, hasEvent: Bool) -> some View {
        VStack(spacing: 5) {
            Text(date, format: .dateTime.day())
                .font(.body.monospacedDigit())
            Circle()
                .fill(hasEvent ? Color.accentColor : .clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(
            localizedCalendar.isDateInToday(date) ? Color.accentColor.opacity(0.12) : .clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .accessibilityLabel(
            date.formatted(date: .complete, time: .omitted)
                + (hasEvent ? ", " + AppLocalization.string("has an important day", locale: locale) : "")
        )
    }

    private var localizedCalendar: Calendar {
        var value = calendar
        value.locale = locale
        return value
    }
}
