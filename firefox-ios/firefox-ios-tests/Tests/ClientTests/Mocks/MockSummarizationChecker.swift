// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SummarizeKit
import WebKit

final class MockSummarizationChecker: SummarizationCheckerProtocol, @unchecked Sendable {
    var checkCalledCount = 0
    static let success = SummarizationCheckResult(
        canSummarize: true,
        reason: nil,
        wordCount: 0,
        textContent: "",
        contentType: .generic
    )
    static let failure = SummarizationCheckResult(
        canSummarize: false,
        reason: .contentTooLong,
        wordCount: 0,
        textContent: "",
        contentType: nil
    )

    var overrideResponse: SummarizationCheckResult?

    func check(on webView: WKWebView, maxWords: Int) async -> SummarizationCheckResult {
        checkCalledCount += 1
        return overrideResponse ?? Self.success
    }
}
