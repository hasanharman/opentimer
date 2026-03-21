import SwiftUI

struct ManageProjectsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let onSelect: (Project) -> Void
    let onDelete: (Project) -> Void

    @State private var query: String = ""
    @State private var showInactive = true
    @State private var showArchived = false

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
            HStack {
                Text("Projects")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            HStack {
                TextField("Search", text: $query)
                    .textFieldStyle(.roundedBorder)
                Toggle("Show Inactive", isOn: $showInactive)
                Toggle("Show Archived", isOn: $showArchived)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(filteredProjects, id: \.objectID) { project in
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
                            Button(project.isArchived ? "Unarchive" : "Archive") {
                                project.isArchived.toggle()
                                if project.isArchived {
                                    project.isActive = false
                                }
                                try? viewContext.save()
                            }
                            Button("Open") {
                                onSelect(project)
                            }
                            Button {
                                onDelete(project)
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
        .padding(24)
        .frame(minWidth: 560, minHeight: 420)
    }

    private var filteredProjects: [Project] {
        let base = projects.filter { project in
            if !showArchived && project.isArchived { return false }
            if showInactive { return true }
            return project.isActive
        }
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(base)
        }
        let needle = query.lowercased()
        return base.filter { project in
            (project.name ?? "").lowercased().contains(needle) ||
            (project.company?.name ?? "").lowercased().contains(needle)
        }
    }
}

#Preview {
    ManageProjectsView(onSelect: { _ in }, onDelete: { _ in })
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
