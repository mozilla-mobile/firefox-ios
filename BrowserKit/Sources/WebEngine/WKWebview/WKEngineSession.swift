// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

class WKEngineSession: NSObject, EngineSession, WKUIDelegate {
    weak var delegate: EngineSessionDelegate?
    private(set) var webView: WKEngineWebView
    private var logger: Logger
    private var sessionData: WKEngineSessionData
    private var contentScriptManager: WKContentScriptManager

    init?(userScriptManager: WKUserScriptManager,
          configurationProvider: WKEngineConfigurationProvider = DefaultWKEngineConfigurationProvider(),
          webViewProvider: WKWebViewProvider = DefaultWKWebViewProvider(),
          logger: Logger = DefaultLogger.shared,
          sessionData: WKEngineSessionData = WKEngineSessionData(),
          contentScriptManager: WKContentScriptManager = DefaultContentScriptManager()) {
        guard let webView = webViewProvider.createWebview(configurationProvider: configurationProvider) else {
            logger.log("WKEngineWebView creation failed on configuration",
                       level: .fatal,
                       category: .webview)
            return nil
        }

        self.webView = webView
        self.logger = logger
        self.sessionData = sessionData
        self.contentScriptManager = contentScriptManager
        super.init()

        self.setupObservers()

        webView.uiDelegate = self
        userScriptManager.injectUserScriptsIntoWebView(webView)

        // TODO: FXIOS-7901 #17646 Handle WKEngineSession tabDelegate
//        tabDelegate?.tab(self, didCreateWebView: webView)
    }

    // TODO: FXIOS-7903 #17648 no return from this load(url:), we need a way to recordNavigationInTab
    func load(url: String) {
        // TODO: FXIOS-7981 Check scheme before loading

        // Convert about:reader?url=http://example.com URLs to local ReaderMode URLs
        if let url = URL(string: url),
           let syncedReaderModeURL = url.decodeReaderModeURL,
           let localReaderModeURL = syncedReaderModeURL
            .encodeReaderModeURL(WKEngineWebServer.shared.baseReaderModeURL()) {
            let readerModeRequest = URLRequest(url: localReaderModeURL)
            sessionData.lastRequest = readerModeRequest
            sessionData.url = url

            webView.load(readerModeRequest)
            logger.log("Loaded reader mode request", level: .debug, category: .webview)
            return
        }

        guard let url = URL(string: url) else { return }
        let request = URLRequest(url: url)

        sessionData.lastRequest = request
        sessionData.url = url

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
        if let url = sessionData.url,
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

    func goToHistory(index: Int) {
        // TODO: FXIOS-7907 #17651 Handle goToHistoryIndex in WKEngineSession (equivalent to goToBackForwardListItem)
    }

    func restore(state: Data) {
        if let lastRequest = sessionData.lastRequest {
            webView.load(lastRequest)
        }

        webView.interactionState = state
    }

    func close() {
        contentScriptManager.uninstall(session: self)
        webView.removeAllUserScripts()
        removeObservers()

        // TODO: FXIOS-7901 #17646 Handle WKEngineSession tabDelegate
//        tabDelegate?.tab(self, willDeleteWebView: webView)

        webView.navigationDelegate = nil
        webView.uiDelegate = nil

        webView.removeFromSuperview()
    }

    // MARK: Observe values

    private func setupObservers() {
        WKEngineKVOConstants.allCases.forEach {
            webView.addObserver(
                self,
                forKeyPath: $0.rawValue,
                options: .new,
                context: nil
            )
        }
    }

    private func removeObservers() {
        WKEngineKVOConstants.allCases.forEach {
            webView.removeObserver(self, forKeyPath: $0.rawValue)
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let keyPath, let path = WKEngineKVOConstants(rawValue: keyPath) else {
            logger.log("Unhandled KVO key: \(keyPath ?? "nil")", level: .debug, category: .webview)
            return
        }

        // Will be used as needed when we start using the engine session
        switch path {
        case .canGoBack:
            delegate?.onNavigationStateChange(canGoBack: webView.canGoBack,
                                              canGoForward: webView.canGoForward)
        case .canGoForward:
            delegate?.onNavigationStateChange(canGoBack: webView.canGoBack,
                                              canGoForward: webView.canGoForward)
        case .contentSize:
            break
        case .estimatedProgress:
            delegate?.onProgress(progress: webView.estimatedProgress)
        case .loading:
            guard let loading = change?[.newKey] as? Bool else { break }
            delegate?.onLoadingStateChange(loading: loading)
        case .title:
            break
        case .URL:
            break
        }
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // FXIOS-8243 - Handle popup windows with createWebViewWith in WebEngine (epic part 2)
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        // FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        // FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        // FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webViewDidClose(_ webView: WKWebView) {
        // FXIOS-8245 - Handle webViewDidClose in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
    ) {
        // FXIOS-8246 - Handle context menu in WebEngine (epic part 3)
    }

    @available(iOS 15, *)
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // FXIOS-8247 - Handle media capture in WebEngine (epic part 3)
    }
}
