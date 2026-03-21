import SwiftUI

enum SummaryRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

struct SummaryView: View {
    @EnvironmentObject private var sessionController: SessionController
    @Binding var range: SummaryRange
    let sessions: [Session]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Range", selection: $range) {
                ForEach(SummaryRange.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            RangeChartView(range: range, sessions: sessions)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(TimeFormatter.hoursMinutes(from: totalDuration))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dateRangeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }

    private var totalDuration: TimeInterval {
        let interval = dateInterval
        return sessions.reduce(0) { partial, session in
            let segments = (session.segments as? Set<SessionSegment>) ?? []
            let segmentTotal = segments.reduce(0) { subtotal, segment in
                let start = segment.startAt ?? sessionController.now
                let end = segment.endAt ?? sessionController.now
                if end <= interval.start || start >= interval.end {
                    return subtotal
                }
                let clampedStart = max(start, interval.start)
                let clampedEnd = min(end, interval.end)
                return subtotal + max(0, clampedEnd.timeIntervalSince(clampedStart))
            }
            return partial + segmentTotal
        }
    }

    private var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = sessionController.now
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

    private var label: String {
        switch range {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }

    private var dateRangeDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: dateInterval.start)) – \(formatter.string(from: dateInterval.end))"
    }
}

#Preview {
    SummaryView(range: .constant(.week), sessions: [])
        .environmentObject(SessionController(viewContext: PersistenceController.preview.container.viewContext))
        .padding()
}
