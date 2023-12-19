// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

class WKEngineSession: EngineSession {
    weak var delegate: EngineSessionDelegate?
    private var webView: WKEngineWebView
    private var logger: Logger

    init?(configurationProvider: WKEngineConfigurationProvider = DefaultWKEngineConfigurationProvider(),
          webViewProvider: WKWebViewProvider = DefaultWKWebViewProvider(),
          logger: Logger = DefaultLogger.shared) {
        guard let webView = webViewProvider.createWebview(configurationProvider: configurationProvider) else {
            logger.log("WKEngineWebView creation failed on configuration",
                       level: .fatal,
                       category: .webview)
            return nil
        }

        self.webView = webView
        self.logger = logger

        // TODO: FXIOS-7899 #17644 Handle WKEngineSession observers
//        self.webView.addObserver(self, forKeyPath: KVOConstants.URL.rawValue, options: .new, context: nil)
//        self.webView.addObserver(self, forKeyPath: KVOConstants.title.rawValue, options: .new, context: nil)

        // TODO: FXIOS-7900 #17645 Handle WKEngineSession scripts
//        UserScriptManager.shared.injectUserScriptsIntoWebView(webView, nightMode: nightMode, noImageMode: noImageMode)

        // TODO: FXIOS-7901 #17646 Handle WKEngineSession tabDelegate
//        tabDelegate?.tab(self, didCreateWebView: webView)
    }

    // TODO: FXIOS-7903 #17648 no return from this load(url:), we need a way to recordNavigationInTab
    func load(url: String) {
        // TODO: FXIOS-7981 Check scheme before loading

        // Convert about:reader?url=http://example.com URLs to local ReaderMode URLs
        if let url = URL(string: url),
           let syncedReaderModeURL = url.decodeReaderModeURL,
           let localReaderModeURL = syncedReaderModeURL.encodeReaderModeURL(WKEngineWebServer.shared.baseReaderModeURL()) {
            let readerModeRequest = URLRequest(url: localReaderModeURL)
            webView.load(readerModeRequest)
            logger.log("Loaded reader mode request", level: .debug, category: .webview)
            return
        }

        guard let url = URL(string: url) else { return }
        let request = URLRequest(url: url)

        if let url = request.url, url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            return
        }

        webView.load(request)
        logger.log("Loaded request", level: .debug, category: .webview)
    }

    func stopLoading() {
        webView.stopLoading()
        logger.log("Stop loading", level: .debug, category: .webview)
    }

    func reload() {
        // If the current page is an error page load the original URL
        if let url = webView.url,
            let internalUrl = WKInternalURL(url),
            let page = internalUrl.originalURLFromErrorPage {
            webView.replaceLocation(with: page)
            logger.log("Reloaded webview as error page", level: .debug, category: .webview)
            return
        }

        // Reloads the current webpage, and performs end-to-end revalidation of the content 
        // using cache-validating conditionals, if possible.
        webView.reloadFromOrigin()
        logger.log("Reloaded webview from origin", level: .debug, category: .webview)
    }

    func goBack() {
        _ = webView.goBack()
        logger.log("Go back", level: .debug, category: .webview)
    }

    func goForward() {
        _ = webView.goForward()
        logger.log("Go forward", level: .debug, category: .webview)
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
        webView.removeAllUserScripts()

        // TODO: FXIOS-7899 #17644 Handle WKEngineSession observers
//        webView.removeObserver(self, forKeyPath: KVOConstants.URL.rawValue)
//        webView.removeObserver(self, forKeyPath: KVOConstants.title.rawValue)

        // TODO: FXIOS-7901 #17646 Handle WKEngineSession tabDelegate
//        tabDelegate?.tab(self, willDeleteWebView: webView)

        webView.navigationDelegate = nil
        webView.removeFromSuperview()
    }
}
