// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import WebEngine

class BrowserWebUIDelegate: NSObject, WKUIDelegate {
    weak var bvc: BrowserViewController?
    private let policyDecider = WKPolicyDeciderFactory()

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
                popupTab.url = URL(string: "about:blank")
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

    func webViewDidClose(_ webView: WKWebView) {
        bvc?.webViewDidClose(webView)
    }
}
