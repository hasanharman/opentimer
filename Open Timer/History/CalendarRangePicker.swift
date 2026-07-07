import SwiftUI

struct CalendarRangePicker: View {
    @Binding var start: Date
    @Binding var end: Date
    @Binding var useCustomRange: Bool

    @State private var monthAnchor: Date = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            weekdayHeader
            daysGrid
            footer
        }
        .onAppear {
            monthAnchor = calendar.dateInterval(of: .month, for: start)?.start ?? startOfDay(Date())
        }
    }

    private var header: some View {
        HStack {
            Button {
                monthAnchor = calendar.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle(for: monthAnchor))
                .font(.headline)

            Spacer()

            Button {
                monthAnchor = calendar.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        let days = monthDays(for: monthAnchor)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(days, id: \.self) { date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 28)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelectedStart = isSameDay(date, start)
        let isSelectedEnd = isSameDay(date, end)
        let inRange = isInRange(date)
        let isEdge = isSelectedStart || isSelectedEnd

        return Button {
            select(date)
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isEdge ? .semibold : .regular)
                .frame(width: 28, height: 28)
                .foregroundColor(isEdge ? .white : .primary)
                .background(
                    ZStack {
                        if inRange {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor.opacity(0.18))
                        }
                        if isEdge {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Button("Reset") {
                useCustomRange = false
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            Text(rangeLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func select(_ date: Date) {
        let day = startOfDay(date)
        if !useCustomRange {
            start = day
            end = day
            useCustomRange = true
            return
        }

        if start <= end {
            if day < start {
                start = day
            } else if day > end {
                end = day
            } else {
                start = day
                end = day
            }
        } else {
            start = min(start, end)
            end = max(start, end)
        }

        if start > end {
            swap(&start, &end)
        }
    }

    private func isInRange(_ date: Date) -> Bool {
        guard useCustomRange else { return false }
        let day = startOfDay(date)
        let lower = startOfDay(start)
        let upper = startOfDay(end)
        return day >= min(lower, upper) && day <= max(lower, upper)
    }

    private func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private func monthTitle(for date: Date) -> String {
        Self.monthTitleFormatter.string(from: date)
    }

    private func monthDays(for date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday,
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }

        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }

        return days
    }

    private var rangeLabel: String {
        let formatter = Self.mediumDateFormatter
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
}

#Preview {
    CalendarRangePicker(
        start: .constant(Calendar.current.startOfDay(for: Date())),
        end: .constant(Calendar.current.startOfDay(for: Date())),
        useCustomRange: .constant(true)
    )
    .padding()
    .frame(width: 320)
}
