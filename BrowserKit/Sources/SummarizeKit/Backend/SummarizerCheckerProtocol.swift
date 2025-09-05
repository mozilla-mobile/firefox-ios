// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

public protocol SummarizationCheckerProtocol: Sendable {
    /// The maximum number of words allowed before rejecting summarization.
    /// Prevents model errors caused by exceeding token or context window limits.
    /// This is enforced by the injected JS, not the model itself.
    /// See UserScripts/MainFrame/AtDocumentStart/Summarizer.js for more context on how this is enforced.
    @MainActor
    func check(on webView: WKWebView, maxWords: Int) async -> SummarizationCheckResult
}
