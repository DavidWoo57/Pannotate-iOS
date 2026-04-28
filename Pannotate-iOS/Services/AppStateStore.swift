import Foundation

struct PersistedAppState: Codable {
    var projects: [Project]
    var currentProjectID: UUID?
    var outputsByProject: [UUID: [GeneratedClip]]
    var sequenceClipsByProject: [UUID: [SequenceClip]]
    var studioStateByProject: [UUID: StudioProjectState]
    var studioContinuationContext: StudioContinuationContext?
    var activityByProject: [UUID: [ProjectActivityItem]]

    private enum CodingKeys: String, CodingKey {
        case projects
        case currentProjectID
        case outputsByProject
        case sequenceClipsByProject
        case studioStateByProject
        case studioContinuationContext
        case activityByProject
    }

    init(
        projects: [Project],
        currentProjectID: UUID?,
        outputsByProject: [UUID: [GeneratedClip]],
        sequenceClipsByProject: [UUID: [SequenceClip]],
        studioStateByProject: [UUID: StudioProjectState],
        studioContinuationContext: StudioContinuationContext?,
        activityByProject: [UUID: [ProjectActivityItem]] = [:]
    ) {
        self.projects = projects
        self.currentProjectID = currentProjectID
        self.outputsByProject = outputsByProject
        self.sequenceClipsByProject = sequenceClipsByProject
        self.studioStateByProject = studioStateByProject
        self.studioContinuationContext = studioContinuationContext
        self.activityByProject = activityByProject
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projects = try container.decode([Project].self, forKey: .projects)
        currentProjectID = try container.decodeIfPresent(UUID.self, forKey: .currentProjectID)
        outputsByProject = try container.decode([UUID: [GeneratedClip]].self, forKey: .outputsByProject)
        sequenceClipsByProject = try container.decode([UUID: [SequenceClip]].self, forKey: .sequenceClipsByProject)
        studioStateByProject = try container.decode([UUID: StudioProjectState].self, forKey: .studioStateByProject)
        studioContinuationContext = try container.decodeIfPresent(StudioContinuationContext.self, forKey: .studioContinuationContext)
        activityByProject = try container.decodeIfPresent([UUID: [ProjectActivityItem]].self, forKey: .activityByProject) ?? [:]
    }
}

enum AppStateStore {
    private static let folderName = "PannotatePrototype"
    private static let fileName = "app-state.json"

    static var fileURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent(folderName, isDirectory: true).appendingPathComponent(fileName)
    }

    static func load() -> PersistedAppState? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(PersistedAppState.self, from: data)
        } catch {
            return nil
        }
    }

    static func save(_ state: PersistedAppState) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("Could not save local prototype state: \(error)")
            #endif
        }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        JSONDecoder()
    }
}
