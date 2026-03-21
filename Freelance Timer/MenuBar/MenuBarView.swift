import SwiftUI
import CoreData

struct MenuBarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sessionController: SessionController
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.openWindow) private var openWindow

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "company.name", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "isActive == YES"),
        animation: .default
    )
    private var projects: FetchedResults<Project>

    var body: some View {
        if !hasCompletedOnboarding {
            Button("Open Onboarding") {
                openMainWindow()
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        } else {
            Menu("Project") {
                ForEach(projects, id: \.objectID) { project in
                    Button {
                        sessionController.updateSelectedProject(project)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: project.colorHex) ?? Color.accentColor)
                                .frame(width: 8, height: 8)
                            Text("\(project.company?.name ?? "Company") · \(project.name ?? "Project")")
                            if sessionController.selectedProjectID == project.objectID {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            if sessionController.activeSession == nil {
                Button("Start") {
                    startSession()
                }
                Button("Start with Note…") {
                    startSessionWithPrompt()
                }
            } else if sessionController.isRunning {
                Button("Pause") {
                    sessionController.pause()
                }
                Button("Finish") {
                    sessionController.finish()
                }
            } else {
                Button("Resume") {
                    sessionController.resume()
                }
                Button("Finish") {
                    sessionController.finish()
                }
            }

            Divider()

            Button("Open") {
                openMainWindow()
            }

            Text(sessionController.isRunning ? "Running" : "Idle")
            if let session = sessionController.activeSession {
                let total = sessionController.totalDuration(for: session, now: sessionController.now)
                Text(TimeFormatter.hhmmss(from: total))
            } else {
                Text("00:00:00")
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }

    private func startSession() {
        guard let project = resolveProject() else {
            return
        }
        sessionController.startSession(project: project, note: nil)
    }

    private func startSessionWithPrompt() {
        guard let project = resolveProject() else {
            return
        }
        let note = promptForNote()
        sessionController.startSession(project: project, note: note)
    }

    private func promptForNote() -> String? {
        let alert = NSAlert()
        alert.messageText = "Session Note"
        alert.informativeText = "Add an optional description."
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 22))
        alert.accessoryView = input
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        let value = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return response == .alertFirstButtonReturn ? (value.isEmpty ? nil : value) : nil
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(#selector(NSWindow.makeKeyAndOrderFront), to: nil, from: nil)
    }

    private func resolveProject() -> Project? {
        if let projectID = sessionController.selectedProjectID,
           let project = viewContext.object(with: projectID) as? Project {
            return project
        }
        if let first = projects.first {
            sessionController.updateSelectedProject(first)
            return first
        }
        return nil
    }
}

#Preview {
    MenuBarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SessionController(viewContext: PersistenceController.preview.container.viewContext))
        .frame(width: 320)
}
