// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

/// Abstraction that allow us to create a `WKWebView` object through
/// the usage of a configuration provider and an webview abstraction.
@MainActor
protocol WKWebViewProvider {
    func createWebview(configurationProvider: WKEngineConfigurationProvider,
                       parameters: WKWebViewParameters) -> WKEngineWebView?
}

struct DefaultWKWebViewProvider: WKWebViewProvider {
    private var logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    func createWebview(configurationProvider: WKEngineConfigurationProvider,
                       parameters: WKWebViewParameters) -> WKEngineWebView? {
        guard let webView = DefaultWKEngineWebView(frame: .zero,
                                                   configurationProvider: configurationProvider,
                                                   parameters: parameters) else {
            logger.log("WKEngineWebView creation failed on configuration",
                       level: .fatal,
                       category: .webview)
            return nil
        }

        // TODO: FXIOS-7898 #17643 Handle WebView a11y label and identifier
        //        webView.accessibilityLabel = .WebViewAccessibilityLabel
        //        webView.accessibilityIdentifier = "contentView"
        webView.accessibilityElementsHidden = false
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true

        if #available(iOS 16.0, *) {
            webView.isFindInteractionEnabled = true
        }

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
