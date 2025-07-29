// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A wrapper around `LiteLLMClient` that provides summarized output (full or streamed)
/// and normalizes underlying errors to `SummarizeError` type.
public final class LiteLLMSummarizer: SummarizerProtocol {
    private let client: LiteLLMClientProtocol
    private let model: String
    private let maxTokens: Int

    public init(
        client: LiteLLMClientProtocol,
        model: String,
        maxTokens: Int
    ) {
        self.client = client
        self.model = model
        self.maxTokens = maxTokens
    }

    /// Generates a full summary of the given text using the provided prompt.
    /// - Parameters:
    ///   - prompt: Instruction prompt to guide the summarization.
    ///   - text: The text to be summarized.
    /// - Returns: A summarized string.
    public func summarize(prompt: String, text: String) async throws -> String {
        let options = LiteLLMChatOptions(model: model, maxTokens: maxTokens, stream: false)
        // System message is used for the prompt, user message for the text.
        let messages = [
            LiteLLMMessage(role: .system, content: prompt),
            LiteLLMMessage(role: .user, content: text)
        ]
        return try await client.requestChatCompletion(messages: messages, options: options)
    }

    /// Streams a summary of the given text chunk-by-chunk using the provided prompt.
    /// - Parameters:
    ///   - prompt: Instruction prompt to guide the summarization.
    ///   - text: The text to be summarized.
    /// - Returns: An `AsyncThrowingStream` yielding chunks of the summary.
    public func summarizeStreamed(
        prompt: String,
        text: String
    ) -> AsyncThrowingStream<String, Error> {
        let options = LiteLLMChatOptions(model: model, maxTokens: maxTokens, stream: true)
        let messages = [
            LiteLLMMessage(role: .system, content: prompt),
            LiteLLMMessage(role: .user, content: text)
        ]
        return client.requestChatCompletionStreamed(messages: messages, options: options)
    }
}
