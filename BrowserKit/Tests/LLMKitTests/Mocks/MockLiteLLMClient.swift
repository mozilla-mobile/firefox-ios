// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import LLMKit

/// Mock implementation of a real  LiteLLMClient for testing the session and responses.
/// This allows injecting controlled outputs or errors without calling the real inference backend.
public final class MockLiteLLMClient: LiteLLMClientProtocol, @unchecked Sendable {
    var respondWith: [String] = [""]
    var respondWithError: Error?
    var requestChatCompletionCallCount = 0
    var requestChatCompletionStreamedCallCount = 0
    var lastMessages: [LiteLLMMessage]?
    var lastConfig: LLMConfig?

    public func requestChatCompletion(
        messages: [LiteLLMMessage],
        config: LLMConfig
    ) async throws -> String {
        requestChatCompletionCallCount += 1
        lastMessages = messages
        lastConfig = config

        if let error = respondWithError { throw error }
        return respondWith.joined(separator: " ")
    }

    public func requestChatCompletionStreamed(
        messages: [LiteLLMMessage],
        config: LLMConfig
    ) -> AsyncThrowingStream<String, Error> {
        requestChatCompletionStreamedCallCount += 1
        lastMessages = messages
        lastConfig = config

        return AsyncThrowingStream<String, Error> { continuation in
            if let error = respondWithError {
                continuation.finish(throwing: error)
            } else {
                for chunk in respondWith { continuation.yield(chunk) }
                continuation.finish()
            }
        }
    }
}
