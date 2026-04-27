import Foundation
import UIKit

enum GenerationJobStatus: Codable, Equatable {
    case queued
    case processing(Int)
    case completed
    case failed(String)

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
        }
    }
}

struct GenerationJob: Identifiable, Codable {
    let id: UUID
    let requestID: UUID
    let createdAt: Date
    let failureReason: String?
    var status: GenerationJobStatus
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
}

struct VisionInterpretationResult {
    let refinedVideoPrompt: String
    let payload: SmartLLMPayload
    let isMockResult: Bool
}
