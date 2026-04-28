// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import LLMKit

// TODO: FXIOS-15199 Move to LLMKitTests package

/// Mock implementation of LiteLLMClient for testing.
final class MockLiteLLMClient: LiteLLMClientProtocol, @unchecked Sendable {
    var respondWith: [String] = [""]
    var respondWithError: Error?
    var requestChatCompletionCallCount = 0
    var requestChatCompletionStreamedCallCount = 0
    var requestSearchCount = 0
    var lastMessages: [LiteLLMMessage]?
    var lastConfig: LLMConfig?

    func requestChatCompletion(
        messages: [LiteLLMMessage],
        config: LLMConfig
    ) async throws -> String {
        requestChatCompletionCallCount += 1
        lastMessages = messages
        lastConfig = config

        if let error = respondWithError { throw error }
        return respondWith.joined(separator: " ")
    }

    func requestSearch(
        transcription: String,
        config: LLMConfig
    ) async throws -> SearchResponse {
        requestChatCompletionCallCount += 1
        lastConfig = config

        if let error = respondWithError { throw error }
        return SearchResponse(results: [])
    }

    func requestChatCompletionStreamed(
        messages: [LiteLLMMessage],
        config: LLMConfig
    ) -> AsyncThrowingStream<String, Error> {
        requestChatCompletionStreamedCallCount += 1
        lastMessages = messages
        lastConfig = config

        return AsyncThrowingStream<String, Error> { continuation in
            if let error = self.respondWithError {
                continuation.finish(throwing: error)
            } else {
                for chunk in self.respondWith {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
        }
    }
}
