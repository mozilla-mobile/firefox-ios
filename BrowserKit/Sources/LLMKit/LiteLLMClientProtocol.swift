// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The result of a non-streaming chat completion request, containing the response content and any references.
public struct LiteLLMCompletionResult: Sendable {
    public let content: String
    public let references: [LiteLLMReference]

    public init(content: String, references: [LiteLLMReference]) {
        self.content = content
        self.references = references
    }
}

/// Interface for a litellm client for both streamed and non-streamed responses.
/// This used because we want to be able to replace the real `LiteLLMClient` with a mock during testing.
public protocol LiteLLMClientProtocol: Sendable {
    /// Sends a non-streaming chat completion request.
    func requestChatCompletion(
        messages: [LiteLLMMessage],
        config: LLMConfig,
    ) async throws -> LiteLLMCompletionResult

    /// Sends a streaming chat completion request.
    func requestChatCompletionStreamed(
        messages: [LiteLLMMessage],
        config: LLMConfig
    ) async throws -> AsyncThrowingStream<LiteLLMStreamResponse, Error>
}
