// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A default implementation of the SummarizerConfigSourceProtocol that provides hardcoded configurations.
/// This will mostly be used as a fallback when no other configuration is available.
public struct DefaultSummarizerConfigSource: SummarizerConfigSourceProtocol {
    public init() {}

    // FIXME: FXIOS-13417 We should strongly type options in the future so they can be any Sendable & Hashable
    private static nonisolated(unsafe) let appleBaseOptions: [String: AnyHashable] = [ "temperature": 0.1 ]
    private static nonisolated(unsafe) let liteLLMBaseOptions: [String: AnyHashable] = [
        "temperature": 0.1,
        "top_p": 0.01,
        "max_tokens": LiteLLMConfig.maxTokens,
        "model": LiteLLMConfig.apiModel,
        "stream": true
    ]

    public func load(_ summarizer: SummarizerModel, contentType: SummarizationContentType) -> SummarizerConfig? {
        switch (contentType, summarizer) {
        case (.generic, .appleSummarizer):
            return .init(instructions: SummarizerModelInstructions.appleInstructions, options: Self.appleBaseOptions)
        case (.recipe, .appleSummarizer):
            return .init(instructions: SummarizerModelInstructions.defaultRecipeInstructions, options: Self.appleBaseOptions)
        case (.generic, .liteLLMSummarizer):
            return .init(instructions: SummarizerModelInstructions.defaultInstructions, options: Self.liteLLMBaseOptions)
        case (.recipe, .liteLLMSummarizer):
            return .init(
                instructions: SummarizerModelInstructions.defaultRecipeInstructions,
                options: Self.liteLLMBaseOptions
            )
        }
    }
}
