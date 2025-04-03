// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit

protocol WKNavigationHandler: WKNavigationDelegate {
    var session: SessionHandler? { get set }
    var telemetryProxy: EngineTelemetryProxy? { get set }
    var readerModeNavigationDelegate: ReaderModeNavigationDelegate? { get set }

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
    weak var readerModeNavigationDelegate: ReaderModeNavigationDelegate?
    var logger: Logger = DefaultLogger.shared

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
        readerModeNavigationDelegate?.didFinish()
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation?,
                 withError error: Error) {
        logger.log("Error occurred during navigation.",
                   level: .warning,
                   category: .webview)

        telemetryProxy?.handleTelemetry(event: .didFailNavigation)
        telemetryProxy?.handleTelemetry(event: .pageLoadCancelled)
        readerModeNavigationDelegate?.didFailWithError(error: error)
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation?,
                 withError error: Error) {
        logger.log("Error occurred during the early navigation process.",
                   level: .warning,
                   category: .webview)

        telemetryProxy?.handleTelemetry(event: .didFailProvisionalNavigation)
        telemetryProxy?.handleTelemetry(event: .pageLoadCancelled)
        readerModeNavigationDelegate?.didFailWithError(error: error)

        // Ignore the "Frame load interrupted" error that is triggered when we cancel a request
        // to open an external application and hand it over to UIApplication.openURL(). The result
        // will be that we switch to the external app, for example the app store, while keeping the
        // original web page in the tab instead of replacing it with an error page.
        let error = error as NSError
        if error.domain == "WebKitErrorDomain" && error.code == 102 {
            return
        }

        guard !checkIfWebContentProcessHasCrashed(webView, error: error as NSError) else { return }

        if error.code == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue) {
            session?.commitURLChange()
            return
        }

        if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            session?.received(error: error, forURL: url)
        }
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

    // MARK: - Helper methods

    private func checkIfWebContentProcessHasCrashed(_ webView: WKWebView, error: NSError) -> Bool {
        if error.code == WKError.webContentProcessTerminated.rawValue && error.domain == "WebKitErrorDomain" {
            logger.log("WebContent process has crashed. Trying to reload to restart it.",
                       level: .warning,
                       category: .webview)
            webView.reload()
            return true
        }

        return false
    }
}
