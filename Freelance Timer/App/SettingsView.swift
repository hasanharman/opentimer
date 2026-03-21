import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Data")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Export CSV…") {
                    DataExporter.exportSessionsCSV(context: viewContext)
                }
                Button("Reset All Data…") {
                    DataExporter.resetAllData(context: viewContext)
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                }
                .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

enum DataExporter {
    static func exportSessionsCSV(context: NSManagedObjectContext) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["csv"]
        panel.nameFieldStringValue = "freelance-timer.csv"
        if panel.runModal() == .OK, let url = panel.url {
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
