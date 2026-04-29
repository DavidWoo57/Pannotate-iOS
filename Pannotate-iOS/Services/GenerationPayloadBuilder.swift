import Foundation
import UIKit

struct GenerationPayloadBuilder {
    static func build(
        submission: VideoGenerationSubmission,
        providerConfiguration: GenerationProviderConfiguration = .mock
    ) -> GenerationRequestPayload {
        build(
            requestID: submission.request.id,
            projectID: submission.request.projectID,
            projectName: submission.request.projectName,
            createdAt: submission.request.createdAt,
            providerConfiguration: providerConfiguration,
            userMotionPrompt: submission.request.motionPrompt,
            finalVideoPrompt: submission.finalVideoPrompt,
            originalGeneratedPrompt: submission.originalGeneratedPrompt,
            interpretationMode: submission.pipelineResult.interpretationMode,
            annotationSummary: submission.request.annotationSummary,
            normalizedAnnotationDescriptions: submission.pipelineResult.normalizedAnnotations.map(\.readableDescription),
            annotationCount: submission.pipelineResult.normalizedAnnotations.count,
            generationMode: submission.request.generationMode,
            continuationSourceClipID: submission.continuationSourceClipID,
            continuationSourceClipTitle: submission.continuationSourceClipTitle,
            sourceImageStatus: submission.request.sourceImageStatus,
            startsFromPreviousFrame: submission.request.startsFromPreviousFrame,
            hasSourceImage: submission.image != nil || submission.request.startsFromPreviousFrame,
            hasAdjustedImage: submission.image != nil,
            thumbnail: submission.thumbnail,
            image: submission.image,
            localReferenceDescription: submission.request.sourceImageStatus,
            parameters: submission.request.generationParameters
        )
    }

    static func buildRetryPayload(
        failedClip: GeneratedClip,
        projectID: UUID?,
        providerConfiguration: GenerationProviderConfiguration = .mock
    ) -> GenerationRequestPayload {
        let generationMode = failedClip.generationMode ?? .newShot
        let sourceImageStatus: String
        switch generationMode {
        case .continueFromLastFrame:
            sourceImageStatus = "Continuation source from previous output"
        case .newShot:
            sourceImageStatus = "Previously submitted local source"
        }

        return build(
            requestID: failedClip.generationRequestID ?? UUID(),
            projectID: projectID,
            projectName: nil,
            createdAt: Date(),
            providerConfiguration: providerConfiguration,
            userMotionPrompt: failedClip.generationRequestSummary ?? "",
            finalVideoPrompt: failedClip.finalVideoPrompt ?? "",
            originalGeneratedPrompt: failedClip.originalGeneratedPrompt ?? failedClip.finalVideoPrompt ?? "",
            interpretationMode: failedClip.interpretationMode ?? .fast,
            annotationSummary: failedClip.generationRequestSummary ?? "",
            normalizedAnnotationDescriptions: [],
            annotationCount: failedClip.annotationCount ?? 0,
            generationMode: generationMode,
            continuationSourceClipID: failedClip.continuationSourceClipID,
            continuationSourceClipTitle: failedClip.continuationSourceClipTitle,
            sourceImageStatus: sourceImageStatus,
            startsFromPreviousFrame: generationMode == .continueFromLastFrame,
            hasSourceImage: failedClip.image != nil,
            hasAdjustedImage: failedClip.image != nil,
            thumbnail: failedClip.thumbnail,
            image: failedClip.image,
            localReferenceDescription: sourceImageStatus,
            parameters: failedClip.generationParameters ?? .defaults
        )
    }

    private static func build(
        requestID: UUID,
        projectID: UUID?,
        projectName: String?,
        createdAt: Date,
        providerConfiguration: GenerationProviderConfiguration,
        userMotionPrompt: String,
        finalVideoPrompt: String,
        originalGeneratedPrompt: String,
        interpretationMode: AnnotationInterpretationMode,
        annotationSummary: String,
        normalizedAnnotationDescriptions: [String],
        annotationCount: Int,
        generationMode: GenerationMode,
        continuationSourceClipID: UUID?,
        continuationSourceClipTitle: String?,
        sourceImageStatus: String,
        startsFromPreviousFrame: Bool,
        hasSourceImage: Bool,
        hasAdjustedImage: Bool,
        thumbnail: ThumbnailStyle,
        image: UIImage?,
        localReferenceDescription: String,
        parameters: GenerationParameterState
    ) -> GenerationRequestPayload {
        GenerationRequestPayload(
            id: requestID,
            requestID: requestID,
            projectID: projectID,
            projectName: projectName,
            createdAt: createdAt,
            providerID: providerConfiguration.id,
            providerName: providerConfiguration.displayName,
            modelID: providerConfiguration.modelID,
            prompt: GenerationPromptPackage(
                userMotionPrompt: userMotionPrompt,
                finalVideoPrompt: finalVideoPrompt,
                originalGeneratedFinalPrompt: originalGeneratedPrompt,
                interpretationMode: interpretationMode,
                annotationSummary: annotationSummary,
                normalizedAnnotationDescriptions: normalizedAnnotationDescriptions,
                annotationCount: annotationCount
            ),
            context: GenerationContextPackage(
                generationMode: generationMode,
                continuationSourceClipID: continuationSourceClipID,
                continuationSourceClipTitle: continuationSourceClipTitle,
                sourceImageStatus: sourceImageStatus,
                startsFromPreviousFrame: startsFromPreviousFrame
            ),
            asset: GenerationAssetPackage(
                hasSourceImage: hasSourceImage,
                hasAdjustedImage: hasAdjustedImage,
                thumbnailReference: String(describing: thumbnail),
                localReferenceDescription: localReferenceDescription,
                mimeType: image == nil ? nil : "image/jpeg",
                encodedImageDataIncluded: false,
                isLocalMockOnly: true
            ),
            parameters: GenerationParameterPackage(
                duration: parameters.duration.value,
                aspectRatio: parameters.aspectRatio.value,
                quality: parameters.quality.title,
                outputStyle: parameters.quality.outputStyle,
                seed: parameters.parsedSeed,
                negativePrompt: parameters.negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : parameters.negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            appMetadata: [
                "payloadVersion": "1",
                "assetEncoding": "metadata_only",
                "networkUpload": "false"
            ],
            isLocalMockOnly: true
        )
    }
}
