// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import SummarizeKit

class DefaultSummarizationChecker: SummarizationCheckerProtocol {
    private let checker: SummarizationCheckerProtocol
    private let nimbusUtility: SummarizerNimbusUtils

    init(checker: SummarizationCheckerProtocol = SummarizationChecker(),
         nimbusUtility: SummarizerNimbusUtils = .shared) {
        self.checker = checker
        self.nimbusUtility = nimbusUtility
    }

    func check(on webView: WKWebView, maxWords: Int) async -> SummarizationCheckResult {
        guard nimbusUtility.isSummarizeFeatureEnabled else { return .failure(.invalidJSON) }
        return await checker.check(on: webView, maxWords: maxWords)
    }

    /// Query the max allowed words to summarize for the active experiment.
    static func maxWords(nimbusUtility: SummarizerNimbusUtils = .shared) -> Int {
        if nimbusUtility.isAppleSummarizerEnabled() {
            return FoundationModelsConfig.maxWords
        }
        if nimbusUtility.isHostedSummarizerEnabled() {
            return LiteLLMConfig.maxWords
        }
        return 0
    }
}
