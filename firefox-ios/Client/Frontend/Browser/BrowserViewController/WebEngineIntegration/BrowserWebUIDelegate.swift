// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import WebEngine

class BrowserWebUIDelegate: NSObject, WKUIDelegate {
    private(set) weak var bvc: BrowserViewController?
    private let policyDecider = WKPolicyDeciderFactory()

    func setLegacyDelegate(_ bvc: BrowserViewController) {
        self.bvc = bvc
    }

    // MARK: - WKUIDelegate

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let bvc, let parentTab = bvc.tabManager[webView] else { return nil }
        let policy = policyDecider.policyForPopupNavigation(action: navigationAction)
        switch policy {
        case .allow:
            let popupTab = bvc.tabManager.addPopupForParentTab(profile: bvc.profile,
                                                               parentTab: parentTab,
                                                               configuration: configuration)
            let url = navigationAction.request.url
            let urlString = url?.absoluteString ?? ""
            if url == nil || urlString.isEmpty {
                popupTab.url = URL(string: EngineConstants.aboutBlank)
            }
            return popupTab.webView
        case .launchExternalApp:
            guard let url = navigationAction.request.url, UIApplication.shared.canOpen(url: url) else { return nil }
            UIApplication.shared.open(url: url)
            return nil
        case .cancel:
            return nil
        }
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
