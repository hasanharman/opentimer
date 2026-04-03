import SwiftUI

struct SimpleRangeChart: View {
    let sessions: [Session]
    let interval: DateInterval

    private let calendar = Calendar.current

    var body: some View {
        let buckets = makeBuckets()
        let maxValue = max(buckets.map(\.hours).max() ?? 1, 0.25)
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(buckets.indices, id: \.self) { index in
                    let item = buckets[index]
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(item.hours > 0 ? 0.9 : 0.2))
                        .frame(height: max(4, CGFloat(item.hours / maxValue) * 70))
                }
            }
            HStack(spacing: 6) {
                ForEach(buckets.indices, id: \.self) { index in
                    let item = buckets[index]
                    Text(item.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func makeBuckets() -> [Bucket] {
        let days = max(1, Int(interval.duration / 86400))
        if days <= 1 {
            return hourBuckets()
        }
        if days <= 31 {
            return dayBuckets()
        }
        if days <= 180 {
            return weekBuckets()
        }
        return monthBuckets()
    }

    private func hourBuckets() -> [Bucket] {
        var result: [Bucket] = []
        let start = calendar.startOfDay(for: interval.start)
        for hour in 0..<24 {
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: start),
                  let hourEnd = calendar.date(byAdding: .hour, value: hour + 1, to: start) else { continue }
            let bucketInterval = DateInterval(start: hourStart, end: hourEnd)
            let hours = TimeMetrics.totalDuration(sessions: sessions, in: bucketInterval, now: Date()) / 3600.0
            let label = hour % 4 == 0 ? "\(hour)" : ""
            result.append(Bucket(label: label, hours: hours))
        }
        return result
    }

    private func dayBuckets() -> [Bucket] {
        var result: [Bucket] = []
        let start = calendar.startOfDay(for: interval.start)
        let dayCount = max(1, Int(interval.duration / 86400))
        for offset in 0..<dayCount {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let bucketInterval = DateInterval(start: dayStart, end: min(dayEnd, interval.end))
            let hours = TimeMetrics.totalDuration(sessions: sessions, in: bucketInterval, now: Date()) / 3600.0
            let label = offset % max(1, dayCount / 6) == 0 ? "\(calendar.component(.day, from: day))" : ""
            result.append(Bucket(label: label, hours: hours))
        }
        return result
    }

    private func weekBuckets() -> [Bucket] {
        var result: [Bucket] = []
        var cursor = calendar.dateInterval(of: .weekOfYear, for: interval.start)?.start ?? interval.start
        while cursor < interval.end {
            let weekStart = cursor
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let bucketInterval = DateInterval(start: weekStart, end: min(weekEnd, interval.end))
            let hours = TimeMetrics.totalDuration(sessions: sessions, in: bucketInterval, now: Date()) / 3600.0
            let label = weekStart.formatted(.dateTime.month(.abbreviated).day())
            result.append(Bucket(label: label, hours: hours))
            cursor = weekEnd
        }
        return result
    }

    private func monthBuckets() -> [Bucket] {
        var result: [Bucket] = []
        var cursor = calendar.dateInterval(of: .month, for: interval.start)?.start ?? interval.start
        while cursor < interval.end {
            let monthStart = cursor
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            let bucketInterval = DateInterval(start: monthStart, end: min(monthEnd, interval.end))
            let hours = TimeMetrics.totalDuration(sessions: sessions, in: bucketInterval, now: Date()) / 3600.0
            let label = monthStart.formatted(.dateTime.month(.abbreviated))
            result.append(Bucket(label: label, hours: hours))
            cursor = monthEnd
        }
        return result
    }

    private struct Bucket {
        let label: String
        let hours: Double
    }
}

#Preview {
    SimpleRangeChart(sessions: [], interval: DateInterval(start: Date().addingTimeInterval(-7 * 86400), end: Date()))
        .frame(height: 110)
        .padding()
}
