import Foundation

struct VideoPromptBuilder {
    static func build(context: VideoPromptBuildContext) -> PromptPipelineResult {
        let fastPrompt = buildFastPrompt(context: context)
        let smartPayload = buildSmartPayload(context: context)
        let smartMockResult = buildSmartMockResult(context: context)

        return PromptPipelineResult(
            interpretationMode: context.interpretationMode,
            normalizedAnnotations: context.annotationSummary.annotations,
            annotationSummary: context.annotationSummary,
            fastPrompt: fastPrompt,
            smartPayload: smartPayload,
            smartMockResult: smartMockResult,
            finalVideoPrompt: context.interpretationMode == .fast ? fastPrompt : smartMockResult
        )
    }

    private static func buildFastPrompt(context: VideoPromptBuildContext) -> String {
        var sentences = [
            "Generate a video from the original image.",
            "Treat all annotations as instructions only; do not render annotation marks, labels, outlines, or drawing strokes as objects in the scene."
        ]

        if let projectName = context.projectName {
            sentences.append("Project context: \(projectName).")
        }

        if context.generationMode == .continueFromLastFrame {
            let source = context.continuationSourceClipTitle ?? "the selected previous clip"
            sentences.append("Continue from the last-frame context of \"\(source)\".")
        } else {
            sentences.append("Create a new shot from the image.")
        }

        let prompt = cleanedPrompt(context.userMotionPrompt)
        if prompt.isEmpty {
            sentences.append("No detailed motion prompt was provided, so preserve the scene and use the annotations as the primary motion guidance.")
        } else {
            sentences.append("User motion prompt: \"\(prompt)\".")
        }

        if context.annotationSummary.annotations.isEmpty {
            sentences.append("No annotations were provided; rely on the user prompt and the original image content.")
        } else {
            sentences.append("Annotation guidance: \(annotationDescription(context.annotationSummary.annotations)).")
            if let likelyTarget = likelyTargetDescription(from: context.annotationSummary.annotations) {
                sentences.append("Likely target: \(likelyTarget).")
            }
        }

        return sentences.joined(separator: " ")
    }

    private static func buildSmartPayload(context: VideoPromptBuildContext) -> SmartLLMPayload {
        SmartLLMPayload(
            originalImageStatus: context.sourceImageStatus,
            userPrompt: cleanedPrompt(context.userMotionPrompt).isEmpty ? "No motion prompt provided" : cleanedPrompt(context.userMotionPrompt),
            projectName: context.projectName,
            generationMode: context.generationMode,
            continuationSourceClipTitle: context.continuationSourceClipTitle,
            annotations: context.annotationSummary.annotations,
            annotationSummary: context.annotationSummary.humanSummary,
            instruction: "You are interpreting user annotations on an image. Treat annotation marks as guidance, not scene content. Identify the likely target object or region and convert the user's prompt plus annotations into a concise video-generation instruction."
        )
    }

    private static func buildSmartMockResult(context: VideoPromptBuildContext) -> String {
        var sentences = [
            "Use the original image as the visual source and ignore all annotation graphics as renderable scene content."
        ]

        if context.generationMode == .continueFromLastFrame {
            let source = context.continuationSourceClipTitle ?? "the selected source clip"
            sentences.append("Continue naturally from \"\(source)\", preserving visual continuity from its mock last frame.")
        }

        let prompt = cleanedPrompt(context.userMotionPrompt)
        if prompt.isEmpty == false {
            sentences.append("Interpret the user's desired motion as: \"\(prompt)\".")
        }

        if context.annotationSummary.annotations.isEmpty {
            sentences.append("No user annotation targets were supplied, so infer the subject from the prompt and image composition.")
        } else {
            sentences.append("The annotation intent suggests \(annotationDescription(context.annotationSummary.annotations)).")
            if let likelyTarget = likelyTargetDescription(from: context.annotationSummary.annotations) {
                sentences.append("Prioritize \(likelyTarget) while keeping surrounding scene details stable.")
            }
        }

        return sentences.joined(separator: " ")
    }

    private static func annotationDescription(_ annotations: [NormalizedAnnotationIntent]) -> String {
        annotations
            .map { annotation in
                switch annotation.type {
                case .stroke:
                    return "a \(annotation.sizeDescription.rawValue) freehand stroke near the \(annotation.positionDescription.rawValue) region"
                case .circle:
                    return "a \(annotation.sizeDescription.rawValue) circled region near the \(annotation.positionDescription.rawValue) region"
                case .text:
                    let text = annotation.textContent.map { " saying \"\($0)\"" } ?? ""
                    return "a \(annotation.sizeDescription.rawValue) text label\(text) near the \(annotation.positionDescription.rawValue) region"
                }
            }
            .joined(separator: "; ")
    }

    private static func likelyTargetDescription(from annotations: [NormalizedAnnotationIntent]) -> String? {
        if let circle = annotations.first(where: { $0.type == .circle }) {
            return "the circled subject or region near the \(circle.positionDescription.rawValue) area"
        }

        if let text = annotations.first(where: { $0.type == .text }) {
            if let textContent = text.textContent, textContent.isEmpty == false {
                return "the subject indicated by the label \"\(textContent)\" near the \(text.positionDescription.rawValue) area"
            }
            return "the labeled region near the \(text.positionDescription.rawValue) area"
        }

        if let stroke = annotations.first(where: { $0.type == .stroke }) {
            return "the area traced by the drawing stroke near the \(stroke.positionDescription.rawValue) area"
        }

        return nil
    }

    private static func cleanedPrompt(_ prompt: String) -> String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
