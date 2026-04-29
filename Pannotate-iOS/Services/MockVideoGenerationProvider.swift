import Foundation

final class MockVideoGenerationProvider: VideoGenerationProvider {
    let configuration = GenerationProviderConfiguration.mock

    private let lock = NSLock()
    private var jobs: [ProviderJobID: MockProviderJobRecord] = [:]

    func submitGeneration(_ request: ProviderGenerationRequest) async -> ProviderJobSnapshot {
        let jobID = ProviderJobID(rawValue: "mock-\(UUID().uuidString)")
        let record = MockProviderJobRecord(
            request: request,
            providerJobID: jobID,
            createdAt: Date(),
            status: .queued,
            failureReason: request.allowsMockFailure ? failureReason(for: request.finalVideoPrompt) : nil,
            statusStep: 0
        )

        lock.withLock {
            jobs[jobID] = record
        }

        return snapshot(for: record)
    }

    func checkStatus(jobID: ProviderJobID) async -> ProviderJobSnapshot {
        guard let currentRecord = lock.withLock({ jobs[jobID] }) else {
            return missingJobSnapshot(jobID: jobID)
        }

        let delay: UInt64 = currentRecord.statusStep == 0 ? 450_000_000 : 950_000_000
        try? await Task.sleep(nanoseconds: delay)

        return lock.withLock {
            guard var record = jobs[jobID] else {
                return missingJobSnapshot(jobID: jobID)
            }

            record.status = nextStatus(for: record)
            record.statusStep += 1
            jobs[jobID] = record
            return snapshot(for: record)
        }
    }

    func fetchResult(jobID: ProviderJobID) async -> ProviderGenerationResult? {
        guard let record = lock.withLock({ jobs[jobID] }) else { return nil }

        guard case .completed = record.status else { return nil }

        return ProviderGenerationResult(
            providerID: configuration.id,
            providerJobID: record.providerJobID,
            requestID: record.request.id,
            videoURL: nil,
            thumbnail: record.request.sourceThumbnail,
            image: record.request.sourceImage,
            duration: record.request.duration,
            providerName: configuration.displayName,
            modelID: configuration.modelID,
            rawProviderMetadata: [
                "mode": "mock",
                "aspectRatio": record.request.aspectRatio,
                "quality": record.request.quality
            ]
        )
    }

    func cancel(jobID: ProviderJobID) async -> ProviderJobSnapshot {
        lock.withLock {
            guard var record = jobs[jobID] else {
                return missingJobSnapshot(jobID: jobID)
            }

            record.status = .cancelled
            jobs[jobID] = record
            return snapshot(for: record)
        }
    }

    private func nextStatus(for record: MockProviderJobRecord) -> GenerationJobStatus {
        if record.statusStep >= 2, let failureReason = record.failureReason {
            return .failed(failureReason)
        }

        switch record.statusStep {
        case 0:
            return .processing(45)
        case 1:
            return .processing(82)
        default:
            return .completed
        }
    }

    private func snapshot(for record: MockProviderJobRecord) -> ProviderJobSnapshot {
        ProviderJobSnapshot(
            providerID: configuration.id,
            providerJobID: record.providerJobID,
            requestID: record.request.id,
            providerName: configuration.displayName,
            modelID: configuration.modelID,
            createdAt: record.createdAt,
            status: record.status,
            failureReason: record.failureReason
        )
    }

    private func missingJobSnapshot(jobID: ProviderJobID) -> ProviderJobSnapshot {
        ProviderJobSnapshot(
            providerID: configuration.id,
            providerJobID: jobID,
            requestID: UUID(),
            providerName: configuration.displayName,
            modelID: configuration.modelID,
            createdAt: Date(),
            status: .failed(L10n.string("generation.something_went_wrong")),
            failureReason: L10n.string("generation.something_went_wrong")
        )
    }

    private func failureReason(for finalVideoPrompt: String) -> String? {
        finalVideoPrompt.localizedCaseInsensitiveContains("mock fail")
            ? L10n.string("generation.mock_generation_failed")
            : nil
    }
}

private struct MockProviderJobRecord {
    let request: ProviderGenerationRequest
    let providerJobID: ProviderJobID
    let createdAt: Date
    var status: GenerationJobStatus
    let failureReason: String?
    var statusStep: Int
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
