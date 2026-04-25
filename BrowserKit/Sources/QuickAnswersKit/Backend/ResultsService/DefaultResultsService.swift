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
        let message = LiteLLMMessage(role: .user, content: transcription)
        // TODO: FXIOS-15198 - Handle mapping errors from request
        let fullResponse = try await requestChatCompletion(for: message)
        return try formatResult(from: fullResponse)
    }

    private func requestChatCompletion(for message: LiteLLMMessage) async throws -> String {
        // TODO: FXIOS-15198 Handle errors appropriately
        // and may need to change type and not use String,
        // but waiting for what we get on server side
        return try await client.requestChatCompletion(
            messages: [message],
            config: config
        )
    }

    private func formatResult(from response: String) throws -> SearchResult {
        // TODO: FXIOS-15197 - Implement parsing logic based on response format and update Search Result
        return SearchResult(
            resultText: response,
            sources: [SearchResult.Source(
                title: "",
                thumbnailURL: nil,
                faviconURL: nil
            )]
        )
    }
}
