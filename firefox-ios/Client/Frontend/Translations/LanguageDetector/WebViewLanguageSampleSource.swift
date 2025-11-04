// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

/// Adapter that evaluates the JS in a real WKWebView.
/// This avoids extending or subclassing WKWebView for testing.
final class WebViewLanguageSampleSource: LanguageSampleSource {
    private let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
    }

    @MainActor
    func getLanguageSample(scriptEvalExpression: String) async throws -> String? {
        try await webView.callAsyncJavaScript(
            scriptEvalExpression,
            contentWorld: .defaultClient
        ) as? String
    }
}
