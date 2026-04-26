import Foundation

struct MockVisionInterpretationService: VisionInterpretationService {
    func interpret(payload: SmartLLMPayload, simulatedPrompt: String) async -> VisionInterpretationResult {
        try? await Task.sleep(nanoseconds: 180_000_000)

        return VisionInterpretationResult(
            refinedVideoPrompt: simulatedPrompt,
            payload: payload,
            isMockResult: true
        )
    }
}
