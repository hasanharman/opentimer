import SwiftUI
import CoreData

struct EditSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let session: Session

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "company.name", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default
    )
    private var projects: FetchedResults<Project>

    @State private var selectedProjectID: NSManagedObjectID?
    @State private var startAt: Date = Date()
    @State private var endAt: Date = Date()
    @State private var note: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Session")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Adjust time, note, or project.")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Project")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if projects.isEmpty {
                    Text("No active projects")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Project", selection: $selectedProjectID) {
                        Text("Select project").tag(Optional<NSManagedObjectID>(nil))
                        ForEach(projects, id: \.objectID) { project in
                            Text("\(project.company?.name ?? "Company") · \(project.name ?? "Project")")
                                .tag(Optional(project.objectID))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .controlSize(.large)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                DatePicker("Start", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Note")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $note)
                    .frame(minHeight: 70)
                    .padding(6)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(8)
            }

            if isRunning {
                Text("Running sessions can’t be edited. Pause or finish first.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { saveChanges() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isRunning || endAt <= startAt)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            note = session.note ?? ""
            let segments = (session.segments as? Set<SessionSegment>) ?? []
            startAt = segments.compactMap { $0.startAt }.min() ?? Date()
            endAt = segments.compactMap { $0.endAt }.max() ?? Date()
            selectedProjectID = session.project?.objectID ?? projects.first?.objectID
        }
        .onChange(of: projects.count) { _ in
            if selectedProjectID == nil {
                selectedProjectID = projects.first?.objectID
            }
        }
    }

    private var isRunning: Bool {
        let segments = (session.segments as? Set<SessionSegment>) ?? []
        return segments.contains { $0.endAt == nil }
    }

    private func saveChanges() {
        session.note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        if let projectID = selectedProjectID,
           let project = viewContext.object(with: projectID) as? Project {
            session.project = project
        }
        let segments = (session.segments as? Set<SessionSegment>) ?? []
        for segment in segments {
            viewContext.delete(segment)
        }
        let newSegment = SessionSegment(context: viewContext)
        newSegment.id = UUID()
        newSegment.startAt = startAt
        newSegment.endAt = endAt
        newSegment.session = session

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request = NSFetchRequest<Session>(entityName: "Session")
    let session = (try? context.fetch(request).first) ?? Session(context: context)
    return EditSessionView(session: session)
        .environment(\.managedObjectContext, context)
}
