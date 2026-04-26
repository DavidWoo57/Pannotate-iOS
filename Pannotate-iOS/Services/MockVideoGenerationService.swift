import Foundation

struct MockVideoGenerationService: VideoGenerationService {
    func submitGeneration(_ submission: VideoGenerationSubmission) async -> GenerationJob {
        GenerationJob(
            id: UUID(),
            requestID: submission.request.id,
            createdAt: Date(),
            status: .queued
        )
    }

    func status(for job: GenerationJob, step: Int) async -> GenerationJobStatus {
        let delay: UInt64 = step == 0 ? 450_000_000 : 950_000_000
        try? await Task.sleep(nanoseconds: delay)

        switch step {
        case 0:
            return .processing(45)
        case 1:
            return .processing(82)
        default:
            return .completed
        }
    }

    func outputClip(for job: GenerationJob, submission: VideoGenerationSubmission, status: GenerationJobStatus) -> GeneratedClip {
        GeneratedClip(
            id: job.id,
            title: submission.title,
            duration: submission.duration,
            createdAt: createdAtLabel(for: status),
            status: status.clipStatus,
            thumbnail: submission.thumbnail,
            image: submission.image,
            generationRequestID: submission.request.id,
            generationRequestSummary: generationRequestSummary(for: submission.request, pipelineResult: submission.pipelineResult, finalVideoPrompt: submission.finalVideoPrompt),
            interpretationMode: submission.pipelineResult.interpretationMode,
            finalVideoPrompt: submission.finalVideoPrompt,
            originalGeneratedPrompt: submission.originalGeneratedPrompt,
            annotationCount: submission.pipelineResult.normalizedAnnotations.count,
            generationMode: submission.request.generationMode,
            continuationSourceClipID: submission.continuationSourceClipID,
            continuationSourceClipTitle: submission.continuationSourceClipTitle
        )
    }

    private func createdAtLabel(for status: GenerationJobStatus) -> String {
        switch status {
        case .queued:
            "Queued"
        case .processing:
            "Processing"
        case .completed:
            "Just now"
        case .failed:
            "Failed"
        }
    }

    private func generationRequestSummary(for request: GenerationRequest, pipelineResult: PromptPipelineResult, finalVideoPrompt: String) -> String {
        """
        Request \(request.id.uuidString.prefix(8)) · \(request.generationMode.title)
        Project: \(request.projectName ?? "No project")
        Interpretation: \(pipelineResult.interpretationMode.title)
        Source clip: \(request.sourceClipTitle ?? "None")
        Prompt: \(request.motionPrompt)
        Normalized annotations: \(pipelineResult.normalizedAnnotations.count)
        Annotations: \(request.strokeCount) strokes, \(request.circleCount) circles, \(request.textAnnotations.count) text labels
        Duration: \(request.mockDuration) · Quality: \(request.quality)
        Final video prompt: \(finalVideoPrompt)
        """
    }
}
