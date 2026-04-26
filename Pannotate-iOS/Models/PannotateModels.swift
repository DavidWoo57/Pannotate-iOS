import Foundation
import UIKit

struct Project: Identifiable, Codable {
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

struct GeneratedClip: Identifiable, Codable {
    let id: UUID
    let title: String
    let duration: String
    let createdAt: String
    let status: ClipStatus
    let thumbnail: ThumbnailStyle
    let image: UIImage?
    let generationRequestID: UUID?
    let generationRequestSummary: String?
    let interpretationMode: AnnotationInterpretationMode?
    let finalVideoPrompt: String?
    let originalGeneratedPrompt: String?
    let annotationCount: Int?
    let generationMode: GenerationMode?
    let continuationSourceClipID: UUID?
    let continuationSourceClipTitle: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case duration
        case createdAt
        case status
        case thumbnail
        case imageData
        case generationRequestID
        case generationRequestSummary
        case interpretationMode
        case finalVideoPrompt
        case originalGeneratedPrompt
        case annotationCount
        case generationMode
        case continuationSourceClipID
        case continuationSourceClipTitle
    }

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
        interpretationMode: AnnotationInterpretationMode? = nil,
        finalVideoPrompt: String? = nil,
        originalGeneratedPrompt: String? = nil,
        annotationCount: Int? = nil,
        generationMode: GenerationMode? = nil,
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
        self.interpretationMode = interpretationMode
        self.finalVideoPrompt = finalVideoPrompt
        self.originalGeneratedPrompt = originalGeneratedPrompt
        self.annotationCount = annotationCount
        self.generationMode = generationMode
        self.continuationSourceClipID = continuationSourceClipID
        self.continuationSourceClipTitle = continuationSourceClipTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        duration = try container.decode(String.self, forKey: .duration)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        status = try container.decode(ClipStatus.self, forKey: .status)
        thumbnail = try container.decode(ThumbnailStyle.self, forKey: .thumbnail)
        image = try container.decodeIfPresent(Data.self, forKey: .imageData).flatMap(UIImage.init(data:))
        generationRequestID = try container.decodeIfPresent(UUID.self, forKey: .generationRequestID)
        generationRequestSummary = try container.decodeIfPresent(String.self, forKey: .generationRequestSummary)
        interpretationMode = try container.decodeIfPresent(AnnotationInterpretationMode.self, forKey: .interpretationMode)
        finalVideoPrompt = try container.decodeIfPresent(String.self, forKey: .finalVideoPrompt)
        originalGeneratedPrompt = try container.decodeIfPresent(String.self, forKey: .originalGeneratedPrompt)
        annotationCount = try container.decodeIfPresent(Int.self, forKey: .annotationCount)
        generationMode = try container.decodeIfPresent(GenerationMode.self, forKey: .generationMode)
        continuationSourceClipID = try container.decodeIfPresent(UUID.self, forKey: .continuationSourceClipID)
        continuationSourceClipTitle = try container.decodeIfPresent(String.self, forKey: .continuationSourceClipTitle)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(duration, forKey: .duration)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(status, forKey: .status)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(image?.jpegData(compressionQuality: 0.82), forKey: .imageData)
        try container.encodeIfPresent(generationRequestID, forKey: .generationRequestID)
        try container.encodeIfPresent(generationRequestSummary, forKey: .generationRequestSummary)
        try container.encodeIfPresent(interpretationMode, forKey: .interpretationMode)
        try container.encodeIfPresent(finalVideoPrompt, forKey: .finalVideoPrompt)
        try container.encodeIfPresent(originalGeneratedPrompt, forKey: .originalGeneratedPrompt)
        try container.encodeIfPresent(annotationCount, forKey: .annotationCount)
        try container.encodeIfPresent(generationMode, forKey: .generationMode)
        try container.encodeIfPresent(continuationSourceClipID, forKey: .continuationSourceClipID)
        try container.encodeIfPresent(continuationSourceClipTitle, forKey: .continuationSourceClipTitle)
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

struct SequenceClip: Identifiable, Codable {
    let id: UUID
    let sourceOutputClipID: UUID?
    let title: String
    let order: Int
    let duration: String
    let continuesFromPreviousFrame: Bool
    let thumbnail: ThumbnailStyle
    let image: UIImage?

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceOutputClipID
        case title
        case order
        case duration
        case continuesFromPreviousFrame
        case thumbnail
        case imageData
    }

