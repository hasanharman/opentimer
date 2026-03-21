//
//  Freelance_TimerApp.swift
//  Freelance Timer
//
//  Created by Hasan Harman on 21.03.2026.
//

import SwiftUI
import CoreData

@main
struct Freelance_TimerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
