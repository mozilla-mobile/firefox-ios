// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Foundation
import MLPAKit

// MARK: - Protocol
protocol ResultsService: Sendable {
    /// Streams the answer for `transcription`, emitting the result accumulated so far every time the
    /// backend sends a chunk. The stream fails with a `ResultsServiceError`.
    func fetchResults(for transcription: String) -> AsyncThrowingStream<SearchResult, Error>
}

final class DefaultResultsService: ResultsService {
    private struct Constants {
        static let maxCitationsCount = 2
    }
    private let client: LiteLLMClientProtocol
    private let configFetcher: QuickAnswersConfigFetcher

    init(client: LiteLLMClientProtocol, configFetcher: QuickAnswersConfigFetcher) {
        self.client = client
        self.configFetcher = configFetcher
    }

    func fetchResults(for transcription: String) -> AsyncThrowingStream<SearchResult, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await streamResults(for: transcription, into: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: mapError(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Accumulates the streamed chunks, yielding the answer built so far together with the citations
    /// received up to that point. Providers send citations in their own chunk, usually the last one,
    /// so the sources appear once the answer is (nearly) complete.
    private func streamResults(
        for transcription: String,
        into continuation: AsyncThrowingStream<SearchResult, Error>.Continuation
    ) async throws {
        let config = try await configFetcher.fetch()
        let messages = makeMessages(for: transcription, config: config)
        // TODO: FXIOS-15198 Handle errors appropriately
        let stream = try await client.requestChatCompletionStreamed(messages: messages, config: config)

        var answer = ""
        var citations: [Citation] = []
        var didYieldResult = false
        for try await chunk in stream {
            try Task.checkCancellation()
            let newCitations = chunk.providerSpecificFields?.citations ?? []
            answer += chunk.content
            if !newCitations.isEmpty {
                citations = newCitations
            }
            // Skip chunks that carry neither text nor citations, they'd emit a duplicate result.
            guard !answer.isEmpty, !chunk.content.isEmpty || !newCitations.isEmpty else { continue }
            didYieldResult = true
            continuation.yield(formatResult(from: answer, and: citations))
        }
        guard didYieldResult else { throw ResultsServiceError.noMessage }
    }

    private func makeMessages(for transcription: String, config: LLMConfig) -> [QuickAnswersMessage] {
        var messages: [QuickAnswersMessage] = []
        if !config.instructions.isEmpty {
            messages.append(LiteLLMMessage(role: .system, content: config.instructions))
        }
        messages.append(LiteLLMMessage(role: .user, content: transcription))
        return messages
    }

    private func formatResult(from answer: String, and citations: [Citation]) -> SearchResult {
        // limit the citations in the array to maximum allowed
        let filteredCitations = citations.prefix(Constants.maxCitationsCount)
        let sources = filteredCitations.map { citation in
            SearchResult.Source(
                title: citation.title ?? "",
                url: URL(string: citation.url ?? ""),
                thumbnailURL: URL(string: citation.image ?? ""),
                faviconURL: URL(string: citation.favicon ?? "")
            )
        }
        return SearchResult(resultText: answer, sources: Array(sources))
    }

    /// Maps underlying errors to `ResultsServiceError` types.
    private func mapError(_ error: Error) -> ResultsServiceError {
        switch error {
        case let e as ResultsServiceError:
            return e
        case LiteLLMClientError.requestCreationFailed:
            return .requestCreationFailed
        case LiteLLMClientError.invalidResponse(let statusCode) where statusCode == 429:
            return .rateLimited
        case LiteLLMClientError.invalidResponse(let statusCode) where statusCode == 403:
            return .maxUsers
        case LiteLLMClientError.invalidResponse(let statusCode) where statusCode == 413:
            return .payloadTooLarge
        case LiteLLMClientError.invalidResponse(let statusCode):
            return .invalidResponse(statusCode: statusCode)
        case LiteLLMClientError.noContent:
            return .noMessage
        case let e as LiteLLMClientError: return .unknown(e.localizedDescription)
        default: return .unknown(error.localizedDescription)
        }
    }
}
