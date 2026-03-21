import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sessionController: SessionController

    @State private var range: SummaryRange = .week
    @State private var showAddSession = false
    @State private var showAddProject = false
    @State private var showSettings = false

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
        animation: .default
    )
    private var projects: FetchedResults<Project>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Freelance Timer")
                .font(.largeTitle)
                .fontWeight(.semibold)

            SummaryView(range: $range, sessions: Array(sessions))

            Divider()

            Text("Sessions")
                .font(.headline)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ProjectsSection(projects: Array(projects)) {
                        showAddProject = true
                    }

                    ForEach(groupedSessions, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ForEach(group.sessions, id: \.objectID) { session in
                                SessionRow(session: session)
                                    .environmentObject(sessionController)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Add Session") {
                    showAddSession = true
                }
                Button("New Project") {
                    showAddProject = true
                }
                Button("Settings") {
                    showSettings = true
                }
            }
        }
        .sheet(isPresented: $showAddSession) {
            AddSessionView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showAddProject) {
            AddProjectView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var groupedSessions: [(date: Date, sessions: [Session])] {
        let sorted = sessions.sorted { lhs, rhs in
            sessionStart(lhs) > sessionStart(rhs)
        }
        let calendar = Calendar.current
        var groups: [Date: [Session]] = [:]
        for session in sorted {
            let day = calendar.startOfDay(for: sessionStart(session))
            groups[day, default: []].append(session)
        }
        return groups.keys.sorted(by: >).map { (date: $0, sessions: groups[$0] ?? []) }
    }

    private func sessionStart(_ session: Session) -> Date {
        let segments = (session.segments as? Set<SessionSegment>) ?? []
        let earliest = segments.compactMap { $0.startAt }.min() ?? Date()
        return earliest
    }
}

struct SessionRow: View {
    @EnvironmentObject private var sessionController: SessionController
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                let companyName = session.project?.company?.name ?? "Company"
                let projectName = session.project?.name ?? "Project"
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: session.project?.colorHex) ?? Color.accentColor)
                        .frame(width: 8, height: 8)
                    Text("\(companyName) · \(projectName)")
                        .font(.subheadline)
                }
                if let note = session.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(TimeFormatter.hoursMinutes(from: sessionController.totalDuration(for: session, now: sessionController.now)))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

struct ProjectsSection: View {
    @Environment(\.managedObjectContext) private var viewContext
    let projects: [Project]
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Projects")
                    .font(.headline)
                Spacer()
                Button("New Project") {
                    onAdd()
                }
            }
            ForEach(projects, id: \.objectID) { project in
                HStack {
                    Circle()
                        .fill(Color(hex: project.colorHex) ?? Color.accentColor)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name ?? "Project")
                            .font(.subheadline)
                        Text(project.company?.name ?? "Company")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("Active", isOn: Binding(
                        get: { project.isActive },
                        set: { newValue in
                            project.isActive = newValue
                            try? viewContext.save()
                        }
                    ))
                    .labelsHidden()
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SessionController(viewContext: PersistenceController.preview.container.viewContext))
}
