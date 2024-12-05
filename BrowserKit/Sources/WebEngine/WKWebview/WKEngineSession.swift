// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
@preconcurrency import WebKit

class WKEngineSession: NSObject,
                       EngineSession,
                       WKUIDelegate,
                       WKNavigationDelegate,
                       WKEngineWebViewDelegate,
                       MetadataFetcherDelegate,
                       AdsTelemetryScriptDelegate {
    weak var delegate: EngineSessionDelegate?
    weak var findInPageDelegate: FindInPageHelperDelegate? {
        didSet {
            let script = contentScriptManager.scripts[FindInPageContentScript.name()]
            guard let findInPage = script as? FindInPageContentScript else { return }
            findInPage.delegate = findInPageDelegate
        }
    }

    private(set) var webView: WKEngineWebView
    var sessionData: WKEngineSessionData
    var telemetryProxy: EngineTelemetryProxy?

    private var logger: Logger
    private var contentScriptManager: WKContentScriptManager
    private var securityManager: SecurityManager
    private var metadataFetcher: MetadataFetcherHelper
    private var contentBlockingSettings: WKContentBlockingSettings = []

    init?(userScriptManager: WKUserScriptManager,
          telemetryProxy: EngineTelemetryProxy? = nil,
          configurationProvider: WKEngineConfigurationProvider = DefaultWKEngineConfigurationProvider(),
          webViewProvider: WKWebViewProvider = DefaultWKWebViewProvider(),
          logger: Logger = DefaultLogger.shared,
          sessionData: WKEngineSessionData = WKEngineSessionData(),
          contentScriptManager: WKContentScriptManager = DefaultContentScriptManager(),
          securityManager: SecurityManager = DefaultSecurityManager(),
          metadataFetcher: MetadataFetcherHelper = DefaultMetadataFetcherHelper()) {
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
        self.securityManager = securityManager
        self.metadataFetcher = metadataFetcher
        super.init()

        self.setupObservers()

        self.metadataFetcher.delegate = self
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.delegate = self
        userScriptManager.injectUserScriptsIntoWebView(webView)
        addContentScripts()
    }

    // TODO: FXIOS-7903 #17648 no return from this load(url:), we need a way to recordNavigationInTab
    func load(url: String) {
        let browsingContext = BrowsingContext(type: .internalNavigation, url: url)
        guard securityManager.canNavigateWith(browsingContext: browsingContext) == .allowed else { return }

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

    func scrollToTop() {
        webView.engineScrollView.setContentOffset(CGPoint.zero, animated: true)
    }

    func findInPage(text: String, function: FindInPageFunction) {
        let sanitizedInput = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        webView.evaluateJavascriptInDefaultContentWorld("__firefox__.\(function.rawValue)(\"\(sanitizedInput)\")")
    }

    func findInPageDone() {
        webView.evaluateJavascriptInDefaultContentWorld("__firefox__.findDone()")
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
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.delegate = nil
        webView.removeFromSuperview()

        metadataFetcher.delegate = nil
    }

    func disableTrackingProtection() {
        var settings = contentBlockingSettings
        settings.remove(.strict)
        settings.remove(.standard)
        contentBlockingSettings = settings
    }

    func switchToStandardTrackingProtection() {
        var settings = contentBlockingSettings
        settings.remove(.strict)
        settings.insert(.standard)
        contentBlockingSettings = settings
    }

    func switchToStrictTrackingProtection() {
        var settings = contentBlockingSettings
        settings.remove(.standard)
        settings.insert(.strict)
        contentBlockingSettings = settings
    }

    func toggleNoImageMode() {
        let settings = (contentBlockingSettings.rawValue ^ WKContentBlockingSettings.noImages.rawValue)
        contentBlockingSettings = WKContentBlockingSettings(rawValue: settings)
    }

    func updatePageZoom(_ change: ZoomChangeValue) {
        let zoomKey = "viewScale"
        let stepAmt = ZoomChangeValue.defaultStepIncrease
        let currentZoom = (webView.value(forKey: zoomKey) as? CGFloat) ?? 1.0
        let newZoom: CGFloat

        switch change {
        case .increase:
            newZoom = currentZoom + stepAmt
        case .decrease:
            newZoom = currentZoom - stepAmt
        case .reset:
            newZoom = 1.0
        case .set(let value):
            newZoom = value
        }
        webView.setValue(newZoom, forKey: zoomKey)
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
            // TODO: FXIOS-8086 - Handle view port in WebEngine
            break
        case .estimatedProgress:
            delegate?.onProgress(progress: webView.estimatedProgress)
        case .loading:
            guard let loading = change?[.newKey] as? Bool else { break }
            delegate?.onLoadingStateChange(loading: loading)
        case .title:
            guard let title = webView.title else { break }
            handleTitleChange(title: title)
        case .URL:
            handleURLChange()
        case .hasOnlySecureContent:
            handleHasOnlySecureContentChanged(webView.hasOnlySecureContent)
        }
    }

    private func handleHasOnlySecureContentChanged(_ value: Bool) {
        delegate?.onHasOnlySecureContentChanged(secure: value)
    }

    private func handleTitleChange(title: String) {
        // Ensure that the title actually changed to prevent repeated calls to onTitleChange
        if !title.isEmpty {
            sessionData.title = title
            delegate?.onTitleChange(title: title)
        }

        // TODO: FXIOS-8273 - Add telemetry integration in WebEngine and first telemetry call
        // TelemetryWrapper.recordEvent(category: .action, method: .navigate, object: .tab)
    }

    private func handleURLChange() {
        // Special case for "about:blank" popups, if the webView.url is nil, keep the sessionData url as "about:blank"
        if sessionData.url?.absoluteString == EngineConstants.aboutBlank
            && webView.url == nil { return }

        // To prevent spoofing, only change the URL immediately if the new URL is on
        // the same origin as the current URL. Otherwise, do nothing and wait for
        // didCommitNavigation to confirm the page load.
        guard sessionData.url?.origin == webView.url?.origin else { return }

        // Update session data, inform delegate, fetch metadata
        commitURLChange()
    }

    private func commitURLChange() {
        guard let url = webView.url else { return }

        sessionData.url = url
        delegate?.onLocationChange(url: url.absoluteString)

        metadataFetcher.fetch(fromSession: self, url: url)
    }

    // MARK: - Content scripts

    private func addContentScripts() {
        contentScriptManager.addContentScript(FindInPageContentScript(),
                                              name: FindInPageContentScript.name(),
                                              forSession: self)
        contentScriptManager.addContentScript(AdsTelemetryContentScript(delegate: self),
                                              name: AdsTelemetryContentScript.name(),
                                              forSession: self)
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // TODO: FXIOS-8243 - Handle popup windows with createWebViewWith in WebEngine (epic part 2)
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        // TODO: FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        // TODO: FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        // TODO: FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webViewDidClose(_ webView: WKWebView) {
        // TODO: FXIOS-8245 - Handle webViewDidClose in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
    ) {
        completionHandler(delegate?.onProvideContextualMenu(linkURL: elementInfo.linkURL))
    }

    @available(iOS 15, *)
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // TODO: FXIOS-8247 - Handle media capture in WebEngine (epic part 3)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 didCommit navigation: WKNavigation!) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
        telemetryProxy?.handleTelemetry(session: self, event: .pageLoadStarted)

        // TODO: Revisit possible duplicate delegate callbacks when navigating to URL in same origin [PR #19083] [FXIOS-8351]
        commitURLChange()
    }

    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate

        if let url = webView.url {
            metadataFetcher.fetch(fromSession: self, url: url)
        }
        telemetryProxy?.handleTelemetry(session: self, event: .pageLoadFinished)
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        telemetryProxy?.handleTelemetry(session: self, event: .didFailNavigation)
        telemetryProxy?.handleTelemetry(session: self, event: .pageLoadCancelled)
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        telemetryProxy?.handleTelemetry(session: self, event: .didFailProvisionalNavigation)
        telemetryProxy?.handleTelemetry(session: self, event: .pageLoadCancelled)
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
    }

    func webView(_ webView: WKWebView,
                 didStartProvisionalNavigation navigation: WKNavigation!) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        // TODO: FXIOS-8277 - Determine navigation calls with EngineSessionDelegate
        decisionHandler(.allow, preferences)
    }

    func webView(_ webView: WKWebView,
                 didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // TODO: FXIOS-8275 - Handle didReceiveServerRedirectForProvisionalNavigation (epic part 3)
    }

    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // TODO: FXIOS-8276 - Handle didReceive challenge: URLAuthenticationChallenge (epic part 3)
        completionHandler(.performDefaultHandling, nil)
    }

    // MARK: - WKEngineWebViewDelegate

    func tabWebView(_ webView: WKEngineWebView, findInPageSelection: String) {
        delegate?.findInPage(with: findInPageSelection)
    }

    func tabWebView(_ webView: WKEngineWebView, searchSelection: String) {
        delegate?.search(with: searchSelection)
    }

    func tabWebViewInputAccessoryView(_ webView: WKEngineWebView) -> EngineInputAccessoryView {
        return delegate?.onWillDisplayAccessoryView() ?? .default
    }

    // MARK: - MetadataFetcherDelegate

    func didLoad(pageMetadata: EnginePageMetadata) {
        delegate?.didLoad(pageMetadata: pageMetadata)
    }

    // MARK: - AdsTelemetryScriptDelegate

    func trackAdsClickedOnPage(providerName: String) {
        telemetryProxy?.handleTelemetry(session: self, event: .trackAdsClickedOnPage(providerName: providerName))
    }

    func trackAdsFoundOnPage(providerName: String, urls: [String]) {
        telemetryProxy?.handleTelemetry(session: self, event: .trackAdsFoundOnPage(providerName: providerName, adUrls: urls))
    }

    func searchProviderModels() -> [EngineSearchProviderModel] {
        return delegate?.adsSearchProviderModels() ?? []
    }
}
