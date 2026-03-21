import SwiftUI
import CoreData

struct ProjectPicker: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "company.name", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "isActive == YES AND isArchived == NO"),
        animation: .default
    )
    private var projects: FetchedResults<Project>

    @Binding var selectedProjectID: NSManagedObjectID?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Project")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Project", selection: selectedProjectIDBinding) {
                ForEach(projects, id: \.objectID) { project in
                    let companyName = project.company?.name ?? "Company"
                    let projectName = project.name ?? "Project"
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: project.colorHex) ?? Color.accentColor)
                            .frame(width: 8, height: 8)
                        Text("\(companyName) · \(projectName)")
                    }
                        .tag(Optional(project.objectID))
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            if selectedProjectID == nil {
                selectedProjectID = projects.first?.objectID
            }
        }
    }

    private var selectedProjectIDBinding: Binding<NSManagedObjectID?> {
        Binding(
            get: { selectedProjectID },
            set: { newValue in
                selectedProjectID = newValue
            }
        )
    }
}

#Preview {
    ProjectPicker(selectedProjectID: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 280)
}
