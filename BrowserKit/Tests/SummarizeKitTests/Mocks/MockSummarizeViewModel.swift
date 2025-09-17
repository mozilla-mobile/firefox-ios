// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import SummarizeKit

class MockSummarizeViewModel: SummarizeViewModel {
    var summarizeCalled = 0
    var injectedSummarizeResult: Result<String, SummarizeKit.SummarizerError>?
    var unblockSummarizationCalled = 0
    var closeSummariationCalled = 0
    var setTosScreenShownCalled = 0
    var setTosConsentAcceptedCalled = 0
    var logTosStatusCalled = 0

    func summarize(
        webView: WKWebView,
        footNoteLabel: String,
        dateProvider: DateProvider,
        onNewData: @escaping (Result<String, SummarizeKit.SummarizerError>) -> Void
    ) {
        summarizeCalled += 1
        guard let injectedSummarizeResult else { return }
        onNewData(injectedSummarizeResult)
    }

    func unblockSummarization() {
        unblockSummarizationCalled += 1
    }

    func closeSummarization() {
        closeSummariationCalled += 1
    }

    func setConsentScreenShown() {
        setTosScreenShownCalled += 1
    }

    func setConsentAccepted() {
        setTosConsentAcceptedCalled += 1
    }

    func logConsentStatus() {
        logTosStatusCalled += 1
    }
}
