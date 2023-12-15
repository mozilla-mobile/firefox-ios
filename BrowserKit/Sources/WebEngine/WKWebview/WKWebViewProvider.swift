// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

protocol WKWebViewProvider {
    func createWebview(configuration: WKWebViewConfiguration) -> WKEngineWebView
}

struct DefaultWKWebViewProvider: WKWebViewProvider {
    func createWebview(configuration: WKWebViewConfiguration) -> WKEngineWebView {
        configuration.userContentController = WKUserContentController()
        configuration.allowsInlineMediaPlayback = true
        let webView = DefaultWKEngineWebView(frame: .zero,
                                             configuration: configuration)

        // TODO: FXIOS-7898 #17643 Handle WebView a11y label
        //        webView.accessibilityLabel = .WebViewAccessibilityLabel
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true

        // Allow Safari Web Inspector (requires toggle in Settings > Safari > Advanced).
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // Night mode enables this by toggling WKWebView.isOpaque, otherwise this has no effect.
        webView.backgroundColor = .black

        // Turning off masking allows the web content to flow outside of the scrollView's frame
        // which allows the content appear beneath the toolbars in the BrowserViewController
        webView.scrollView.layer.masksToBounds = false

        return webView
    }
}
