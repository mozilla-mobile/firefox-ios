// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import GCDWebServers
import WebKit

class WKEngineSession: EngineSession {
    weak var delegate: EngineSessionDelegate?
    private var webView: TabWebView
    private let configuration: WKWebViewConfiguration

    init(configuration: WKWebViewConfiguration) {
        configuration.userContentController = WKUserContentController()
        configuration.allowsInlineMediaPlayback = true
        let webView = TabWebView(frame: .zero,
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

        self.webView = webView
        self.configuration = configuration

        // TODO: FXIOS-7899 #17644 Handle WKEngineSession observers
//        self.webView.addObserver(self, forKeyPath: KVOConstants.URL.rawValue, options: .new, context: nil)
//        self.webView.addObserver(self, forKeyPath: KVOConstants.title.rawValue, options: .new, context: nil)

        // TODO: FXIOS-7900 #17645 Handle WKEngineSession scripts
//        UserScriptManager.shared.injectUserScriptsIntoWebView(webView, nightMode: nightMode, noImageMode: noImageMode)

        // TODO: FXIOS-7901 #17646 Handle WKEngineSession tabDelegate
//        tabDelegate?.tab(self, didCreateWebView: webView)
    }

    // TODO: FXIOS-7903 #17648 no return from this loadURL, we need a way to recordNavigationInTab
    func loadUrl(url: String) {
        // Convert about:reader?url=http://example.com URLs to local ReaderMode URLs
        if let url = URL(string: url),
           let syncedReaderModeURL = url.decodeReaderModeURL,
           syncedReaderModeURL.encodeReaderModeURL(WKEngineWebServer.shared.baseReaderModeURL()) != nil {
            // TODO: FXIOS-7902 #17647 Handle webview request
//            let readerModeRequest = PrivilegedRequest(url: localReaderModeURL) as URLRequest
//            lastRequest = readerModeRequest
//            webView.load(readerModeRequest)
        }
        // TODO: FXIOS-7902 #17647 Handle webview request
//        lastRequest = request
//        if let url = request.url, url.isFileURL, request.isPrivileged {
//            webView.loadFileURL(url, allowingReadAccessTo: url)
//        }
//        webView.load(request)
    }

    func stopLoading() {
        webView.stopLoading()
    }

    func reload() {
        // TODO: FXIOS-7906 #17650 Handle reload in WKEngineSession
    }

    func goBack() {
        _ = webView.goBack()
    }

    func goForward() {
        _ = webView.goForward()
    }

    func goToHistoryIndex(index: Int) {
        // TODO: FXIOS-7907 #17651 Handle goToHistoryIndex in WKEngineSession (equivalent to goToBackForwardListItem)
    }

    func restoreState(state: Data) {
        // TODO: FXIOS-7908 #17652 Handle restoreState in WKEngineSession
    }

    func close() {
        // TODO: FXIOS-7900 #17645 Handle WKEngineSession scripts
//        contentScriptManager.uninstall(tab: self)
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeAllScriptMessageHandlers()

        // TODO: FXIOS-7899 #17644 Handle WKEngineSession observers
//        webView.removeObserver(self, forKeyPath: KVOConstants.URL.rawValue)
//        webView.removeObserver(self, forKeyPath: KVOConstants.title.rawValue)

        // TODO: FXIOS-7901 #17646 Handle WKEngineSession tabDelegate
//        tabDelegate?.tab(self, willDeleteWebView: webView)

        webView.navigationDelegate = nil
        webView.removeFromSuperview()
    }
}
