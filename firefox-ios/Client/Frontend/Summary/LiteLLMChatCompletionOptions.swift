// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Configuration options for chat completions, handling both request setup.
///
/// This struct centralizes a few key functions:
/// - Provides sensible defaults for the options
/// - Controls streaming vs. regular responses
/// - Can be extended to control other options (e.g., temperature, tools)
///
/// Note:
/// - Use `fakeLiteLLMModel` ("fake-openai-endpoint-5") when testing against LiteLLM's mock endpoint
/// - Streaming is disabled by default
public struct LiteLLMChatOptions {
    /// The model identifier string used when testing locally with LiteLLM's dummy endpoint
    public static let fakeLiteLLMModel = "fake-openai-endpoint-5"

    public var model: String
    public var maxTokens: Int
    public var stream: Bool

    public init(model: String, maxTokens: Int, stream: Bool = false) {
        self.model = model
        self.maxTokens = maxTokens
        self.stream = stream
    }
}
