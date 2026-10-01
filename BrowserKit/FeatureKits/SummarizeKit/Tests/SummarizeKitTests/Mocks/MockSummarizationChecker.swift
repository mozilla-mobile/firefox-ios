// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import SummarizeKit

final class MockSummarizationChecker: SummarizationCheckerProtocol, @unchecked Sendable {
    var canSummarize: Bool
    var reason: SummarizationReason?
    var wordCount: Int
    var textContent: String? = ""

    init(canSummarize: Bool, reason: SummarizationReason?, wordCount: Int, textContent: String?) {
        self.canSummarize = canSummarize
        self.reason = reason
        self.wordCount = wordCount
        self.textContent = textContent
    }

    func check(on webView: WKWebView, maxWords: Int) async -> SummarizationCheckResult {
        SummarizationCheckResult(
            canSummarize: canSummarize,
            reason: reason,
            wordCount: wordCount,
            textContent: textContent,
            contentType: .generic
        )
    }
}
