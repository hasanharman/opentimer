import SwiftUI

struct AddProjectView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default
    )
    private var companies: FetchedResults<Company>

    @State private var selectedCompanyID: NSManagedObjectID?
    @State private var newCompanyName: String = ""
    @State private var projectName: String = ""
    @State private var color: ProjectColor = .blue
    @State private var isActive = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Project")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Keep it simple and organized.")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Company")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if companies.isEmpty {
                    TextField("Company name", text: $newCompanyName)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Picker("Company", selection: $selectedCompanyID) {
                        Text("New Company").tag(Optional<NSManagedObjectID>(nil))
                        ForEach(companies, id: \.objectID) { company in
                            Text(company.name ?? "Company").tag(Optional(company.objectID))
                        }
                    }
                    .labelsHidden()
                    TextField("New company name", text: $newCompanyName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(selectedCompanyID != nil)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Project")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Project name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    ForEach(ProjectColor.allCases) { option in
                        Button {
                            color = option
                        } label: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(color == option ? 0.9 : 0), lineWidth: 2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle("Active", isOn: $isActive)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Create") {
                    createProject()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            if companies.isEmpty {
                selectedCompanyID = nil
            }
        }
    }

    private func createProject() {
        let trimmedCompany = newCompanyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProject = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProject.isEmpty else { return }

        let company: Company
        if let selectedID = selectedCompanyID,
           let existing = viewContext.object(with: selectedID) as? Company {
            company = existing
        } else {
            company = Company(context: viewContext)
            company.id = UUID()
            company.name = trimmedCompany.isEmpty ? "Company" : trimmedCompany
        }

        let project = Project(context: viewContext)
        project.id = UUID()
        project.name = trimmedProject
        project.isActive = isActive
        project.isArchived = false
        project.colorHex = color.rawValue
        project.company = company

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    AddProjectView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
