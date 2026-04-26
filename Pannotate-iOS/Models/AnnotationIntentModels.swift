import CoreGraphics
import Foundation

enum AnnotationInterpretationMode: String, CaseIterable, Identifiable, Codable {
    case fast
    case smart

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fast:
            L10n.string("interpretation.fast")
        case .smart:
            L10n.string("interpretation.smart")
        }
    }

    var requestValue: String { rawValue }
}

struct AnnotationStroke: Identifiable, Codable {
    let id: UUID
    var points: [CGPoint]

    init(id: UUID = UUID(), points: [CGPoint]) {
        self.id = id
        self.points = points
    }
}

struct AnnotationCircle: Identifiable, Codable {
    let id: UUID
    var rect: CGRect

    init(id: UUID = UUID(), rect: CGRect) {
        self.id = id
        self.rect = rect
    }
}

struct AnnotationText: Identifiable, Codable {
    let id: UUID
    var text: String
    var position: CGPoint

    init(id: UUID = UUID(), text: String, position: CGPoint) {
        self.id = id
        self.text = text
        self.position = position
    }
}

enum StudioAnnotation: Identifiable, Codable {
    case stroke(AnnotationStroke)
    case circle(AnnotationCircle)
    case text(AnnotationText)

    var id: UUID {
        switch self {
        case .stroke(let stroke):
            stroke.id
        case .circle(let circle):
            circle.id
        case .text(let text):
            text.id
        }
    }

    var stroke: AnnotationStroke? {
        if case .stroke(let stroke) = self { return stroke }
        return nil
    }

    var circle: AnnotationCircle? {
        if case .circle(let circle) = self { return circle }
        return nil
    }

    var text: AnnotationText? {
        if case .text(let text) = self { return text }
        return nil
    }
}

enum NormalizedAnnotationType: String {
    case stroke
    case circle
    case text
}

struct NormalizedAnnotationBounds {
    let minX: CGFloat
    let minY: CGFloat
    let width: CGFloat
    let height: CGFloat

    var midX: CGFloat { minX + width / 2 }
    var midY: CGFloat { minY + height / 2 }
    var area: CGFloat { width * height }
}

enum AnnotationPositionDescription: String {
    case upperLeft = "upper-left"
    case upperCenter = "upper-center"
    case upperRight = "upper-right"
    case centerLeft = "center-left"
    case center = "center"
    case centerRight = "center-right"
    case lowerLeft = "lower-left"
    case lowerCenter = "lower-center"
    case lowerRight = "lower-right"
}

enum AnnotationSizeDescription: String {
    case small
    case medium
    case large
}

struct NormalizedAnnotationIntent: Identifiable {
    let id: UUID
    let type: NormalizedAnnotationType
    let normalizedBounds: NormalizedAnnotationBounds
    let positionDescription: AnnotationPositionDescription
    let sizeDescription: AnnotationSizeDescription
    let textContent: String?

    var readableDescription: String {
        var parts = ["\(sizeDescription.rawValue) \(type.rawValue) near \(positionDescription.rawValue)"]
        if let textContent, textContent.isEmpty == false {
            parts.append("text: \"\(textContent)\"")
        }
        return parts.joined(separator: ", ")
    }
}

struct AnnotationIntentSummary {
    let annotations: [NormalizedAnnotationIntent]
    let strokeCount: Int
    let circleCount: Int
    let textCount: Int
    let textContents: [String]

    var humanSummary: String {
        var lines = [
            "Normalized annotations: \(annotations.count)",
            "Freehand strokes: \(strokeCount)",
            "Circles / ellipses: \(circleCount)",
            "Text annotations: \(textCount)"
        ]

        if textContents.isEmpty == false {
            lines.append("Text content: \(textContents.joined(separator: "; "))")
        }

        if annotations.isEmpty {
            lines.append("No annotations have been added yet.")
        }

        return lines.joined(separator: "\n")
    }
}

struct SmartLLMPayload {
    let originalImageStatus: String
    let userPrompt: String
    let projectName: String?
    let generationMode: GenerationMode
    let continuationSourceClipTitle: String?
    let annotations: [NormalizedAnnotationIntent]
    let annotationSummary: String
    let instruction: String
}

struct VideoPromptBuildContext {
    let interpretationMode: AnnotationInterpretationMode
    let userMotionPrompt: String
    let projectName: String?
    let generationMode: GenerationMode
    let continuationSourceClipTitle: String?
    let sourceImageStatus: String
    let annotationSummary: AnnotationIntentSummary
}

struct PromptPipelineResult {
    let interpretationMode: AnnotationInterpretationMode
    let normalizedAnnotations: [NormalizedAnnotationIntent]
    let annotationSummary: AnnotationIntentSummary
    let fastPrompt: String
    let smartPayload: SmartLLMPayload
    let smartMockResult: String
    let finalVideoPrompt: String
}
