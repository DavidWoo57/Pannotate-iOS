import Foundation

protocol VisionInterpretationService {
    func interpret(payload: SmartLLMPayload, simulatedPrompt: String) async -> VisionInterpretationResult
}

// A future RealVisionInterpretationService can implement this protocol with a visual LLM
// request once remote interpretation is in scope. No network work happens in this step.
