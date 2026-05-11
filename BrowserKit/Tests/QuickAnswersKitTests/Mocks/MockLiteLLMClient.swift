// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import LLMKit

// TODO: FXIOS-15199 Move to LLMKitTests package

/// Mock implementation of LiteLLMClient for testing.
final class MockLiteLLMClient: LiteLLMClientProtocol, @unchecked Sendable {
    var respondWith: [String] = [""]
    var respondWithCitations: [Citation]?
    var respondWithError: Error?
    var requestChatCompletionCallCount = 0
    var requestChatCompletionStreamedCallCount = 0
    var lastMessages: [Any] = []
    var lastConfig: LLMConfig?

    func requestChatCompletion<ProviderFields: Codable & Sendable>(
        messages: [LiteLLMMessage<ProviderFields>],
        config: LLMConfig
    ) async throws -> LiteLLMMessage<ProviderFields> {
        requestChatCompletionCallCount += 1
        lastMessages = messages
        lastConfig = config

        if let error = respondWithError { throw error }

        let content = respondWith.joined(separator: " ")

        // For QuickAnswersProviderFields, include citations
        if ProviderFields.self == QuickAnswersProviderFields.self {
            let providerFields = respondWithCitations.map { QuickAnswersProviderFields(citations: $0) } as? ProviderFields
            return LiteLLMMessage(role: .assistant, content: content, providerSpecificFields: providerFields)
        } else {
            return LiteLLMMessage(role: .assistant, content: content, providerSpecificFields: nil)
        }
    }

    func requestChatCompletionStreamed<ProviderFields: Codable & Sendable>(
        messages: [LiteLLMMessage<ProviderFields>],
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
