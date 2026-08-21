// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

class MockLegacyResponder: NSObject, WKUIDelegate {
    var createWebViewCalled = 0
    var runJavaScriptAlertPanelCalled = 0
    var runJavaScriptConfirmPanelCalled = 0
    var runJavaScriptTextInputPanelCalled = 0
    var webViewDidCloseCalled = 0
    var contextMenuConfigurationCalled = 0
    var requestMediaCapturePermissionCalled = 0
    var contextMenuDidEndForElementCalled = 0

    // MARK: - WKUIDelegate

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        createWebViewCalled += 1
        return nil
    }

    // `async` is required to match the `WKUIDelegate` optional requirement. Without it this only
    // "nearly matches", so WebKit never dispatches to it and the mock silently stops recording calls.
    // swiftlint:disable async_without_await
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async {
        runJavaScriptAlertPanelCalled += 1
    }
    // swiftlint:enable async_without_await

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (Bool) -> Void
    ) {
        runJavaScriptConfirmPanelCalled += 1
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    ) {
        runJavaScriptTextInputPanelCalled += 1
    }

    func webViewDidClose(_ webView: WKWebView) {
        webViewDidCloseCalled += 1
    }

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping @MainActor (UIContextMenuConfiguration?) -> Void
    ) {
        contextMenuConfigurationCalled += 1
    }

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        requestMediaCapturePermissionCalled += 1
    }

    func webView(_ webView: WKWebView,
                 contextMenuDidEndForElement elementInfo: WKContextMenuElementInfo) {
        contextMenuDidEndForElementCalled += 1
    }
}
