import Foundation
import UIKit

struct GenerationProviderID: RawRepresentable, Hashable, Codable, Identifiable {
    let rawValue: String

    var id: String { rawValue }

    static let mock = GenerationProviderID(rawValue: "mock")
}

struct ProviderJobID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

enum GenerationProviderCapability: String, Codable, CaseIterable {
    case imageToVideo
    case continuation
    case promptEditing
    case mockFailure
}

struct GenerationProviderConfiguration: Codable, Equatable {
    let id: GenerationProviderID
    let displayName: String
    let modelID: String?
    let capabilities: [GenerationProviderCapability]

    static let mock = GenerationProviderConfiguration(
        id: .mock,
        displayName: "Mock Video Provider",
        modelID: "mock-video-preview-v1",
        capabilities: [.imageToVideo, .continuation, .promptEditing, .mockFailure]
    )
}

enum GenerationJobStatus: Codable, Equatable {
    case queued
    case processing(Int)
    case completed
    case failed(String)
    case cancelled

    var clipStatus: ClipStatus {
        switch self {
        case .queued:
            .queued
        case .processing(let progress):
            .processing(progress)
        case .completed:
            .done
        case .failed:
            .failed
        case .cancelled:
            .failed
        }
    }
}

struct GenerationJob: Identifiable, Codable {
    let id: UUID
    let requestID: UUID
    let createdAt: Date
    let failureReason: String?
    let providerID: GenerationProviderID
    let providerJobID: ProviderJobID
    let providerName: String
    let modelID: String?
    var status: GenerationJobStatus

    init(
        id: UUID,
        requestID: UUID,
        createdAt: Date,
        failureReason: String?,
        providerID: GenerationProviderID = .mock,
        providerJobID: ProviderJobID? = nil,
        providerName: String = GenerationProviderConfiguration.mock.displayName,
        modelID: String? = GenerationProviderConfiguration.mock.modelID,
        status: GenerationJobStatus
    ) {
        self.id = id
        self.requestID = requestID
        self.createdAt = createdAt
        self.failureReason = failureReason
        self.providerID = providerID
        self.providerJobID = providerJobID ?? ProviderJobID(rawValue: id.uuidString)
        self.providerName = providerName
        self.modelID = modelID
        self.status = status
    }
}

struct VideoGenerationSubmission {
    let request: GenerationRequest
    let pipelineResult: PromptPipelineResult
    let title: String
    let duration: String
    let thumbnail: ThumbnailStyle
    let image: UIImage?
    let continuationSourceClipID: UUID?
    let continuationSourceClipTitle: String?
    let finalVideoPrompt: String
    let originalGeneratedPrompt: String
    let payload: GenerationRequestPayload?

    init(
        request: GenerationRequest,
        pipelineResult: PromptPipelineResult,
        title: String,
        duration: String,
        thumbnail: ThumbnailStyle,
        image: UIImage?,
        continuationSourceClipID: UUID?,
        continuationSourceClipTitle: String?,
        finalVideoPrompt: String,
        originalGeneratedPrompt: String,
        payload: GenerationRequestPayload? = nil
    ) {
        self.request = request
        self.pipelineResult = pipelineResult
        self.title = title
        self.duration = duration
        self.thumbnail = thumbnail
        self.image = image
        self.continuationSourceClipID = continuationSourceClipID
        self.continuationSourceClipTitle = continuationSourceClipTitle
        self.finalVideoPrompt = finalVideoPrompt
        self.originalGeneratedPrompt = originalGeneratedPrompt
        self.payload = payload
    }
}

protocol GenerationParameterOption: CaseIterable, Hashable, Identifiable {
    var title: String { get }
}

enum GenerationDurationOption: String, GenerationParameterOption, Codable {
    case fourSeconds
    case sixSeconds
    case eightSeconds

    var id: String { rawValue }

    var value: String {
        switch self {
        case .fourSeconds:
            "4s"
        case .sixSeconds:
            "6s"
        case .eightSeconds:
            "8s"
        }
    }

    var title: String { value }
}

enum GenerationAspectRatioOption: String, GenerationParameterOption, Codable {
    case auto
    case widescreen
    case vertical
    case square

    var id: String { rawValue }

    var value: String {
        switch self {
        case .auto:
            "auto"
        case .widescreen:
            "16:9"
        case .vertical:
            "9:16"
        case .square:
            "1:1"
        }
    }

    var title: String {
        switch self {
        case .auto:
            L10n.string("generation.aspect_auto_original")
        case .widescreen:
            "16:9"
        case .vertical:
            "9:16"
        case .square:
            "1:1"
        }
    }
}

enum GenerationQualityOption: String, GenerationParameterOption, Codable {
    case fast
    case standard
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fast:
            L10n.string("generation.quality_fast")
        case .standard:
            L10n.string("generation.quality_standard")
        case .high:
            L10n.string("generation.quality_high")
        }
    }

    var outputStyle: String {
        switch self {
        case .fast:
            "Fast creator prototype"
        case .standard:
            "Cinematic creator prototype"
        case .high:
            "High-detail creator prototype"
        }
    }
}

struct GenerationParameterState: Codable, Equatable {
    var duration: GenerationDurationOption
    var aspectRatio: GenerationAspectRatioOption
    var quality: GenerationQualityOption
    var negativePrompt: String
    var seedText: String

    static let defaults = GenerationParameterState(
        duration: .fourSeconds,
        aspectRatio: .auto,
        quality: .standard,
        negativePrompt: "",
        seedText: ""
    )

    var parsedSeed: Int? {
        let trimmedSeed = seedText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedSeed.isEmpty ? nil : Int(trimmedSeed)
    }
}

