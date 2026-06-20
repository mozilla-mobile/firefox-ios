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
    private let config: LLMConfig

    init(client: LiteLLMClientProtocol, config: LLMConfig) {
        self.client = client
        self.config = config
    }

    func fetchResults(for transcription: String) async throws -> SearchResult {
        let messages = makeMessages(for: transcription)

        do {
            let fullResponse = try await requestChatCompletion(for: messages)
            let citations = fullResponse.providerSpecificFields?.citations ?? []
            return formatResult(from: fullResponse.content, and: citations)
        } catch {
            throw mapError(error)
        }
    }

    /// Builds the typed message array for a request. When `config.instructions` is non-empty (e.g. for the
    /// Exa model), a `.system` message is prepended ahead of the `.user` message; otherwise only the user
    /// message is sent.
    private func makeMessages(for transcription: String) -> [QuickAnswersMessage] {
        var messages: [QuickAnswersMessage] = []
        if !config.instructions.isEmpty {
            messages.append(LiteLLMMessage(role: .system, content: config.instructions))
        }
        messages.append(LiteLLMMessage(role: .user, content: transcription))
        return messages
    }

    private func requestChatCompletion(for messages: [QuickAnswersMessage]) async throws -> QuickAnswersMessage {
        // TODO: FXIOS-15198 Handle errors appropriately
        // and may need to change type and not use String,
        // but waiting for what we get on server side
        return try await client.requestChatCompletion(
            messages: messages,
            config: config
        )
    }

    private func formatResult(from answer: String, and citations: [Citation]) -> SearchResult {
        let sources = citations.map { citation in
            SearchResult.Source(
                title: citation.title ?? "",
                thumbnailURL: URL(string: citation.image ?? ""),
                faviconURL: URL(string: citation.favicon ?? "")
            )
        }
        return SearchResult(resultText: answer, sources: sources)
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
