// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SummarizeKit
import WebKit

class MockSummarizationChecker: SummarizationCheckerProtocol {
    static let success = SummarizationCheckResult(
        canSummarize: true,
        reason: nil,
        wordCount: 0,
        textContent: ""
    )
    static let failure = SummarizationCheckResult(
        canSummarize: false,
        reason: .contentTooLong,
        wordCount: 0,
        textContent: ""
    )

    var overrideResponse: SummarizationCheckResult?

    func check(on webView: WKWebView, maxWords: Int) async -> SummarizationCheckResult {
        return overrideResponse ?? Self.success
    }
}
