import Foundation

protocol VideoGenerationService {
    func submitGeneration(_ submission: VideoGenerationSubmission) async -> GenerationJob
    func submitRetry(for clip: GeneratedClip, projectID: UUID?) async -> GenerationJob
    func status(for job: GenerationJob, step: Int) async -> GenerationJobStatus
    func outputClip(for job: GenerationJob, submission: VideoGenerationSubmission, status: GenerationJobStatus) -> GeneratedClip
    func retryOutputClip(for job: GenerationJob, failedClip: GeneratedClip, status: GenerationJobStatus) -> GeneratedClip
}

// This app-facing facade lets SwiftUI screens stay stable while provider adapters
// evolve underneath for future networking, polling, cancellation, and media download.
