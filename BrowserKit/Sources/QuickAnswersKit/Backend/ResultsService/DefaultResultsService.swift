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

/// A completed exchange with the model, replayed as context so a follow up question is answered in context.
struct ConversationTurn: Equatable {
    let question: String
    let answer: String
}

actor DefaultResultsService: ResultsService {
    private struct Constants {
        static let maxCitationsCount = 2
        /// How many past exchanges are carried over by the providers that answer the last message only.
        static let maxContextTurns = 2
        /// Past answers are trimmed so they don't drown the actual question in the query being searched.
        static let maxContextAnswerLength = 200
    }
    private let client: LiteLLMClientProtocol
    private let configFetcher: QuickAnswersConfigFetcher
    /// The exchanges already made in this session, oldest first.
    private var conversation: [ConversationTurn] = []

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
            conversation.append(ConversationTurn(question: transcription, answer: fullResponse.content))
            return formatResult(from: fullResponse.content, and: citations)
        } catch {
            throw mapError(error)
        }
    }

    private func makeMessages(for transcription: String, config: LLMConfig) -> [QuickAnswersMessage] {
        var messages: [QuickAnswersMessage] = []
//        if !config.instructions.isEmpty {
        //swiflint: disable next
            messages.append(LiteLLMMessage(role: .system, content: config.instructions.appending("Respond in markdown highlighting what is important.")))
//        }
        guard configFetcher.model.supportsAssistantRole else {
            // Exa answers the last message and searches the web with it, so the context has to travel
            // inside the question rather than as separate messages.
            return messages + [LiteLLMMessage(role: .user, content: contextualizedQuestion(transcription))]
        }
        for turn in conversation {
            messages.append(LiteLLMMessage(role: .user, content: turn.question))
            messages.append(LiteLLMMessage(role: .assistant, content: turn.answer))
        }
        messages.append(LiteLLMMessage(role: .user, content: transcription))
        return messages
    }

    /// The question with the last exchanges inlined, so a follow up like "and tomorrow?" still carries the
    /// terms needed to search for an answer.
    private func contextualizedQuestion(_ question: String) -> String {
        let context = conversation.suffix(Constants.maxContextTurns).map {
            "The user asked \"\($0.question)\" and was told \"\(trimmedAnswer($0.answer))\"."
        }
        guard !context.isEmpty else { return question }
        return (context + ["Considering that, answer: \(question)"]).joined(separator: " ")
    }

    private func trimmedAnswer(_ answer: String) -> String {
        guard answer.count > Constants.maxContextAnswerLength else { return answer }
        let prefix = answer.prefix(Constants.maxContextAnswerLength)
        return prefix.trimmingCharacters(in: .whitespacesAndNewlines) + "\u{2026}"
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
        case let e as LiteLLMClientError: return .unknown(e.telemetryDescription)
        default: return .unknown(error.telemetryDescription)
        }
    }
}
