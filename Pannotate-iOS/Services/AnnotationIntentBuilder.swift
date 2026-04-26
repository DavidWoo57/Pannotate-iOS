import CoreGraphics
import Foundation

struct AnnotationIntentBuilder {
    static func buildSummary(from annotations: [StudioAnnotation], canvasSize: CGSize) -> AnnotationIntentSummary {
        let normalizedAnnotations = annotations.compactMap { annotation in
            normalizedAnnotation(from: annotation, canvasSize: canvasSize)
        }

        return AnnotationIntentSummary(
            annotations: normalizedAnnotations,
            strokeCount: normalizedAnnotations.filter { $0.type == .stroke }.count,
            circleCount: normalizedAnnotations.filter { $0.type == .circle }.count,
            textCount: normalizedAnnotations.filter { $0.type == .text }.count,
            textContents: normalizedAnnotations.compactMap(\.textContent)
        )
    }

    private static func normalizedAnnotation(from annotation: StudioAnnotation, canvasSize: CGSize) -> NormalizedAnnotationIntent? {
        let rawBounds: CGRect
        let type: NormalizedAnnotationType
        let textContent: String?

        switch annotation {
        case .stroke(let stroke):
            guard let bounds = bounds(for: stroke.points) else { return nil }
            rawBounds = bounds
            type = .stroke
            textContent = nil
        case .circle(let circle):
            rawBounds = circle.rect
            type = .circle
            textContent = nil
        case .text(let text):
            rawBounds = textBounds(for: text)
            type = .text
            textContent = text.text
        }

        let normalizedBounds = normalized(rawBounds, canvasSize: canvasSize)

        return NormalizedAnnotationIntent(
            id: annotation.id,
            type: type,
            normalizedBounds: normalizedBounds,
            positionDescription: positionDescription(for: normalizedBounds),
            sizeDescription: sizeDescription(for: normalizedBounds),
            textContent: textContent
        )
    }

    private static func bounds(for points: [CGPoint]) -> CGRect? {
        guard let first = points.first else { return nil }

        let bounds = points.reduce(CGRect(origin: first, size: .zero)) { partial, point in
            partial.union(CGRect(origin: point, size: .zero))
        }

        return bounds.insetBy(dx: -4, dy: -4)
    }

    private static func textBounds(for text: AnnotationText) -> CGRect {
        let width = max(CGFloat(text.text.count) * 9 + 28, 72)
        let height: CGFloat = 42

        return CGRect(
            x: text.position.x - width / 2,
            y: text.position.y - height / 2,
            width: width,
            height: height
        )
    }

    private static func normalized(_ rect: CGRect, canvasSize: CGSize) -> NormalizedAnnotationBounds {
        let width = max(canvasSize.width, 1)
        let height = max(canvasSize.height, 1)
        let minX = clamp(rect.minX / width)
        let minY = clamp(rect.minY / height)
        let maxX = clamp(rect.maxX / width)
        let maxY = clamp(rect.maxY / height)

        return NormalizedAnnotationBounds(
            minX: minX,
            minY: minY,
            width: max(maxX - minX, 0.01),
            height: max(maxY - minY, 0.01)
        )
    }

    private static func positionDescription(for bounds: NormalizedAnnotationBounds) -> AnnotationPositionDescription {
        let horizontal: Int
        switch bounds.midX {
        case ..<0.34:
            horizontal = 0
        case 0.34..<0.67:
            horizontal = 1
        default:
            horizontal = 2
        }

        let vertical: Int
        switch bounds.midY {
        case ..<0.34:
            vertical = 0
        case 0.34..<0.67:
            vertical = 1
        default:
            vertical = 2
        }

        switch (vertical, horizontal) {
        case (0, 0): return .upperLeft
        case (0, 1): return .upperCenter
        case (0, 2): return .upperRight
        case (1, 0): return .centerLeft
        case (1, 1): return .center
        case (1, 2): return .centerRight
        case (2, 0): return .lowerLeft
        case (2, 1): return .lowerCenter
        default: return .lowerRight
        }
    }

    private static func sizeDescription(for bounds: NormalizedAnnotationBounds) -> AnnotationSizeDescription {
        switch bounds.area {
        case ..<0.08:
            return .small
        case 0.08..<0.28:
            return .medium
        default:
            return .large
        }
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }
}
