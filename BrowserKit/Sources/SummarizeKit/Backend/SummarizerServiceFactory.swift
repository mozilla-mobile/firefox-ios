// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol SummarizerServiceFactory {
    func make(isAppleSummarizerEnabled: Bool, isHostedSummarizerEnabled: Bool) -> SummarizerService?
}

public struct DefaultSummarizerServiceFactory: SummarizerServiceFactory {
    public init() {}

    public func make(isAppleSummarizerEnabled: Bool, isHostedSummarizerEnabled: Bool) -> SummarizerService? {
        #if canImport(FoundationModels)
        if isAppleSummarizerEnabled, #available(iOS 26, *) {
            let applSummarizer = FoundationModelsSummarizer(modelInstructions: FoundationModelsConfig.instructions)
            return SummarizerService(summarizer: applSummarizer, maxWords: FoundationModelsConfig.maxWords)
        } else {
            guard let endPoint = URL(string: LiteLLMConfig.apiEndpoint ?? ""),
                  let model = LiteLLMConfig.apiModel,
                  let key = LiteLLMConfig.apiKey else { return nil }
            let llmClient = LiteLLMClient(apiKey: key, baseURL: endPoint)
            let llmSummarizer = LiteLLMSummarizer(
                client: llmClient,
                model: model,
                maxTokens: LiteLLMConfig.maxTokens,
                modelInstructions: LiteLLMConfig.instructions
            )
            return SummarizerService(summarizer: llmSummarizer, maxWords: LiteLLMConfig.maxWords)
        }
        #else
        guard isHostedSummarizerEnabled,
              let endPoint = URL(string: LiteLLMConfig.apiEndpoint ?? ""),
              let model = LiteLLMConfig.apiModel,
              let key = LiteLLMConfig.apiKey else { return nil }
        let llmClient = LiteLLMClient(apiKey: key, baseURL: endPoint)
        let llmSummarizer = LiteLLMSummarizer(
            client: llmClient,
            model: model,
            maxTokens: LiteLLMConfig.maxTokens,
            modelInstructions: LiteLLMConfig.instructions
        )
        return SummarizerService(summarizer: llmSummarizer, maxWords: LiteLLMConfig.maxWords)
        #endif
    }
}
