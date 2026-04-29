import Foundation

protocol VideoGenerationProvider {
    var configuration: GenerationProviderConfiguration { get }

    func submitGeneration(_ request: ProviderGenerationRequest) async -> ProviderJobSnapshot
    func checkStatus(jobID: ProviderJobID) async -> ProviderJobSnapshot
    func fetchResult(jobID: ProviderJobID) async -> ProviderGenerationResult?
    func cancel(jobID: ProviderJobID) async -> ProviderJobSnapshot
}

// Future real providers such as Runway, Kling, Pika, Luma, or a custom backend
// can implement this protocol with networking, auth, polling, and media download.
