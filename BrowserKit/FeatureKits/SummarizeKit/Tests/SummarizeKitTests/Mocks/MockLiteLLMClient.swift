// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import LLMKit

// TODO: FXIOS-15199 Move to LLMKitTests package

/// Mock implementation of a real  LiteLLMClient for testing the session and responses.
/// This allows injecting controlled outputs or errors without calling the real inference backend.
public final class MockLiteLLMClient: LiteLLMClientProtocol, @unchecked Sendable {
    var respondWith: [String] = [""]
    var respondWithError: Error?

    public func requestChatCompletion<ProviderFields: Codable & Sendable>(
        messages: [LiteLLMMessage<ProviderFields>],
        config: LLMConfig
    ) async throws -> LiteLLMMessage<ProviderFields> {
        if let error = respondWithError { throw error }
        let content = respondWith.joined(separator: " ")
        return LiteLLMMessage(role: .assistant, content: content, providerSpecificFields: nil)
    }

    public func requestChatCompletionStreamed<ProviderFields: Codable & Sendable>(
        messages: [LiteLLMMessage<ProviderFields>],
        config: LLMConfig
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
