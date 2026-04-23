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
        guard let stream = try await requestChatCompletion(for: message) else {
            // TODO: FXIOS-15196 - Remove error once LLMCLient is not nil
            throw SpeechError.unknown
        }

        var fullResponse = ""
        for try await chunk in stream {
            fullResponse += chunk
        }

        return try formatResult(from: fullResponse)
    }

    private func requestChatCompletion(for message: LiteLLMMessage) async throws -> AsyncThrowingStream<String, Error>? {
        // TODO: FXIOS-15198 Handle errors appropriately
        return try await client.requestChatCompletionStreamed(
            messages: [message],
            config: config
        )
    }

    private func formatResult(from response: String) throws -> SearchResult {
        // TODO: FXIOS-15197 - Implement parsing logic based on response format and update Search Result
        // depending on UI to be a stream instead. For now, return the full response as the body.
        return SearchResult(title: "Quick Answer", body: response, url: nil)
    }
}
