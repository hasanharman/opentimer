//
//  Freelance_TimerApp.swift
//  Freelance Timer
//
//  Created by Hasan Harman on 21.03.2026.
//

import SwiftUI
import CoreData
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            let completed = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            if !completed {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title == "Freelance Timer" }) {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
}

@main
struct Freelance_TimerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var sessionController: SessionController
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        let context = persistenceController.container.viewContext
        _sessionController = StateObject(wrappedValue: SessionController(viewContext: context))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarDashboardView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(sessionController)
        } label: {
            MenuBarLabelView()
                .environmentObject(sessionController)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("Freelance Timer", id: "main") {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(sessionController)
        }
        .defaultSize(width: 1000, height: 680)
    }
}
