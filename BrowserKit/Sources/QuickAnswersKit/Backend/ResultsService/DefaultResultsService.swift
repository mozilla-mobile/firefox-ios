// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Foundation
import MLPAKit

// MARK: - Protocol
protocol ResultsService: Sendable {
    func fetchResults(for transcription: String) async throws -> SearchResult
}

final class DefaultResultsService: ResultsService {
    private let client: LiteLLMClientProtocol
    private let configFetcher: QuickAnswersConfigFetcher

    init(client: LiteLLMClientProtocol, configFetcher: QuickAnswersConfigFetcher) {
        self.client = client
        self.configFetcher = configFetcher
    }

    func fetchResults(for transcription: String) async throws -> SearchResult {
        do {
            let config = try await configFetcher.fetch()
            let messages = makeMessages(for: transcription, config: config)
            let fullResponse = try await requestChatCompletion(for: messages, config: config)
            let citations = fullResponse.providerSpecificFields?.citations ?? []
            return formatResult(from: fullResponse.content, and: citations)
        } catch {
            throw mapError(error)
        }
    }

    private func makeMessages(for transcription: String, config: LLMConfig) -> [QuickAnswersMessage] {
        var messages: [QuickAnswersMessage] = []
        if !config.instructions.isEmpty {
            messages.append(LiteLLMMessage(role: .system, content: config.instructions))
        }
        messages.append(LiteLLMMessage(role: .user, content: transcription))
        return messages
    }

    private func requestChatCompletion(
        for messages: [QuickAnswersMessage],
        config: LLMConfig
    ) async throws -> QuickAnswersMessage {
        // TODO: FXIOS-15198 Handle errors appropriately
        // and may need to change type and not use String,
        // but waiting for what we get on server side
        return try await client.requestChatCompletion(
            messages: messages,
            config: config
        )
    }

    private func formatResult(from answer: String, and citations: [Citation]) -> SearchResult {
        // limit the citations to the first 3 in the array
        let filteredCitations = citations.prefix(3)
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
