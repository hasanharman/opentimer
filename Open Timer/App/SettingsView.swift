import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = CurrencyOption.usd.rawValue

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showImportOptions = false
    @State private var importMode: DataBackup.ImportMode = .replaceAll

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            Form {
                Section("Data") {
                    HStack(spacing: 8) {
                        Button("Export CSV\u{2026}") {
                            do {
                                let didExport = try DataExporter.exportSessionsCSV(context: viewContext)
                                if didExport {
                                    presentInfo(title: "Export Complete", message: "Your CSV was saved successfully.")
                                }
                            } catch {
                                presentError(title: "Export Failed", message: error.localizedDescription)
                            }
                        }
                        Button("Export Backup\u{2026}") {
                            do {
                                let didExport = try DataBackup.exportBackup(context: viewContext)
                                if didExport {
                                    presentInfo(title: "Backup Saved", message: "Your data was exported successfully.")
                                }
                            } catch {
                                presentError(title: "Backup Failed", message: error.localizedDescription)
                            }
                        }
                        Button("Import Backup\u{2026}") {
                            showImportOptions = true
                        }
                    }
                    Button("Reset All Data\u{2026}", role: .destructive) {
                        DataExporter.resetAllData(context: viewContext)
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    }
                }

                Section("Currency") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(CurrencyOption.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 440, height: 320)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog("Import Backup", isPresented: $showImportOptions, titleVisibility: .visible) {
            Button("Replace All Data", role: .destructive) {
                importMode = .replaceAll
                runImport()
            }
            Button("Merge (Skip Duplicates)") {
                importMode = .merge
                runImport()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how to apply the backup file.")
        }
    }

    private func runImport() {
        do {
            let didImport = try DataBackup.importBackup(context: viewContext, mode: importMode)
            if didImport {
                presentInfo(title: "Import Complete", message: "Your backup was restored successfully.")
            }
        } catch {
            presentError(title: "Import Failed", message: error.localizedDescription)
        }
    }

    private func presentError(title: String, message: String) {
        alertTitle = title
        alertMessage = message.isEmpty ? "Something went wrong. Please try again." : message
        showAlert = true
    }

    private func presentInfo(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

enum DataExporter {
    static func exportSessionsCSV(context: NSManagedObjectContext) throws -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = "open-timer.csv"
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        let request = NSFetchRequest<Session>(entityName: "Session")
        let sessions = (try? context.fetch(request)) ?? []
        var rows: [String] = ["company,project,start,end,duration_hours,note"]
        for session in sessions {
            let company = session.project?.company?.name ?? ""
            let project = session.project?.name ?? ""
            let segments = (session.segments as? Set<SessionSegment>) ?? []
            let start = segments.compactMap { $0.startAt }.min()
            let end = segments.compactMap { $0.endAt }.max()
            let duration = segments.reduce(0.0) { partial, segment in
                let s = segment.startAt ?? Date()
                let e = segment.endAt ?? Date()
                return partial + max(0, e.timeIntervalSince(s))
            } / 3600.0
            let note = (session.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let row = "\"\(company)\",\"\(project)\",\"\(start?.ISO8601Format() ?? "")\",\"\(end?.ISO8601Format() ?? "")\",\"\(String(format: "%.2f", duration))\",\"\(note)\""
            rows.append(row)
        }
        let csv = rows.joined(separator: "\n")
        guard let data = csv.data(using: .utf8) else {
            throw NSError(domain: "ExportCSV", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode CSV data."])
        }
        try data.write(to: url)
        return true
    }

    static func exportProjectCSV(context: NSManagedObjectContext, project: Project) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = "\(project.name ?? "project").csv"
        if panel.runModal() == .OK, let url = panel.url {
            let sessions = (project.sessions as? Set<Session>) ?? []
            var rows: [String] = ["company,project,start,end,duration_hours,note"]
            for session in sessions {
                let company = session.project?.company?.name ?? ""
                let projectName = session.project?.name ?? ""
                let segments = (session.segments as? Set<SessionSegment>) ?? []
                let start = segments.compactMap { $0.startAt }.min()
                let end = segments.compactMap { $0.endAt }.max()
                let duration = segments.reduce(0.0) { partial, segment in
                    let s = segment.startAt ?? Date()
                    let e = segment.endAt ?? Date()
                    return partial + max(0, e.timeIntervalSince(s))
                } / 3600.0
                let note = (session.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                let row = "\"\(company)\",\"\(projectName)\",\"\(start?.ISO8601Format() ?? "")\",\"\(end?.ISO8601Format() ?? "")\",\"\(String(format: "%.2f", duration))\",\"\(note)\""
                rows.append(row)
            }
            let csv = rows.joined(separator: "\n")
            try? csv.data(using: .utf8)?.write(to: url)
        }
    }

    static func resetAllData(context: NSManagedObjectContext) {
        let entities = ["SessionSegment", "Session", "Project", "Company"]
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? context.execute(deleteRequest)
        }
        try? context.save()
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
