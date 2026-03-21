import SwiftUI

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var companyName: String = ""
    @State private var projectName: String = ""
    @State private var projectColor: ProjectColor = .blue
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Let’s set up your first company and project.")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Company")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Company name", text: $companyName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Project")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Project name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                HStack(spacing: 10) {
                    ForEach(ProjectColor.allCases) { option in
                        Button {
                            projectColor = option
                        } label: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(projectColor == option ? 0.9 : 0), lineWidth: 2)
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

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button("Get Started") {
                    createInitialData()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .frame(maxWidth: 420)
    }

    private func createInitialData() {
        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProject = projectName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCompany.isEmpty, !trimmedProject.isEmpty else {
            errorMessage = "Please enter both a company and a project."
            return
        }

        let company = Company(context: viewContext)
        company.id = UUID()
        company.name = trimmedCompany

        let project = Project(context: viewContext)
        project.id = UUID()
        project.name = trimmedProject
        project.isActive = true
        project.colorHex = projectColor.rawValue
        project.company = company

        do {
            try viewContext.save()
            hasCompletedOnboarding = true
        } catch {
            viewContext.rollback()
            errorMessage = "Could not save your setup. Please try again."
        }
    }
}

#Preview {
    OnboardingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
