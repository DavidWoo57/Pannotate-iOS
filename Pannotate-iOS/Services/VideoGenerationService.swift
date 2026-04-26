import Foundation

protocol VideoGenerationService {
    func submitGeneration(_ submission: VideoGenerationSubmission) async -> GenerationJob
    func status(for job: GenerationJob, step: Int) async -> GenerationJobStatus
    func outputClip(for job: GenerationJob, submission: VideoGenerationSubmission, status: GenerationJobStatus) -> GeneratedClip
}

// A future RealVideoGenerationService can implement this protocol with provider networking,
// polling, cancellation, and media download once real API integration is in scope.
