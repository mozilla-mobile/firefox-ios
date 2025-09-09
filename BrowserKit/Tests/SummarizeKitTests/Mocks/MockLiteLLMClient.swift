// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SummarizeKit

/// Mock implementation of a real  LiteLLMClient for testing the session and responses.
/// This allows injecting controlled outputs or errors without calling the real inference backend.
final class MockLiteLLMClient: LiteLLMClientProtocol, @unchecked Sendable {
    var respondWith: [String] = [""]
    var respondWithError: Error?

    func requestChatCompletion(
        messages: [LiteLLMMessage],
        config: SummarizerConfig
    ) async throws -> String {
        if let error = respondWithError { throw error }
        return respondWith.joined(separator: " ")
    }

    func requestChatCompletionStreamed(
        messages: [LiteLLMMessage],
        config: SummarizerConfig
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream<String, Error> { continuation in
            if let error = respondWithError {
                continuation.finish(throwing: error)
            } else {
                for chunk in respondWith { continuation.yield(chunk) }
                continuation.finish()
            }
        }
    }
}
