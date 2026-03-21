import Foundation
import CoreData
import Combine

final class SessionController: ObservableObject {
    @Published private(set) var activeSession: Session?
    @Published private(set) var activeSegment: SessionSegment?
    @Published var now: Date = Date()
    @Published var selectedProjectID: NSManagedObjectID?

    private let viewContext: NSManagedObjectContext
    private var timer: Timer?

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.activeSegment = Self.fetchActiveSegment(in: viewContext)
        self.activeSession = activeSegment?.session
        self.selectedProjectID = activeSession?.project?.objectID
        startClock()
    }

    deinit {
        timer?.invalidate()
    }

    var isRunning: Bool {
        activeSegment != nil
    }

    func startSession(project: Project, note: String?) {
        guard activeSession == nil else { return }

        let session = Session(context: viewContext)
        session.id = UUID()
        session.note = note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : note
        session.project = project

        let segment = SessionSegment(context: viewContext)
        segment.id = UUID()
        segment.startAt = now
        segment.session = session

        activeSession = session
        activeSegment = segment
        selectedProjectID = project.objectID
        saveContext()
    }

    func pause() {
        guard let segment = activeSegment else { return }
        segment.endAt = now
        activeSegment = nil
        saveContext()
    }

    func resume() {
        guard let session = activeSession, activeSegment == nil else { return }
        let segment = SessionSegment(context: viewContext)
        segment.id = UUID()
        segment.startAt = now
        segment.session = session
        activeSegment = segment
        saveContext()
    }

    func finish() {
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

    func menuBarTitle() -> String {
        guard let session = activeSession else { return "" }
        let total = totalDuration(for: session, now: now)
        let formatted = TimeFormatter.hhmmss(from: total)
        return formatted
    }

    func totalDuration(for session: Session, now: Date) -> TimeInterval {
        let segments = (session.segments as? Set<SessionSegment>) ?? []
        return segments.reduce(0) { partial, segment in
            let start = segment.startAt ?? now
            let end = segment.endAt ?? now
            return partial + max(0, end.timeIntervalSince(start))
        }
    }

    private func startClock() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.now = Date()
        }
        RunLoop.main.add(timer!, forMode: .common)
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
