import SwiftUI

enum SummaryRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

func summaryDateInterval(range: SummaryRange, now: Date) -> DateInterval {
    let calendar = Calendar.current
    switch range {
    case .day:
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return DateInterval(start: start, end: end)
    case .week:
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let end = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
        return DateInterval(start: weekStart, end: end)
    case .month:
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let end = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now
        return DateInterval(start: monthStart, end: end)
    case .year:
        let yearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
        let end = calendar.date(byAdding: .year, value: 1, to: yearStart) ?? now
        return DateInterval(start: yearStart, end: end)
    }
}

struct SummaryView: View {
    @AppStorage("showEarnings") private var showEarnings = false
    @AppStorage("currencyCode") private var currencyCode = CurrencyOption.usd.rawValue

    @Binding var range: SummaryRange
    let sessions: [Session]
    let projects: [Project]

    @State private var showRangePicker = false
    @State private var useCustomRange = false
    @State private var customStart = Calendar.current.startOfDay(for: Date())
    @State private var customEnd = Calendar.current.startOfDay(for: Date())

    var body: some View {
        let now = Date()
        let interval = resolvedInterval(now: now)
        let total = TimeMetrics.totalDuration(sessions: sessions, in: interval, now: now)
        let earnings = TimeMetrics.earnings(sessions: sessions, projects: projects, in: interval, now: now)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Range")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SegmentedTabs(items: SummaryRange.allCases, selection: $range) { $0.rawValue }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button {
                        showRangePicker.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                            Text(rangeLabel(interval: interval))
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .font(.callout)
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 220)
                        .background(AppTheme.cardBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showRangePicker) {
                        CalendarRangePicker(start: $customStart, end: $customEnd, useCustomRange: $useCustomRange)
                            .frame(width: 320)
                            .padding(16)
                    }
                }

                Spacer()

                Toggle("Show Earnings", isOn: $showEarnings)
                    .toggleStyle(.switch)
            }

            SimpleRangeChart(sessions: sessions, interval: interval)
                .frame(height: 110)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(TimeFormatter.hoursMinutes(from: total))
                        .font(.title2)
                        .fontWeight(.semibold)

                    if showEarnings {
                        Text("Earnings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 6)
                        Text(CurrencyFormatter.string(from: earnings, currencyCode: currencyCode))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Selected Range")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dateRangeDescription(interval: interval))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .cardStyle()
        }
    }

    private func resolvedInterval(now: Date) -> DateInterval {
        if useCustomRange {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: min(customStart, customEnd))
            var end = calendar.startOfDay(for: max(customStart, customEnd))
            if calendar.isDate(start, inSameDayAs: end) {
                end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
            }
            return DateInterval(start: start, end: end)
        }
        return summaryDateInterval(range: range, now: now)
    }

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private func rangeLabel(interval: DateInterval) -> String {
        let formatter = Self.mediumDateFormatter
        let display = displayRange(interval: interval)
        if useCustomRange {
            return "\(formatter.string(from: customStart)) – \(formatter.string(from: customEnd))"
        }
        return "\(formatter.string(from: display.start)) – \(formatter.string(from: display.end))"
    }

    private func dateRangeDescription(interval: DateInterval) -> String {
        let formatter = Self.mediumDateFormatter
        let display = displayRange(interval: interval)
        if useCustomRange {
            return "\(formatter.string(from: customStart)) – \(formatter.string(from: customEnd))"
        }
        return "\(formatter.string(from: display.start)) – \(formatter.string(from: display.end))"
    }

    private func displayRange(interval: DateInterval) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = interval.start
        let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        return (start, end)
    }

}

#Preview {
    SummaryView(range: .constant(.week), sessions: [], projects: [])
        .padding()
}
