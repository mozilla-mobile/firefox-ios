// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Interface for a litellm client for both streamed and non-streamed responses.
/// This used because we want to be able to replace the real `LiteLLMClient` with a mock during testing.
protocol LiteLLMClientProtocol: Sendable {
    /// Sends a non-streaming chat completion request.
    func requestChatCompletion(
        messages: [LiteLLMMessage],
        config: SummarizerConfig
    ) async throws -> String

    /// Sends a streaming chat completion request.
    func requestChatCompletionStreamed(
        messages: [LiteLLMMessage],
        config: SummarizerConfig
    ) async throws -> AsyncThrowingStream<String, Error>
}
