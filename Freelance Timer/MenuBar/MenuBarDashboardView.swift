import SwiftUI
import CoreData
import AppKit

struct MenuBarDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sessionController: SessionController
    @Environment(\.openWindow) private var openWindow

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "id", ascending: false)],
        animation: .default
    )
    private var sessions: FetchedResults<Session>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "company.name", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "isActive == YES AND isArchived == NO"),
        animation: .default
    )
    private var projects: FetchedResults<Project>

    @State private var selectedProjectID: NSManagedObjectID?

    private let cardRadius: CGFloat = 10
    private let cardPadding: CGFloat = 12
    private let cardSpacing: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                projectCard
                timerCard
                chartCard
                recentCard
            }
            .padding(16)
        }
        .frame(width: 320)
        .onAppear {
            if selectedProjectID == nil {
                selectedProjectID = sessionController.selectedProjectID
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Freelance Timer")
                .font(.headline)
            Spacer()
            Button {
                openMainWindow()
            } label: {
                Image(systemName: "arrow.up.forward.square")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private var projectCard: some View {
        ProjectPicker(selectedProjectID: $selectedProjectID)
            .disabled(sessionController.activeSession != nil)
            .opacity(sessionController.activeSession != nil ? 0.5 : 1)
    }

    private var timerCard: some View {
        VStack(spacing: 8) {
            Text(sessionController.activeSession == nil ? "Ready to start" : "Tracking")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 16) {
                Spacer()

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(timerText(now: context.date))
                        .font(.system(size: 36, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                if sessionController.activeSession == nil {
                    Button { startSession() } label: {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.accentColor, in: Circle())
                    }
                    .buttonStyle(.plain)
                } else if sessionController.isRunning {
                    HStack(spacing: 8) {
                        Button { sessionController.pause() } label: {
                            Image(systemName: "pause.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor, in: Circle())
                        }
                        .buttonStyle(.plain)
                        Button { sessionController.finish(); openMainWindow() } label: {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.secondary.opacity(0.5), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    HStack(spacing: 8) {
                        Button { sessionController.resume() } label: {
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor, in: Circle())
                        }
                        .buttonStyle(.plain)
                        Button { sessionController.finish(); openMainWindow() } label: {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.secondary.opacity(0.5), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }

            if let session = sessionController.activeSession, let project = session.project {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: project.colorHex) ?? Color.accentColor)
                        .frame(width: 6, height: 6)
                    Text("\(project.company?.name ?? "Company") · \(project.name ?? "Project")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: sessionController.isRunning)
        .animation(.easeInOut(duration: 0.2), value: sessionController.activeSession != nil)
    }

    @ViewBuilder
    private var chartCard: some View {
        let now = Date()
        let week = summaryDateInterval(range: .week, now: now)
        let weekTotal = TimeMetrics.totalDuration(sessions: Array(sessions), in: week, now: now)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This week")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(TimeFormatter.hoursMinutes(from: weekTotal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            SimpleWeekChart(sessions: Array(sessions), weekStart: week.start)
                .frame(height: 50)
        }
    }

    @ViewBuilder
    private var recentCard: some View {
        let now = Date()
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.subheadline.weight(.medium))
            ForEach(recentSessions(prefix: 3), id: \.objectID) { session in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: session.project?.colorHex) ?? Color.accentColor)
                        .frame(width: 8, height: 8)
                    Text(session.project?.name ?? "Project")
                        .font(.callout)
                    Spacer()
                    Text(TimeFormatter.hoursMinutes(from: sessionController.totalDuration(for: session, now: now)))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func startSession() {
        guard let project = resolveProject() else {
            return
        }
        sessionController.startSession(project: project, note: nil)
    }

    private func resolveProject() -> Project? {
        if let projectID = selectedProjectID,
           let project = viewContext.object(with: projectID) as? Project {
            sessionController.updateSelectedProject(project)
            return project
        }
        if let first = projects.first {
            selectedProjectID = first.objectID
            sessionController.updateSelectedProject(first)
            return first
        }
        return nil
    }

    private func timerText(now: Date) -> String {
        guard let session = sessionController.activeSession else {
            return "00:00:00"
        }
        let duration = sessionController.totalDuration(for: session, now: now)
        return TimeFormatter.hhmmss(from: duration)
    }

    private func recentSessions(prefix count: Int) -> [Session] {
        let sorted = sessions.sorted { lhs, rhs in
            sessionStart(lhs) > sessionStart(rhs)
        }
        return Array(sorted.prefix(count))
    }

    private func sessionStart(_ session: Session) -> Date {
        let segments = (session.segments as? Set<SessionSegment>) ?? []
        return segments.compactMap { $0.startAt }.min() ?? Date()
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(#selector(NSWindow.makeKeyAndOrderFront), to: nil, from: nil)
    }
}

#Preview {
    MenuBarDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SessionController(viewContext: PersistenceController.preview.container.viewContext))
}

private struct SimpleWeekChart: View {
    let sessions: [Session]
    let weekStart: Date

    private let calendar = Calendar.current

    var body: some View {
        let data = weekData()
        let maxValue = max(data.map(\.hours).max() ?? 1, 0.25)
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(data, id: \.day) { item in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(item.hours > 0 ? 0.9 : 0.2))
                    .frame(height: max(4, CGFloat(item.hours / maxValue) * 46))
            }
        }
    }

    private func weekData() -> [(day: Date, hours: Double, label: String)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        var result: [(Date, Double, String)] = []
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let interval = DateInterval(start: dayStart, end: dayEnd)
            let hours = TimeMetrics.totalDuration(sessions: sessions, in: interval, now: Date()) / 3600.0
            result.append((day, hours, formatter.string(from: day)))
        }
        return result
    }
}
