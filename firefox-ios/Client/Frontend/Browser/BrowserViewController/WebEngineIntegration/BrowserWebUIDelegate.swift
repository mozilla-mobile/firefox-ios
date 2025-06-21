// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import WebKit
import WebEngine

class BrowserWebUIDelegate: NSObject, WKUIDelegate {
    private weak var bvc: BrowserViewController?
    private let engineResponder: WKUIHandler

    /// Initializes the `BrowserWebUIDelegate` with a legacy and engine responder.
    /// - Parameters:
    ///  - engineResponder: The object which actually responds to `WKUIDelegate` methods
    ///  being forwarded from `BrowserWebUIDelegate`.
    ///  - legacyResponder: The responder used when `engineResponder` can't respond to a delegate call.
    init(engineResponder: WKUIHandler, legacyResponder: BrowserViewController) {
        self.bvc = legacyResponder
        self.engineResponder = engineResponder
    }

    // MARK: - WKUIDelegate

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        return engineResponder.webView(
            webView,
            createWebViewWith: configuration,
            for: navigationAction,
            windowFeatures: windowFeatures
        )
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        bvc?.webView(
            webView,
            runJavaScriptAlertPanelWithMessage: message,
            initiatedByFrame: frame,
            completionHandler: completionHandler
        )
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        bvc?.webView(
            webView,
            runJavaScriptConfirmPanelWithMessage: message,
            initiatedByFrame: frame,
            completionHandler: completionHandler
        )
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        bvc?.webView(
            webView,
            runJavaScriptTextInputPanelWithPrompt: prompt,
            defaultText: defaultText,
            initiatedByFrame: frame,
            completionHandler: completionHandler
        )
    }

    func webViewDidClose(_ webView: WKWebView) {
        bvc?.webViewDidClose(webView)
    }

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
    ) {
        bvc?.webView(
            webView,
            contextMenuConfigurationForElement: elementInfo,
            completionHandler: completionHandler
        )
    }

    func webView(_ webView: WKWebView, contextMenuDidEndForElement elementInfo: WKContextMenuElementInfo) {
        bvc?.webView(webView, contextMenuDidEndForElement: elementInfo)
    }

    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        bvc?.webView(
            webView,
            requestMediaCapturePermissionFor: origin,
            initiatedByFrame: frame,
            type: type,
            decisionHandler: decisionHandler
        )
    }
}
