import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sessionController: SessionController

    @State private var range: SummaryRange = .week
    @State private var showAddSession = false
    @State private var showAddProject = false
    @State private var showSettings = false
    @State private var selectedProjectForDetail: Project?
    @State private var showManageProjects = false
    @State private var projectToDelete: Project?
    @State private var sessionToDelete: Session?
    @State private var sessionToEdit: Session?

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
        predicate: NSPredicate(format: "isArchived == NO"),
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
                    ProjectsSection(
                        projects: Array(projects),
                        onSelect: { project in
                            selectedProjectForDetail = project
                        },
                        onDelete: { project in
                            projectToDelete = project
                        },
                        onAdd: {
                            showAddProject = true
                        }
                    )

                    ForEach(groupedSessions, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ForEach(group.sessions, id: \.objectID) { session in
                                SessionRow(session: session)
                                    .environmentObject(sessionController)
                                    .contextMenu {
                                        Button("Edit Session") {
                                            sessionToEdit = session
                                        }
                                        Button("Delete Session") {
                                            sessionToDelete = session
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(AppTheme.windowBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Add Session") {
                    showAddSession = true
                }
                Button("New Project") {
                    showAddProject = true
                }
                Button("Manage Projects") {
                    showManageProjects = true
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
        .sheet(isPresented: $showManageProjects) {
            ManageProjectsView(onSelect: { project in
                selectedProjectForDetail = project
            }, onDelete: { project in
                projectToDelete = project
            })
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedProjectForDetail) { project in
            ProjectDetailView(project: project)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(sessionController)
        }
        .sheet(item: $sessionToEdit) { session in
            EditSessionView(session: session)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Delete Project?", isPresented: Binding(
            get: { projectToDelete != nil },
            set: { newValue in
                if !newValue { projectToDelete = nil }
            }
        )) {
            Button("Delete (remove sessions)", role: .destructive) {
                if let projectToDelete {
                    viewContext.delete(projectToDelete)
                    try? viewContext.save()
                }
                projectToDelete = nil
            }
            Button("Delete (keep sessions)") {
                if let projectToDelete {
                    moveSessionsToUnassigned(projectToDelete)
                    viewContext.delete(projectToDelete)
                    try? viewContext.save()
                }
                projectToDelete = nil
            }
            Button("Archive") {
                if let projectToDelete {
                    projectToDelete.isArchived = true
                    projectToDelete.isActive = false
                    try? viewContext.save()
                }
                projectToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
        } message: {
            Text("Choose whether to keep or remove sessions.")
        }
        .alert("Delete Session?", isPresented: Binding(
            get: { sessionToDelete != nil },
            set: { newValue in
                if !newValue { sessionToDelete = nil }
            }
        )) {
            Button("Delete", role: .destructive) {
                if let sessionToDelete {
                    viewContext.delete(sessionToDelete)
                    try? viewContext.save()
                }
                sessionToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        } message: {
            Text("This will remove the session permanently.")
        }
    }

    private func moveSessionsToUnassigned(_ project: Project) {
        let company: Company
        if let existingCompany = project.company {
            company = existingCompany
        } else {
            let newCompany = Company(context: viewContext)
            newCompany.id = UUID()
            newCompany.name = "Unassigned"
            company = newCompany
        }
        let unassignedName = "Unassigned"

        let fetch = NSFetchRequest<Project>(entityName: "Project")
        fetch.predicate = NSPredicate(format: "company == %@ AND name == %@", company, unassignedName)
        let existing = (try? viewContext.fetch(fetch))?.first

        let target: Project
        if let existing {
            target = existing
        } else {
            let newProject = Project(context: viewContext)
            newProject.id = UUID()
            newProject.name = unassignedName
            newProject.isActive = false
            newProject.isArchived = true
            newProject.colorHex = "9CA3AF"
            newProject.company = company
            target = newProject
        }

        let sessions = project.sessions as? Set<Session> ?? []
        sessions.forEach { $0.project = target }
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
    let onSelect: (Project) -> Void
    let onDelete: (Project) -> Void
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
                    Button {
                        project.isArchived.toggle()
                        if project.isArchived {
                            project.isActive = false
                        }
                        try? viewContext.save()
                    } label: {
                        Image(systemName: project.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    .buttonStyle(.borderless)
                    Button {
                        onDelete(project)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
                .cardStyle()
                .onTapGesture {
                    onSelect(project)
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SessionController(viewContext: PersistenceController.preview.container.viewContext))
}
