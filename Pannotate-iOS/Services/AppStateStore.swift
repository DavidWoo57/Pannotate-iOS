import Foundation

struct PersistedAppState: Codable {
    var projects: [Project]
    var currentProjectID: UUID?
    var outputsByProject: [UUID: [GeneratedClip]]
    var sequenceClipsByProject: [UUID: [SequenceClip]]
    var studioStateByProject: [UUID: StudioProjectState]
    var studioContinuationContext: StudioContinuationContext?
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
