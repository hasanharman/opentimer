import Foundation
import CoreData
import Combine

final class SessionController: ObservableObject {
    @Published private(set) var activeSession: Session?
    @Published private(set) var activeSegment: SessionSegment?
    @Published var selectedProjectID: NSManagedObjectID?

    private let viewContext: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.activeSegment = Self.fetchActiveSegment(in: viewContext)
        self.activeSession = activeSegment?.session
        self.selectedProjectID = activeSession?.project?.objectID
    }

    var isRunning: Bool {
        activeSegment != nil
    }

    func startSession(project: Project, note: String?) {
        guard activeSession == nil else { return }
        let now = Date()

        let session = Session(context: viewContext)
        session.id = UUID()
        session.note = note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : note
        session.project = project

        let segment = SessionSegment(context: viewContext)
        segment.id = UUID()
        segment.startAt = now
        segment.session = session
        session.startedAt = now

        activeSession = session
        activeSegment = segment
        selectedProjectID = project.objectID
        saveContext()
    }

    func pause() {
        guard let segment = activeSegment else { return }
        let now = Date()
        segment.endAt = now
        activeSegment = nil
        saveContext()
    }

    func resume() {
        guard let session = activeSession, activeSegment == nil else { return }
        let now = Date()
        let segment = SessionSegment(context: viewContext)
        segment.id = UUID()
        segment.startAt = now
        segment.session = session
        activeSegment = segment
        saveContext()
    }

    func finish() {
        let now = Date()
        if let segment = activeSegment {
            segment.endAt = now
        }
        activeSegment = nil
        activeSession = nil
        saveContext()
    }

    func updateSelectedProject(_ project: Project?) {
        selectedProjectID = project?.objectID
    }

    func menuBarTitle(now: Date) -> String {
        guard let session = activeSession else { return "" }
        let projectName = session.project?.name ?? "Project"
        let total = totalDuration(for: session, now: now)
        let formatted = TimeFormatter.hhmmss(from: total)
        if isRunning {
            return "\(projectName) · \(formatted)"
        }
        return "Paused · \(projectName) · \(formatted)"
    }

    func totalDuration(for session: Session, now: Date) -> TimeInterval {
        let segments = (session.segments as? Set<SessionSegment>) ?? []
        return segments.reduce(0) { partial, segment in
            let start = segment.startAt ?? now
            let end = segment.endAt ?? now
            return partial + max(0, end.timeIntervalSince(start))
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
        }
    }

    private static func fetchActiveSegment(in context: NSManagedObjectContext) -> SessionSegment? {
        let request = NSFetchRequest<SessionSegment>(entityName: "SessionSegment")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "endAt == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "startAt", ascending: false)]
        return try? context.fetch(request).first
    }
}

extension Session {
    /// The denormalized session start (earliest segment `startAt`), kept in sync
    /// so fetches can sort on a scalar attribute instead of faulting `segments`.
    func refreshStartedAt() {
        let segments = (self.segments as? Set<SessionSegment>) ?? []
        startedAt = segments.compactMap { $0.startAt }.min()
    }

    /// Best-effort start date: the maintained `startedAt`, falling back to the
    /// earliest segment for records that predate the attribute.
    var effectiveStart: Date {
        if let startedAt { return startedAt }
        let segments = (self.segments as? Set<SessionSegment>) ?? []
        return segments.compactMap { $0.startAt }.min() ?? .distantPast
    }

    /// One-time backfill for sessions created before `startedAt` existed.
    static func backfillStartedAt(in context: NSManagedObjectContext) {
        let request = NSFetchRequest<Session>(entityName: "Session")
        request.predicate = NSPredicate(format: "startedAt == nil")
        guard let sessions = try? context.fetch(request), !sessions.isEmpty else { return }
        for session in sessions {
            session.refreshStartedAt()
        }
        if context.hasChanges {
            try? context.save()
        }
    }
}

enum TimeFormatter {
    static func hhmmss(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func hoursMinutes(from interval: TimeInterval) -> String {
        let totalMinutes = Int(interval.rounded() / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}
