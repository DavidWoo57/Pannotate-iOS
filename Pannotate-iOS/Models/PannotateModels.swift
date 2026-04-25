import Foundation
import UIKit

struct Project: Identifiable {
    let id: UUID
    let title: String
    let clipCount: Int
    let updatedAt: String
    let thumbnail: ThumbnailStyle

    init(
        id: UUID = UUID(),
        title: String,
        clipCount: Int,
        updatedAt: String,
        thumbnail: ThumbnailStyle
    ) {
        self.id = id
        self.title = title
        self.clipCount = clipCount
        self.updatedAt = updatedAt
        self.thumbnail = thumbnail
    }
}

struct GeneratedClip: Identifiable {
    let id: UUID
    let title: String
    let duration: String
    let createdAt: String
    let status: ClipStatus
    let thumbnail: ThumbnailStyle
    let image: UIImage?
    let generationRequestID: UUID?
    let generationRequestSummary: String?
    let continuationSourceClipID: UUID?
    let continuationSourceClipTitle: String?

    init(
        id: UUID = UUID(),
        title: String,
        duration: String,
        createdAt: String,
        status: ClipStatus,
        thumbnail: ThumbnailStyle,
        image: UIImage? = nil,
        generationRequestID: UUID? = nil,
        generationRequestSummary: String? = nil,
        continuationSourceClipID: UUID? = nil,
        continuationSourceClipTitle: String? = nil
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.createdAt = createdAt
        self.status = status
        self.thumbnail = thumbnail
        self.image = image
        self.generationRequestID = generationRequestID
        self.generationRequestSummary = generationRequestSummary
        self.continuationSourceClipID = continuationSourceClipID
        self.continuationSourceClipTitle = continuationSourceClipTitle
    }
}

struct GenerationRequest: Identifiable {
    let id: UUID
    let createdAt: Date
    let projectID: UUID?
    let projectName: String?
    let sourceImageStatus: String
    let sourceClipID: UUID?
    let sourceClipTitle: String?
    let motionPrompt: String
    let annotationSummary: String
    let strokeCount: Int
    let circleCount: Int
    let textAnnotations: [String]
    let generationMode: GenerationMode
    let mockDuration: String
    let outputStyle: String
    let quality: String
    let startsFromPreviousFrame: Bool
    let generatedInstruction: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        projectID: UUID? = nil,
        projectName: String? = nil,
        sourceImageStatus: String,
        sourceClipID: UUID? = nil,
        sourceClipTitle: String? = nil,
        motionPrompt: String,
        annotationSummary: String,
        strokeCount: Int,
        circleCount: Int,
        textAnnotations: [String],
        generationMode: GenerationMode,
        mockDuration: String,
        outputStyle: String,
        quality: String,
        startsFromPreviousFrame: Bool,
        generatedInstruction: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.projectID = projectID
        self.projectName = projectName
        self.sourceImageStatus = sourceImageStatus
        self.sourceClipID = sourceClipID
        self.sourceClipTitle = sourceClipTitle
        self.motionPrompt = motionPrompt
        self.annotationSummary = annotationSummary
        self.strokeCount = strokeCount
        self.circleCount = circleCount
        self.textAnnotations = textAnnotations
        self.generationMode = generationMode
        self.mockDuration = mockDuration
        self.outputStyle = outputStyle
        self.quality = quality
        self.startsFromPreviousFrame = startsFromPreviousFrame
        self.generatedInstruction = generatedInstruction
    }
}

struct SequenceClip: Identifiable {
    let id: UUID
    let title: String
    let order: Int
    let duration: String
    let continuesFromPreviousFrame: Bool
    let thumbnail: ThumbnailStyle

    init(
        id: UUID = UUID(),
        title: String,
        order: Int,
        duration: String,
        continuesFromPreviousFrame: Bool,
        thumbnail: ThumbnailStyle
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.duration = duration
        self.continuesFromPreviousFrame = continuesFromPreviousFrame
        self.thumbnail = thumbnail
    }
}

struct StudioContinuationContext: Identifiable {
    let id: UUID
    let title: String
    let thumbnail: ThumbnailStyle
    let image: UIImage?
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let timeAgo: String
    let thumbnail: ThumbnailStyle
}

struct UserProfile {
    let name: String
    let handle: String
    let plan: String
    let monthlyCreditsUsed: Int
    let monthlyCreditsTotal: Int
    let projectCount: Int
    let clipCount: Int
    let exportCount: Int
}

enum ClipStatus {
    case done
    case processing(Int)
    case queued

    var label: String {
        switch self {
        case .done:
            "Done"
        case .processing(let progress):
            "\(progress)%"
        case .queued:
            "Queued"
        }
    }
}

enum ThumbnailStyle {
    case city
    case ocean
    case forest
    case lights
}

enum GenerationMode: String, CaseIterable, Identifiable {
    case newShot
    case continueFromLastFrame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newShot:
            "New Shot"
        case .continueFromLastFrame:
            "Continue from Last Frame"
        }
    }

    var requestValue: String {
        switch self {
        case .newShot:
            "new_shot"
        case .continueFromLastFrame:
            "continue_from_last_frame"
        }
    }
}
