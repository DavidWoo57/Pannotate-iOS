import Foundation

struct MockVideoGenerationService: VideoGenerationService {
    private let provider: VideoGenerationProvider

    init(provider: VideoGenerationProvider = MockVideoGenerationProvider()) {
        self.provider = provider
    }

    func submitGeneration(_ submission: VideoGenerationSubmission) async -> GenerationJob {
        let payload = submission.payload ?? GenerationPayloadBuilder.build(
            submission: submission,
            providerConfiguration: provider.configuration
        )
        let providerRequest = ProviderGenerationRequest(
            payload: payload,
            sourceThumbnail: submission.thumbnail,
            sourceImage: submission.image,
            allowsMockFailure: true
        )
        let snapshot = await provider.submitGeneration(providerRequest)
        return generationJob(from: snapshot)
    }

    func submitRetry(for clip: GeneratedClip, projectID: UUID?) async -> GenerationJob {
        let providerConfiguration = GenerationProviderConfiguration(
            id: GenerationProviderID(rawValue: clip.generationProviderID ?? provider.configuration.id.rawValue),
            displayName: clip.generationProviderName ?? provider.configuration.displayName,
            modelID: clip.providerModelID ?? provider.configuration.modelID,
            capabilities: provider.configuration.capabilities
        )
        let payload = GenerationPayloadBuilder.buildRetryPayload(
            failedClip: clip,
            projectID: projectID,
            providerConfiguration: providerConfiguration
        )
        let providerRequest = ProviderGenerationRequest(
            payload: payload,
            sourceThumbnail: clip.thumbnail,
            sourceImage: clip.image,
            allowsMockFailure: false
        )
        let snapshot = await provider.submitGeneration(providerRequest)
        return generationJob(from: snapshot, id: clip.id)
    }

    func status(for job: GenerationJob, step: Int) async -> GenerationJobStatus {
        let snapshot = await provider.checkStatus(jobID: job.providerJobID)
        return snapshot.status
    }

    func outputClip(for job: GenerationJob, submission: VideoGenerationSubmission, status: GenerationJobStatus) -> GeneratedClip {
        let payload = submission.payload ?? GenerationPayloadBuilder.build(
            submission: submission,
            providerConfiguration: provider.configuration
        )
        let payloadSummary = payload.compactSummary
        return GeneratedClip(
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
            failureReason: failureReason(from: status),
            generationProviderID: job.providerID.rawValue,
            generationProviderName: job.providerName,
            providerJobID: job.providerJobID.rawValue,
            providerModelID: job.modelID,
            generationPayloadSummary: payloadSummary,
            generationParameters: submission.request.generationParameters,
            outputResult: outputResult(for: job, payload: payload, status: status, payloadSummary: payloadSummary)
        )
    }

    func retryOutputClip(for job: GenerationJob, failedClip: GeneratedClip, status: GenerationJobStatus) -> GeneratedClip {
        let payload = GenerationPayloadBuilder.buildRetryPayload(
            failedClip: failedClip,
            projectID: nil,
            providerConfiguration: GenerationProviderConfiguration(
                id: job.providerID,
                displayName: job.providerName,
                modelID: job.modelID,
                capabilities: provider.configuration.capabilities
            )
        )
        let payloadSummary = failedClip.generationPayloadSummary ?? payload.compactSummary
        return GeneratedClip(
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
            failureReason: failureReason(from: status),
            generationProviderID: job.providerID.rawValue,
            generationProviderName: job.providerName,
            providerJobID: job.providerJobID.rawValue,
            providerModelID: job.modelID,
            generationPayloadSummary: payloadSummary,
            generationParameters: failedClip.generationParameters ?? .defaults,
            outputResult: outputResult(for: job, payload: payload, status: status, payloadSummary: payloadSummary)
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
        case .failed, .cancelled:
            L10n.string("generation.failed")
        }
    }

    private func failureReason(from status: GenerationJobStatus) -> String? {
        if case .failed(let reason) = status {
            return reason
        }

        return nil
    }

    private func generationJob(from snapshot: ProviderJobSnapshot, id: UUID? = nil) -> GenerationJob {
        GenerationJob(
            id: id ?? UUID(),
            requestID: snapshot.requestID,
            createdAt: snapshot.createdAt,
            failureReason: snapshot.failureReason,
            providerID: snapshot.providerID,
            providerJobID: snapshot.providerJobID,
            providerName: snapshot.providerName,
            modelID: snapshot.modelID,
            status: snapshot.status
        )
    }

    private func outputResult(
        for job: GenerationJob,
        payload: GenerationRequestPayload,
        status: GenerationJobStatus,
        payloadSummary: String
    ) -> GeneratedOutputResult? {
        guard case .completed = status else { return nil }

        let resolution = resolution(for: payload.parameters.aspectRatio)
        return GeneratedOutputResult(
            providerID: job.providerID.rawValue,
            providerName: job.providerName,
            providerJobID: job.providerJobID.rawValue,
            modelID: job.modelID,
            createdAt: job.createdAt,
            completedAt: Date(),
            duration: payload.parameters.duration,
            generationParameterSummary: generationParameterSummary(for: payload.parameters),
            payloadSummary: payloadSummary,
            failureReason: nil,
            rawProviderMetadata: [
                "mode": "mock",
                "aspectRatio": payload.parameters.aspectRatio,
                "quality": payload.parameters.quality,
                "playback": "unavailable"
            ],
            media: OutputMediaMetadata(
                remoteVideoURL: nil,
                localVideoFileURL: nil,
                thumbnailReference: payload.asset.thumbnailReference,
                hasThumbnailImage: payload.asset.hasSourceImage,
                duration: payload.parameters.duration,
                resolution: resolution,
                fileSize: nil,
                isPlaybackAvailable: false,
                isExportAvailable: false,
                isMockResult: true
            )
        )
    }

    private func generationParameterSummary(for parameters: GenerationParameterPackage) -> String {
        var lines = [
            "\(L10n.string("generation.duration")): \(parameters.duration)",
            "\(L10n.string("generation.aspect_ratio")): \(parameters.aspectRatio)",
            "\(L10n.string("generation.quality")): \(parameters.quality)"
        ]

        if let negativePrompt = parameters.negativePrompt {
            lines.append("\(L10n.string("generation.negative_prompt")): \(negativePrompt)")
        }

        lines.append("\(L10n.string("generation.seed")): \(parameters.seed.map { "\($0)" } ?? L10n.string("generation.automatic"))")
        return lines.joined(separator: "\n")
    }

    private func resolution(for aspectRatio: String) -> String {
        switch aspectRatio {
        case "16:9":
            "1280x720"
        case "9:16":
            "720x1280"
        case "1:1":
            "1024x1024"
        default:
            "1280x720"
        }
    }

    private func generationRequestSummary(for request: GenerationRequest, pipelineResult: PromptPipelineResult, finalVideoPrompt: String) -> String {
        """
        Request \(request.id.uuidString.prefix(8)) · \(request.generationMode.title)
        Provider: \(provider.configuration.displayName)
        Model: \(provider.configuration.modelID ?? "None")
        API payload: local/mock metadata package, no raw API keys or image bytes
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
