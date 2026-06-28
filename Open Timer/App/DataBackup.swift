import Foundation
import CoreData
import UniformTypeIdentifiers
import AppKit

enum DataBackup {
    struct Payload: Codable {
        var version: Int
        var createdAt: Date
        var companies: [CompanyDTO]
        var projects: [ProjectDTO]
        var sessions: [SessionDTO]
        var segments: [SegmentDTO]
    }

    struct CompanyDTO: Codable {
        var id: UUID
        var name: String
    }

    struct ProjectDTO: Codable {
        var id: UUID
        var name: String
        var colorHex: String?
        var isArchived: Bool
        var isActive: Bool
        var hourlyRate: Double
        var monthlyFee: Double
        var companyID: UUID
    }

    struct SessionDTO: Codable {
        var id: UUID
        var note: String?
        var projectID: UUID
    }

    struct SegmentDTO: Codable {
        var id: UUID
        var startAt: Date
        var endAt: Date?
        var sessionID: UUID
    }

    enum ImportMode {
        case replaceAll
        case merge
    }

    static func exportBackup(context: NSManagedObjectContext) throws -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "open-timer-backup.json"
        guard panel.runModal() == .OK, let url = panel.url else { return false }

        let payload = try buildPayload(context: context)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        try data.write(to: url)
        return true
    }

    static func importBackup(context: NSManagedObjectContext, mode: ImportMode) throws -> Bool {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return false }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(Payload.self, from: data)

        try applyPayload(payload, context: context, mode: mode)
        return true
    }

    private static func buildPayload(context: NSManagedObjectContext) throws -> Payload {
        let companyRequest = NSFetchRequest<Company>(entityName: "Company")
        let projectRequest = NSFetchRequest<Project>(entityName: "Project")
        let sessionRequest = NSFetchRequest<Session>(entityName: "Session")
        let segmentRequest = NSFetchRequest<SessionSegment>(entityName: "SessionSegment")

        let companies = (try? context.fetch(companyRequest)) ?? []
        let projects = (try? context.fetch(projectRequest)) ?? []
        let sessions = (try? context.fetch(sessionRequest)) ?? []
        let segments = (try? context.fetch(segmentRequest)) ?? []

        let companyDTOs = companies.map { CompanyDTO(id: $0.id ?? UUID(), name: $0.name ?? "Company") }
        let projectDTOs = projects.compactMap { project -> ProjectDTO? in
            guard let id = project.id, let companyID = project.company?.id else { return nil }
            return ProjectDTO(
                id: id,
                name: project.name ?? "Project",
                colorHex: project.colorHex,
                isArchived: project.isArchived,
                isActive: project.isActive,
                hourlyRate: project.hourlyRate,
                monthlyFee: project.monthlyFee,
                companyID: companyID
            )
        }
        let sessionDTOs = sessions.compactMap { session -> SessionDTO? in
            guard let id = session.id, let projectID = session.project?.id else { return nil }
            return SessionDTO(id: id, note: session.note, projectID: projectID)
        }
        let segmentDTOs = segments.compactMap { segment -> SegmentDTO? in
            guard let id = segment.id, let startAt = segment.startAt, let sessionID = segment.session?.id else { return nil }
            return SegmentDTO(id: id, startAt: startAt, endAt: segment.endAt, sessionID: sessionID)
        }

        return Payload(
            version: 1,
            createdAt: Date(),
            companies: companyDTOs,
            projects: projectDTOs,
            sessions: sessionDTOs,
            segments: segmentDTOs
        )
    }

    private static func applyPayload(_ payload: Payload, context: NSManagedObjectContext, mode: ImportMode) throws {
        if mode == .replaceAll {
            DataExporter.resetAllData(context: context)
        }

        let companyFetch = NSFetchRequest<Company>(entityName: "Company")
        let projectFetch = NSFetchRequest<Project>(entityName: "Project")
        let sessionFetch = NSFetchRequest<Session>(entityName: "Session")
        let segmentFetch = NSFetchRequest<SessionSegment>(entityName: "SessionSegment")

        let existingCompanies = ((try? context.fetch(companyFetch)) ?? []).reduce(into: [UUID: Company]()) { dict, item in
            if let id = item.id { dict[id] = item }
        }
        let existingProjects = ((try? context.fetch(projectFetch)) ?? []).reduce(into: [UUID: Project]()) { dict, item in
            if let id = item.id { dict[id] = item }
        }
        let existingSessions = ((try? context.fetch(sessionFetch)) ?? []).reduce(into: [UUID: Session]()) { dict, item in
            if let id = item.id { dict[id] = item }
        }
        let existingSegments = ((try? context.fetch(segmentFetch)) ?? []).reduce(into: [UUID: SessionSegment]()) { dict, item in
            if let id = item.id { dict[id] = item }
        }

        for dto in payload.companies {
            if mode == .merge, existingCompanies[dto.id] != nil { continue }
            let company = existingCompanies[dto.id] ?? Company(context: context)
            company.id = dto.id
            company.name = dto.name
        }

        for dto in payload.projects {
            if mode == .merge, existingProjects[dto.id] != nil { continue }
            guard let company = existingCompanies[dto.companyID] ?? fetchCompany(id: dto.companyID, context: context) else { continue }
            let project = existingProjects[dto.id] ?? Project(context: context)
            project.id = dto.id
            project.name = dto.name
            project.colorHex = dto.colorHex
            project.isArchived = dto.isArchived
            project.isActive = dto.isActive
            project.hourlyRate = dto.hourlyRate
            project.monthlyFee = dto.monthlyFee
            project.company = company
        }

        for dto in payload.sessions {
            if mode == .merge, existingSessions[dto.id] != nil { continue }
            guard let project = existingProjects[dto.projectID] ?? fetchProject(id: dto.projectID, context: context) else { continue }
            let session = existingSessions[dto.id] ?? Session(context: context)
            session.id = dto.id
            session.note = dto.note
            session.project = project
        }

        for dto in payload.segments {
            if mode == .merge, existingSegments[dto.id] != nil { continue }
            guard let session = existingSessions[dto.sessionID] ?? fetchSession(id: dto.sessionID, context: context) else { continue }
            let segment = existingSegments[dto.id] ?? SessionSegment(context: context)
            segment.id = dto.id
            segment.startAt = dto.startAt
            segment.endAt = dto.endAt
            segment.session = session
        }

        try context.save()
    }

    private static func fetchCompany(id: UUID, context: NSManagedObjectContext) -> Company? {
        let request = NSFetchRequest<Company>(entityName: "Company")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    private static func fetchProject(id: UUID, context: NSManagedObjectContext) -> Project? {
        let request = NSFetchRequest<Project>(entityName: "Project")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    private static func fetchSession(id: UUID, context: NSManagedObjectContext) -> Session? {
        let request = NSFetchRequest<Session>(entityName: "Session")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
}
