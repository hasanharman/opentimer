import SwiftUI
import Charts

struct RangeChartView: View {
    let range: SummaryRange
    let interval: DateInterval
    let sessions: [Session]
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Range")
                .font(.caption)
                .foregroundColor(.secondary)
            Chart(dataPoints) { point in
                BarMark(
                    x: .value("Bucket", point.label),
                    y: .value("Hours", point.hours)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color(NSColor.separatorColor))
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6))
            }
            .frame(height: 140)
            .cardStyle()
        }
    }

    private var dataPoints: [ChartPoint] {
        let interval = dateInterval
        let calendar = Calendar.current
        var buckets: [DateInterval] = []

        switch range {
        case .day:
            for hour in 0..<24 {
                if let start = calendar.date(byAdding: .hour, value: hour, to: interval.start),
                   let end = calendar.date(byAdding: .hour, value: hour + 1, to: interval.start) {
                    buckets.append(DateInterval(start: start, end: end))
                }
            }
        case .week:
            for day in 0..<7 {
                if let start = calendar.date(byAdding: .day, value: day, to: interval.start),
                   let end = calendar.date(byAdding: .day, value: day + 1, to: interval.start) {
                    buckets.append(DateInterval(start: start, end: end))
                }
            }
        case .month:
            let range = calendar.range(of: .day, in: .month, for: interval.start) ?? 1..<28
            for day in range {
                if let start = calendar.date(byAdding: .day, value: day - 1, to: interval.start),
                   let end = calendar.date(byAdding: .day, value: day, to: interval.start) {
                    buckets.append(DateInterval(start: start, end: end))
                }
            }
        case .year:
            for month in 0..<12 {
                if let start = calendar.date(byAdding: .month, value: month, to: interval.start),
                   let end = calendar.date(byAdding: .month, value: month + 1, to: interval.start) {
                    buckets.append(DateInterval(start: start, end: end))
                }
            }
        }

        return buckets.map { bucket in
            let hours = totalHours(in: bucket)
            return ChartPoint(label: label(for: bucket), hours: hours)
        }
    }

    private func totalHours(in bucket: DateInterval) -> Double {
        let total = sessions.reduce(0.0) { partial, session in
            let segments = (session.segments as? Set<SessionSegment>) ?? []
            let segmentTotal = segments.reduce(0.0) { subtotal, segment in
                let start = segment.startAt ?? now
                let end = segment.endAt ?? now
                if end <= bucket.start || start >= bucket.end {
                    return subtotal
                }
                let clampedStart = max(start, bucket.start)
                let clampedEnd = min(end, bucket.end)
                return subtotal + max(0, clampedEnd.timeIntervalSince(clampedStart))
            }
            return partial + segmentTotal
        }
        return total / 3600.0
    }

    private func label(for bucket: DateInterval) -> String {
        let calendar = Calendar.current
        switch range {
        case .day:
            let hour = calendar.component(.hour, from: bucket.start)
            return "\(hour)"
        case .week:
            return bucket.start.formatted(.dateTime.weekday(.abbreviated))
        case .month:
            let day = calendar.component(.day, from: bucket.start)
            return "\(day)"
        case .year:
            return bucket.start.formatted(.dateTime.month(.abbreviated))
        }
    }

    private var dateInterval: DateInterval {
        interval
    }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let hours: Double
}

#Preview {
    RangeChartView(range: .week, interval: summaryDateInterval(range: .week, now: Date()), sessions: [], now: Date())
        .padding()
}