struct GenerationRequestPayload: Identifiable, Codable {
    let id: UUID
    let requestID: UUID
    let projectID: UUID?
    let projectName: String?
    let createdAt: Date
    let providerID: GenerationProviderID
    let providerName: String
    let modelID: String?
    let prompt: GenerationPromptPackage
    let context: GenerationContextPackage
    let asset: GenerationAssetPackage
    let parameters: GenerationParameterPackage
    let appMetadata: [String: String]
    let isLocalMockOnly: Bool

    var compactSummary: String {
        var lines = [
            "\(L10n.string("generation.payload_provider")): \(providerName)",
            "\(L10n.string("generation.payload_mode")): \(context.generationMode.title) · \(prompt.interpretationMode.title)",
            "\(L10n.string("generation.payload_image_available")): \(asset.hasSourceImage ? L10n.string("common.yes") : L10n.string("common.no"))",
            "\(L10n.string("generation.payload_annotations")): \(prompt.annotationCount)",
            "\(L10n.string("generation.payload_duration_aspect_quality")): \(parameters.duration) · \(parameters.aspectRatio) · \(parameters.quality)",
            "\(L10n.string("generation.payload_local_mock_only")): \(isLocalMockOnly ? L10n.string("common.yes") : L10n.string("common.no"))"
        ]

        if let negativePrompt = parameters.negativePrompt {
            lines.append("\(L10n.string("generation.negative_prompt")): \(negativePrompt)")
        }

        lines.append("\(L10n.string("generation.seed")): \(parameters.seed.map { "\($0)" } ?? L10n.string("generation.automatic"))")

        return lines.joined(separator: "\n")
    }
}

struct GenerationPromptPackage: Codable {
    let userMotionPrompt: String
    let finalVideoPrompt: String
    let originalGeneratedFinalPrompt: String
    let interpretationMode: AnnotationInterpretationMode
    let annotationSummary: String
    let normalizedAnnotationDescriptions: [String]
    let annotationCount: Int
}

struct GenerationContextPackage: Codable {
    let generationMode: GenerationMode
    let continuationSourceClipID: UUID?
    let continuationSourceClipTitle: String?
    let sourceImageStatus: String
    let startsFromPreviousFrame: Bool
}

struct GenerationAssetPackage: Codable {
    let hasSourceImage: Bool
    let hasAdjustedImage: Bool
    let thumbnailReference: String
    let localReferenceDescription: String
    let mimeType: String?
    let encodedImageDataIncluded: Bool
    let isLocalMockOnly: Bool
}

struct GenerationParameterPackage: Codable {
    let duration: String
    let aspectRatio: String
    let quality: String
    let outputStyle: String
    let seed: Int?
    let negativePrompt: String?
}

struct ProviderGenerationRequest {
    let payload: GenerationRequestPayload
    let id: UUID
    let projectID: UUID?
    let projectName: String?
    let sourceImageStatus: String
    let sourceThumbnail: ThumbnailStyle
    let sourceImage: UIImage?
    let finalVideoPrompt: String
    let userMotionPrompt: String
    let interpretationMode: AnnotationInterpretationMode?
    let generationMode: GenerationMode
    let continuationSourceClipID: UUID?
    let continuationSourceClipTitle: String?
    let annotationCount: Int
    let annotationSummary: String
    let providerID: GenerationProviderID
    let modelID: String?
    let duration: String
    let aspectRatio: String
    let quality: String
    let outputStyle: String
    let createdAt: Date
    let allowsMockFailure: Bool

    init(
        payload: GenerationRequestPayload,
        sourceThumbnail: ThumbnailStyle,
        sourceImage: UIImage?,
        allowsMockFailure: Bool
    ) {
        self.payload = payload
        id = payload.requestID
        projectID = payload.projectID
        projectName = payload.projectName
        sourceImageStatus = payload.context.sourceImageStatus
        self.sourceThumbnail = sourceThumbnail
        self.sourceImage = sourceImage
        finalVideoPrompt = payload.prompt.finalVideoPrompt
        userMotionPrompt = payload.prompt.userMotionPrompt
        interpretationMode = payload.prompt.interpretationMode
        generationMode = payload.context.generationMode
        continuationSourceClipID = payload.context.continuationSourceClipID
        continuationSourceClipTitle = payload.context.continuationSourceClipTitle
        annotationCount = payload.prompt.annotationCount
        annotationSummary = payload.prompt.annotationSummary
        providerID = payload.providerID
        modelID = payload.modelID
        duration = payload.parameters.duration
        aspectRatio = payload.parameters.aspectRatio
        quality = payload.parameters.quality
        outputStyle = payload.parameters.outputStyle
        createdAt = payload.createdAt
        self.allowsMockFailure = allowsMockFailure
    }
}

struct ProviderJobSnapshot: Identifiable, Codable, Equatable {
    var id: ProviderJobID { providerJobID }

    let providerID: GenerationProviderID
    let providerJobID: ProviderJobID
    let requestID: UUID
    let providerName: String
    let modelID: String?
    let createdAt: Date
    let status: GenerationJobStatus
    let failureReason: String?
}

struct ProviderGenerationResult {
    let providerID: GenerationProviderID
    let providerJobID: ProviderJobID
    let requestID: UUID
    let videoURL: URL?
    let thumbnail: ThumbnailStyle
    let image: UIImage?
    let duration: String
    let providerName: String
    let modelID: String?
    let rawProviderMetadata: [String: String]
}

struct VisionInterpretationResult {
    let refinedVideoPrompt: String
    let payload: SmartLLMPayload
    let isMockResult: Bool
}