    init(
        id: UUID = UUID(),
        sourceOutputClipID: UUID? = nil,
        title: String,
        order: Int,
        duration: String,
        continuesFromPreviousFrame: Bool,
        thumbnail: ThumbnailStyle,
        image: UIImage? = nil
    ) {
        self.id = id
        self.sourceOutputClipID = sourceOutputClipID
        self.title = title
        self.order = order
        self.duration = duration
        self.continuesFromPreviousFrame = continuesFromPreviousFrame
        self.thumbnail = thumbnail
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sourceOutputClipID = try container.decodeIfPresent(UUID.self, forKey: .sourceOutputClipID)
        title = try container.decode(String.self, forKey: .title)
        order = try container.decode(Int.self, forKey: .order)
        duration = try container.decode(String.self, forKey: .duration)
        continuesFromPreviousFrame = try container.decode(Bool.self, forKey: .continuesFromPreviousFrame)
        thumbnail = try container.decode(ThumbnailStyle.self, forKey: .thumbnail)
        image = try container.decodeIfPresent(Data.self, forKey: .imageData).flatMap(UIImage.init(data:))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(sourceOutputClipID, forKey: .sourceOutputClipID)
        try container.encode(title, forKey: .title)
        try container.encode(order, forKey: .order)
        try container.encode(duration, forKey: .duration)
        try container.encode(continuesFromPreviousFrame, forKey: .continuesFromPreviousFrame)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(image?.jpegData(compressionQuality: 0.82), forKey: .imageData)
    }
}

struct StudioContinuationContext: Identifiable, Codable {
    let id: UUID
    let title: String
    let thumbnail: ThumbnailStyle
    let image: UIImage?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnail
        case imageData
    }

    init(id: UUID, title: String, thumbnail: ThumbnailStyle, image: UIImage?) {
        self.id = id
        self.title = title
        self.thumbnail = thumbnail
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        thumbnail = try container.decode(ThumbnailStyle.self, forKey: .thumbnail)
        image = try container.decodeIfPresent(Data.self, forKey: .imageData).flatMap(UIImage.init(data:))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(image?.jpegData(compressionQuality: 0.82), forKey: .imageData)
    }
}

struct StudioProjectState: Codable {
    var motionPrompt: String
    var interpretationMode: AnnotationInterpretationMode
    var annotations: [StudioAnnotation]
    var selectedMockThumbnail: ThumbnailStyle?
    var selectedImageData: Data?
    var imageScale: CGFloat
    var imageOffset: CGSize

    init(
        motionPrompt: String = "",
        interpretationMode: AnnotationInterpretationMode = .fast,
        annotations: [StudioAnnotation] = [],
        selectedMockThumbnail: ThumbnailStyle? = nil,
        selectedImageData: Data? = nil,
        imageScale: CGFloat = 1,
        imageOffset: CGSize = .zero
    ) {
        self.motionPrompt = motionPrompt
        self.interpretationMode = interpretationMode
        self.annotations = annotations
        self.selectedMockThumbnail = selectedMockThumbnail
        self.selectedImageData = selectedImageData
        self.imageScale = imageScale
        self.imageOffset = imageOffset
    }
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

enum ClipStatus: Codable {
    case done
    case processing(Int)
    case queued
    case failed

    var label: String {
        switch self {
        case .done:
            L10n.string("status.done")
        case .processing(let progress):
            "\(progress)%"
        case .queued:
            L10n.string("status.queued")
        case .failed:
            L10n.string("status.failed")
        }
    }
}

enum ThumbnailStyle: Codable {
    case city
    case ocean
    case forest
    case lights
}

enum GenerationMode: String, CaseIterable, Identifiable, Codable {
    case newShot
    case continueFromLastFrame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newShot:
            L10n.string("generation.new_shot")
        case .continueFromLastFrame:
            L10n.string("generation.continue_from_last_frame")
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
