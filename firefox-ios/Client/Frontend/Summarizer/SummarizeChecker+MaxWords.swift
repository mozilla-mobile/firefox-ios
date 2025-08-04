// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import SummarizeKit

extension SummarizationChecker {
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
