import SwiftUI

struct AddSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "company.name", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "isActive == YES"),
        animation: .default
    )
    private var projects: FetchedResults<Project>

    @State private var selectedProjectID: NSManagedObjectID?
    @State private var note: String = ""
    @State private var startAt: Date = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
    @State private var endAt: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Session")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Manually log time in one place.")
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

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    saveSession()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedProjectID == nil || endAt <= startAt)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            if selectedProjectID == nil {
                selectedProjectID = projects.first?.objectID
            }
        }
        .onChange(of: projects.count) { _, _ in
            if selectedProjectID == nil {
                selectedProjectID = projects.first?.objectID
            }
        }
    }

    private func saveSession() {
        guard let projectID = selectedProjectID,
              let project = viewContext.object(with: projectID) as? Project else {
            return
        }
        let session = Session(context: viewContext)
        session.id = UUID()
        session.note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        session.project = project

        let segment = SessionSegment(context: viewContext)
        segment.id = UUID()
        segment.startAt = startAt
        segment.endAt = endAt
        segment.session = session

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    AddSessionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
