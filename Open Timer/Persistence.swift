//
//  Persistence.swift
//  Open Timer
//
//  Created by Hasan Harman on 21.03.2026.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let company = Company(context: viewContext)
        company.id = UUID()
        company.name = "Acme Studio"

        let project = Project(context: viewContext)
        project.id = UUID()
        project.name = "Website Redesign"
        project.isActive = true
        project.isArchived = false
        project.colorHex = "3B82F6"
        project.company = company

        let session = Session(context: viewContext)
        session.id = UUID()
        session.note = "Homepage audit"
        session.project = project

        let segment = SessionSegment(context: viewContext)
        segment.id = UUID()
        segment.startAt = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
        segment.endAt = Date()
        segment.session = session
        session.refreshStartedAt()

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Open_Timer")
        if let description = container.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
            // Migrate lightweight model changes automatically instead of crashing.
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        let loadedContainer = container
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Don't crash a shipping app on store-load failure. Log the error and
                // fall back to an in-memory store so the app stays usable this session.
                NSLog("[Open Timer] Failed to load persistent store: \(error), \(error.userInfo)")
                do {
                    try loadedContainer.persistentStoreCoordinator.addPersistentStore(
                        ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil
                    )
                } catch {
                    NSLog("[Open Timer] In-memory fallback store also failed: \(error)")
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
