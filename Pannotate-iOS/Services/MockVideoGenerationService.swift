import Foundation

struct MockVideoGenerationService: VideoGenerationService {
    func submitGeneration(_ submission: VideoGenerationSubmission) async -> GenerationJob {
        GenerationJob(
            id: UUID(),
            requestID: submission.request.id,
            createdAt: Date(),
            failureReason: failureReason(for: submission.finalVideoPrompt),
            status: .queued
        )
    }

    func submitRetry(for clip: GeneratedClip) async -> GenerationJob {
        GenerationJob(
            id: clip.id,
            requestID: clip.generationRequestID ?? UUID(),
            createdAt: Date(),
            failureReason: nil,
            status: .queued
        )
    }

    func status(for job: GenerationJob, step: Int) async -> GenerationJobStatus {
        let delay: UInt64 = step == 0 ? 450_000_000 : 950_000_000
        try? await Task.sleep(nanoseconds: delay)

        if step >= 2, let failureReason = job.failureReason {
            return .failed(failureReason)
        }

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
            continuationSourceClipTitle: submission.continuationSourceClipTitle,
            failureReason: failureReason(from: status)
        )
    }

    func retryOutputClip(for job: GenerationJob, failedClip: GeneratedClip, status: GenerationJobStatus) -> GeneratedClip {
        GeneratedClip(
            id: failedClip.id,
            title: failedClip.title,
            duration: failedClip.duration,
            createdAt: createdAtLabel(for: status),
            status: status.clipStatus,
            thumbnail: failedClip.thumbnail,
            image: failedClip.image,
            generationRequestID: failedClip.generationRequestID ?? job.requestID,
            generationRequestSummary: failedClip.generationRequestSummary,
            interpretationMode: failedClip.interpretationMode,
            finalVideoPrompt: failedClip.finalVideoPrompt,
            originalGeneratedPrompt: failedClip.originalGeneratedPrompt,
            annotationCount: failedClip.annotationCount,
            generationMode: failedClip.generationMode,
            continuationSourceClipID: failedClip.continuationSourceClipID,
            continuationSourceClipTitle: failedClip.continuationSourceClipTitle,
            failureReason: failureReason(from: status)
        )
    }

    private func createdAtLabel(for status: GenerationJobStatus) -> String {
        switch status {
        case .queued:
            L10n.string("status.queued")
        case .processing:
            "Processing"
        case .completed:
            "Just now"
        case .failed:
            L10n.string("generation.failed")
        }
    }

    private func failureReason(for finalVideoPrompt: String) -> String? {
        finalVideoPrompt.localizedCaseInsensitiveContains("mock fail")
            ? L10n.string("generation.mock_generation_failed")
            : nil
    }

    private func failureReason(from status: GenerationJobStatus) -> String? {
        if case .failed(let reason) = status {
            return reason
        }

        return nil
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
