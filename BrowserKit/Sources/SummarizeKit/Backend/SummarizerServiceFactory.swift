// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import LLMKit
import MLPAKit

public protocol SummarizerServiceFactory {
    /// An object which responds to Summarize activities.
    var lifecycleDelegate: SummarizerServiceLifecycle? { get set }

    func make(isAppleSummarizerEnabled: Bool,
              isHostedSummarizerEnabled: Bool,
              isAppAttestAuthEnabled: Bool,
              usesPermissiveGuardrails: Bool,
              config: SummarizerConfig?) -> SummarizerService?

    /// Returns the max words that the summarizer Service can handle.
    func maxWords(isAppleSummarizerEnabled: Bool, isHostedSummarizerEnabled: Bool) -> Int
}

public struct DefaultSummarizerServiceFactory: SummarizerServiceFactory {
    public weak var lifecycleDelegate: SummarizerServiceLifecycle?

    public init() {}

    public func make(isAppleSummarizerEnabled: Bool,
                     isHostedSummarizerEnabled: Bool,
                     isAppAttestAuthEnabled: Bool,
                     usesPermissiveGuardrails: Bool = false,
                     config: SummarizerConfig?) -> SummarizerService? {
        let maxWords = maxWords(isAppleSummarizerEnabled: isAppleSummarizerEnabled,
                                isHostedSummarizerEnabled: isHostedSummarizerEnabled)
        let config = config ?? SummarizerConfig.defaultConfig
        #if canImport(FoundationModels)
        if isAppleSummarizerEnabled, #available(iOS 26, *) {
            let appleSummarizer = FoundationModelsSummarizer(
                usesPermissiveGuardrails: usesPermissiveGuardrails,
                config: config
            )
            return DefaultSummarizerService(
                summarizer: appleSummarizer,
                lifecycleDelegate: lifecycleDelegate,
                maxWords: maxWords
            )
        } else {
            guard isHostedSummarizerEnabled,
                  let llmClient = makeLiteLLMClient(config: config, isAppAttestAuthEnabled: isAppAttestAuthEnabled) else {
                return nil
            }

            let llmSummarizer = LiteLLMSummarizer(client: llmClient, config: config)
            return DefaultSummarizerService(
                summarizer: llmSummarizer,
                lifecycleDelegate: lifecycleDelegate,
                maxWords: maxWords
            )
        }
        #else
        guard isHostedSummarizerEnabled,
              let llmClient = makeLiteLLMClient(config: config, isAppAttestAuthEnabled: isAppAttestAuthEnabled) else {
            return nil
        }
        let llmSummarizer = LiteLLMSummarizer(client: llmClient, config: config)
        return DefaultSummarizerService(
            summarizer: llmSummarizer,
            lifecycleDelegate: lifecycleDelegate,
            maxWords: maxWords
        )
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

    // TODO: FXIOS-15146 - Add this to LLMKit and make creation more generic
    private func makeLiteLLMClient(
        config: SummarizerConfig,
        isAppAttestAuthEnabled: Bool
    ) -> LiteLLMClient? {
        guard let model = config.options["model"] as? String, !model.isEmpty else {
            return nil
        }

        if isAppAttestAuthEnabled {
            guard let endPoint = MLPAConstants.completionsEndpoint,
                  let client = try? AppAttestClient(remoteServer: MLPAAppAttestServer()) else {
                return nil
            }
            let authenticator = AppAttestRequestAuth(appAttestClient: client)
            return LiteLLMClient(authenticator: authenticator, baseURL: endPoint)
        } else {
            guard let endPoint = URL(string: LiteLLMConfig.apiEndpoint ?? ""),
                  let key = LiteLLMConfig.apiKey else {
                return nil
            }
            let authenticator = BearerRequestAuth(apiKey: key)
            return LiteLLMClient(authenticator: authenticator, baseURL: endPoint)
        }
    }
}
