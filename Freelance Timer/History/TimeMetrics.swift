import Foundation
import CoreData

enum TimeMetrics {
    static func totalDuration(sessions: [Session], in interval: DateInterval, now: Date) -> TimeInterval {
        sessions.reduce(0) { partial, session in
            partial + sessionDuration(session, in: interval, now: now)
        }
    }

    static func sessionDuration(_ session: Session, in interval: DateInterval, now: Date) -> TimeInterval {
        let segments = (session.segments as? Set<SessionSegment>) ?? []
        return segments.reduce(0) { subtotal, segment in
            let start = segment.startAt ?? now
            let end = segment.endAt ?? now
            if end <= interval.start || start >= interval.end {
                return subtotal
            }
            let clampedStart = max(start, interval.start)
            let clampedEnd = min(end, interval.end)
            return subtotal + max(0, clampedEnd.timeIntervalSince(clampedStart))
        }
    }

    static func earnings(sessions: [Session], projects: [Project], in interval: DateInterval, now: Date) -> Double {
        let hourlyTotal = sessions.reduce(0.0) { partial, session in
            let rate = session.project?.hourlyRate ?? 0
            let duration = sessionDuration(session, in: interval, now: now)
            return partial + (duration / 3600.0) * rate
        }

        let feeTotal = projects.reduce(0.0) { partial, project in
            partial + monthlyFeeContribution(for: project, in: interval)
        }

        return hourlyTotal + feeTotal
    }

    static func projectEarnings(project: Project, sessions: [Session], in interval: DateInterval, now: Date) -> Double {
        let hourlyTotal = sessions.reduce(0.0) { partial, session in
            let duration = sessionDuration(session, in: interval, now: now)
            return partial + (duration / 3600.0) * project.hourlyRate
        }
        return hourlyTotal + monthlyFeeContribution(for: project, in: interval)
    }

    static func monthlyFeeContribution(for project: Project, in interval: DateInterval) -> Double {
        let fee = project.monthlyFee
        if fee <= 0 { return 0 }

        let calendar = Calendar.current
        guard interval.end > interval.start else { return 0 }

        var total = 0.0
        var cursor = calendar.dateInterval(of: .month, for: interval.start)?.start ?? interval.start

        while cursor < interval.end {
            guard let monthInterval = calendar.dateInterval(of: .month, for: cursor) else { break }
            let overlapStart = max(interval.start, monthInterval.start)
            let overlapEnd = min(interval.end, monthInterval.end)
            if overlapEnd > overlapStart {
                let monthDays = monthInterval.duration / 86400.0
                let overlapDays = overlapEnd.timeIntervalSince(overlapStart) / 86400.0
                total += fee * (overlapDays / monthDays)
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: monthInterval.start) else { break }
            cursor = next
        }

        return total
    }
}
