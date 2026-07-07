import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sessionController: SessionController

    @AppStorage("showEarnings") private var showEarnings = false
    @AppStorage("currencyCode") private var currencyCode = CurrencyOption.usd.rawValue

    @State private var range: SummaryRange = .week
    @State private var showAddSession = false
    @State private var showAddProject = false
    @State private var showSettings = false
    @State private var selectedProjectForDetail: Project?
    @State private var showManageProjects = false
    @State private var projectToDelete: Project?
    @State private var sessionToDelete: Session?
    @State private var sessionToEdit: Session?
    @State private var projectToEdit: Project?
    @State private var sidebarSelection: DashboardSection = .dashboard
    @State private var showRangePicker = false
    @State private var useCustomRange = false
    @State private var customStart = Calendar.current.startOfDay(for: Date())
    @State private var customEnd = Calendar.current.startOfDay(for: Date())

    @FetchRequest(fetchRequest: HistoryView.sessionsFetchRequest(), animation: .default)
    private var sessions: FetchedResults<Session>

    private static func sessionsFetchRequest() -> NSFetchRequest<Session> {
        let request = NSFetchRequest<Session>(entityName: "Session")
        // Sort on the denormalized start (a scalar attribute) instead of the random
        // UUID, so results are actually chronological without an in-memory re-sort.
        request.sortDescriptors = [
            NSSortDescriptor(key: "startedAt", ascending: false),
            NSSortDescriptor(key: "id", ascending: false)
        ]
        // Batch faulting and prefetch the relationships the views immediately read,
        // so aggregation doesn't fault each session/segment individually.
        request.fetchBatchSize = 50
        request.relationshipKeyPathsForPrefetching = ["segments", "project"]
        return request
    }

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "company.name", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default
    )
    private var projects: FetchedResults<Project>

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.prominentDetail)
        .background(AppTheme.dashboardBackground.ignoresSafeArea())
        .toolbar(removing: .sidebarToggle)
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
        }
        .sheet(item: $projectToEdit) { project in
            EditProjectView(project: project)
                .environment(\.managedObjectContext, viewContext)
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

    private var sidebar: some View {
        List(selection: $sidebarSelection) {
            ForEach(DashboardSection.allCases) { section in
                Label(section.rawValue, systemImage: section.systemImage)
                    .tag(section)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
                dashboardContent
            }
            .padding(24)
        }
        .background(AppTheme.dashboardBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var dashboardContent: some View {
        switch sidebarSelection {
        case .dashboard:
            dashboardSummary
            dashboardSessions
        case .activities:
            dashboardSessions
        case .projects:
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Projects")
                        .font(.headline)
                    Spacer()
                    Button("New Project") { showAddProject = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                }
                projectsList
            }
        }
    }

    private var dashboardSummary: some View {
        let now = Date()
        let interval = resolvedInterval(now: now)
        let total = TimeMetrics.totalDuration(sessions: Array(sessions), in: interval, now: now)
        let earnings = TimeMetrics.earnings(sessions: Array(sessions), projects: Array(projects), in: interval, now: now)

        return VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            // Row 1: Title ---- Buttons
            HStack {
                Text("Activity Monitor")
                    .font(.title3.weight(.semibold))
                Spacer()
                HStack(spacing: 8) {
                    Button { showAddSession = true } label: {
                        Label("Add Session", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Button("New Project") { showAddProject = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                }
            }

            // Row 2: Tabs - Date picker - Earnings toggle
            HStack(spacing: 12) {
                SegmentedTabs(items: SummaryRange.allCases, selection: $range) { $0.rawValue }
                    .fixedSize()

                Button {
                    showRangePicker.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text(rangeLabel(interval: interval))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .font(.callout)
                    .foregroundColor(.primary)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.dashboardStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showRangePicker) {
                    CalendarRangePicker(start: $customStart, end: $customEnd, useCustomRange: $useCustomRange)
                        .frame(width: 320)
                        .padding(16)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("Earnings")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Toggle("Earnings", isOn: $showEarnings)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .controlSize(.small)
                }
            }

            // Chart + stat cards row
            HStack(alignment: .top, spacing: AppTheme.cardSpacing) {
                // Chart card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Focus Activity")
                        .font(.footnote.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text("Usage Statistics")
                        .font(.title2.bold())
                    Spacer()
                    SimpleRangeChart(sessions: Array(sessions), interval: interval)
                        .frame(height: 160)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dashboardCardStyle()

                // Stat cards
                VStack(spacing: AppTheme.cardSpacing) {
                    statCard(
                        title: "Total Worktime",
                        value: TimeFormatter.hoursMinutes(from: total),
                        subtitle: "Calculated from sessions"
                    )
                    .frame(maxHeight: .infinity)
                    if showEarnings {
                        statCard(
                            title: "Estimated Earnings",
                            value: CurrencyFormatter.string(from: earnings, currencyCode: currencyCode),
                            subtitle: "Calculated from projects"
                        )
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
                .frame(width: 220)
            }
            .frame(height: 320)
        }
    }

    private var dashboardSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ongoing Activities")
                    .font(.headline)
                Spacer()
                Button("Manage Projects") { showManageProjects = true }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
            }

            projectsList

            ForEach(groupedSessions, id: \.date) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.dashboardMuted)
                    ForEach(group.sessions, id: \.objectID) { session in
                        DashboardSessionRow(session: session, duration: sessionController.totalDuration(for: session, now: Date()))
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

    private var projectsList: some View {
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
                        .foregroundStyle(.secondary)
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
                    if project.isArchived { project.isActive = false }
                    try? viewContext.save()
                } label: {
                    Image(systemName: project.isArchived ? "tray.and.arrow.up" : "archivebox")
                }
                .buttonStyle(.borderless)
                Button { projectToDelete = project } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            .dashboardCardStyle()
            .onTapGesture { projectToEdit = project }
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
        session.effectiveStart
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

    private func displayRange(interval: DateInterval) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = interval.start
        let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        return (start, end)
    }

    private func statCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
            Spacer()
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .dashboardCardStyle(elevated: true)
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
                        .foregroundColor(AppTheme.dashboardMuted)
                }
            }
            Spacer()
            Text(TimeFormatter.hoursMinutes(from: sessionController.totalDuration(for: session, now: Date())))
                .font(.subheadline)
                .foregroundColor(AppTheme.dashboardMuted)
        }
        .padding(10)
        .background(AppTheme.dashboardCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.dashboardStroke, lineWidth: 1)
        )
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SessionController(viewContext: PersistenceController.preview.container.viewContext))
}
