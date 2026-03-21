import SwiftUI
import CoreData

struct ProjectDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sessionController: SessionController
    @Environment(\.dismiss) private var dismiss

    let project: Project
    @State private var range: SummaryRange = .month
    @State private var sessionToDelete: Session?
    @State private var sessionToEdit: Session?
    @State private var activeTab: DetailTab = .overview

    enum DetailTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case sessions = "Sessions"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(hex: project.colorHex) ?? Color.accentColor)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name ?? "Project")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(project.company?.name ?? "Company")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            Picker("Tab", selection: $activeTab) {
                ForEach(DetailTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            switch activeTab {
            case .overview:
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
                    Text("\(sessions.count) sessions")
                        .foregroundColor(.secondary)
                }
                .cardStyle()
            case .sessions:
                SessionsListView(
                    sessions: sessions,
                    onEdit: { sessionToEdit = $0 },
                    onDelete: { sessionToDelete = $0 }
                )
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 420)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Export CSV…") {
                    DataExporter.exportProjectCSV(context: viewContext, project: project)
                }
            }
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
        .sheet(item: $sessionToEdit) { session in
            EditSessionView(session: session)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var sessions: [Session] {
        let set = project.sessions as? Set<Session> ?? []
        return set.sorted { lhs, rhs in
            sessionStart(lhs) > sessionStart(rhs)
        }
    }

    private var totalDuration: TimeInterval {
        sessions.reduce(0) { partial, session in
            partial + sessionController.totalDuration(for: session, now: sessionController.now)
        }
    }

    private func sessionStart(_ session: Session) -> Date {
        let segments = (session.segments as? Set<SessionSegment>) ?? []
        return segments.compactMap { $0.startAt }.min() ?? Date()
    }
}

struct SessionsListView: View {
    let sessions: [Session]
    let onEdit: (Session) -> Void
    let onDelete: (Session) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sessions")
                .font(.headline)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(sessions, id: \.objectID) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.note ?? "Session")
                                    .font(.subheadline)
                                Text(session.project?.name ?? "Project")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                onEdit(session)
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)
                            Button {
                                onDelete(session)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .cardStyle()
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request = NSFetchRequest<Project>(entityName: "Project")
    let project = (try? context.fetch(request).first) ?? Project(context: context)
    return ProjectDetailView(project: project)
        .environment(\.managedObjectContext, context)
        .environmentObject(SessionController(viewContext: context))
}
