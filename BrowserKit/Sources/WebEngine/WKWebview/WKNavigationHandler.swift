// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

protocol WKNavigationHandler: WKNavigationDelegate {
    var session: SessionHandler? { get set }
    var telemetryProxy: EngineTelemetryProxy? { get set }

    func webView(_ webView: WKWebView,
                 didCommit navigation: WKNavigation?)

    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation?)

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation?,
                 withError error: Error)

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation?,
                 withError error: Error)

    func webView(_ webView: WKWebView,
                 didStartProvisionalNavigation navigation: WKNavigation?)

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void
    )

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    )

    func webView(_ webView: WKWebView,
                 didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation?)

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @MainActor (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )
}

class DefaultNavigationHandler: NSObject, WKNavigationHandler {
    weak var session: SessionHandler?
    weak var telemetryProxy: EngineTelemetryProxy?

    func webView(_ webView: WKWebView,
                 didCommit navigation: WKNavigation?) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
        telemetryProxy?.handleTelemetry(event: .pageLoadStarted)

        // TODO: Revisit possible duplicate delegate callbacks when navigating to URL in same origin [PR #19083] [FXIOS-8351]
        session?.commitURLChange()
    }

    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation?) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate

        if let url = webView.url {
            session?.fetchMetadata(withURL: url)
        }
        telemetryProxy?.handleTelemetry(event: .pageLoadFinished)
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation?,
                 withError error: Error) {
        telemetryProxy?.handleTelemetry(event: .didFailNavigation)
        telemetryProxy?.handleTelemetry(event: .pageLoadCancelled)
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation?,
                 withError error: Error) {
        telemetryProxy?.handleTelemetry(event: .didFailProvisionalNavigation)
        telemetryProxy?.handleTelemetry(event: .pageLoadCancelled)
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
    }

    func webView(_ webView: WKWebView,
                 didStartProvisionalNavigation navigation: WKNavigation?) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void
    ) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
        decisionHandler(.allow, preferences)
    }

    func webView(_ webView: WKWebView,
                 didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation?) {
        // TODO: FXIOS-8275 - Handle didReceiveServerRedirectForProvisionalNavigation (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @MainActor (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // TODO: FXIOS-8276 - Handle didReceive challenge: URLAuthenticationChallenge (epic part 3)
        completionHandler(.performDefaultHandling, nil)
    }
}
