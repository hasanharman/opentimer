import SwiftUI

struct EditProjectView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = CurrencyOption.usd.rawValue

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default
    )
    private var companies: FetchedResults<Company>

    let project: Project

    @State private var projectName: String = ""
    @State private var companyName: String = ""
    @State private var color: ProjectColor = .blue
    @State private var isActive: Bool = true
    @State private var hourlyRate: Double = 0
    @State private var monthlyFee: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color.color)
                        .frame(width: 10, height: 10)
                    Text("Edit Project")
                        .font(.title3.weight(.semibold))
                }
                Spacer()
                Button("Done") { save() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            Form {
                Section("Project") {
                    TextField("Project name", text: $projectName)
                    TextField("Company name", text: $companyName)
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(ProjectColor.allCases) { option in
                            Button {
                                color = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white.opacity(color == option ? 1 : 0), lineWidth: 2.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Status & Rates") {
                    Toggle("Active", isOn: $isActive)

                    LabeledContent("Hourly Rate") {
                        TextField("0.00", value: $hourlyRate, format: .number.precision(.fractionLength(2)))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    LabeledContent("Monthly Fee") {
                        TextField("0.00", value: $monthlyFee, format: .number.precision(.fractionLength(2)))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    LabeledContent("Currency") {
                        Picker("Currency", selection: $currencyCode) {
                            ForEach(CurrencyOption.allCases) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 440, height: 480)
        .onAppear { loadValues() }
    }

    private func loadValues() {
        projectName = project.name ?? ""
        companyName = project.company?.name ?? ""
        color = ProjectColor(rawValue: project.colorHex ?? "") ?? .blue
        isActive = project.isActive
        hourlyRate = project.hourlyRate
        monthlyFee = project.monthlyFee
    }

    private func save() {
        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        project.name = trimmedName
        project.colorHex = color.rawValue
        project.isActive = isActive
        project.hourlyRate = hourlyRate
        project.monthlyFee = monthlyFee

        if !trimmedCompany.isEmpty, let company = project.company {
            company.name = trimmedCompany
        }

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let project = Project(context: context)
    project.name = "Grit Flow"
    project.colorHex = "3B82F6"
    project.isActive = true
    return EditProjectView(project: project)
        .environment(\.managedObjectContext, context)
}
