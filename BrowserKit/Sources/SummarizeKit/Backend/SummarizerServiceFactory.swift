// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol SummarizerServiceFactory {
    func make(isAppleSummarizerEnabled: Bool,
              isHostedSummarizerEnabled: Bool,
              config: SummarizerConfig?) -> SummarizerService?

    /// Returns the max words that the summarizer Service can handle.
    func maxWords(isAppleSummarizerEnabled: Bool, isHostedSummarizerEnabled: Bool) -> Int
}

public struct DefaultSummarizerServiceFactory: SummarizerServiceFactory {
    public init() {}

    public func make(isAppleSummarizerEnabled: Bool,
                     isHostedSummarizerEnabled: Bool,
                     config: SummarizerConfig?) -> SummarizerService? {
        let maxWords = maxWords(isAppleSummarizerEnabled: isAppleSummarizerEnabled,
                                isHostedSummarizerEnabled: isHostedSummarizerEnabled)
        let config = config ?? SummarizerConfig.defaultConfig
        #if canImport(FoundationModels)
        if isAppleSummarizerEnabled, #available(iOS 26, *) {
            let applSummarizer = FoundationModelsSummarizer(config: config)
            return SummarizerService(summarizer: applSummarizer, maxWords: maxWords)
        } else {
            guard let endPoint = URL(string: LiteLLMConfig.apiEndpoint ?? ""),
                  let model = config.options["model"] as? String, !model.isEmpty,
                  let key = LiteLLMConfig.apiKey else { return nil }
            let llmClient = LiteLLMClient(apiKey: key, baseURL: endPoint)
            let llmSummarizer = LiteLLMSummarizer(client: llmClient, config: config)
            return SummarizerService(summarizer: llmSummarizer, maxWords: maxWords)
        }
        #else
        guard isHostedSummarizerEnabled,
              let endPoint = URL(string: LiteLLMConfig.apiEndpoint ?? ""),
              let model = config.options["model"] as? String, !model.isEmpty,
              let key = LiteLLMConfig.apiKey else { return nil }
        let llmClient = LiteLLMClient(apiKey: key, baseURL: endPoint)
        let llmSummarizer = LiteLLMSummarizer(client: llmClient, config: config)
        return SummarizerService(summarizer: llmSummarizer, maxWords: maxWords)
        #endif
    }

    public func maxWords(isAppleSummarizerEnabled: Bool, isHostedSummarizerEnabled: Bool) -> Int {
        if isAppleSummarizerEnabled {
            return FoundationModelsConfig.maxWords
        }
        if isHostedSummarizerEnabled {
            return LiteLLMConfig.maxWords
        }
        return 0
    }
}
