// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
@preconcurrency import WebKit

protocol SessionHandler: AnyObject {
    func commitURLChange()
    func fetchMetadata(withURL url: URL)
    func received(error: NSError, forURL url: URL)
}

class WKEngineSession: NSObject,
                       EngineSession,
                       WKEngineWebViewDelegate,
                       MetadataFetcherDelegate,
                       AdsTelemetryScriptDelegate,
                       SessionHandler {
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
    private var metadataFetcher: MetadataFetcherHelper
    private var contentBlockingSettings: WKContentBlockingSettings = []
    private let navigationHandler: WKNavigationHandler
    private let uiHandler: WKUIHandler

    init?(userScriptManager: WKUserScriptManager,
          telemetryProxy: EngineTelemetryProxy? = nil,
          configurationProvider: WKEngineConfigurationProvider = DefaultWKEngineConfigurationProvider(),
          webViewProvider: WKWebViewProvider = DefaultWKWebViewProvider(),
          logger: Logger = DefaultLogger.shared,
          sessionData: WKEngineSessionData = WKEngineSessionData(),
          contentScriptManager: WKContentScriptManager = DefaultContentScriptManager(),
          metadataFetcher: MetadataFetcherHelper = DefaultMetadataFetcherHelper(),
          navigationHandler: DefaultNavigationHandler = DefaultNavigationHandler(),
          uiHandler: WKUIHandler = DefaultUIHandler()) {
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
        self.metadataFetcher = metadataFetcher
        self.navigationHandler = navigationHandler
        self.uiHandler = uiHandler
        super.init()

        self.setupObservers()

        self.metadataFetcher.delegate = self
        navigationHandler.session = self
        uiHandler.delegate = delegate
        webView.uiDelegate = uiHandler
        webView.navigationDelegate = navigationHandler
        webView.delegate = self
        userScriptManager.injectUserScriptsIntoWebView(webView)
        addContentScripts()
    }

    // TODO: FXIOS-7903 #17648 no return from this load(url:), we need a way to recordNavigationInTab
    func load(browserURL: BrowserURL) {
        // Convert about:reader?url=http://example.com URLs to local ReaderMode URLs
        if let syncedReaderModeURL = browserURL.url.decodeReaderModeURL,
           let localReaderModeURL = syncedReaderModeURL
            .encodeReaderModeURL(WKEngineWebServer.shared.baseReaderModeURL()) {
            let readerModeRequest = URLRequest(url: localReaderModeURL)
            sessionData.lastRequest = readerModeRequest
            sessionData.url = browserURL.url

            webView.load(readerModeRequest)
            logger.log("Loaded reader mode request", level: .debug, category: .webview)
            return
        }

        let request = URLRequest(url: browserURL.url)
        sessionData.lastRequest = request
        sessionData.url = browserURL.url

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

    func reload(bypassCache: Bool = false) {
        // Manage internal URLs reload
        if let url = sessionData.url,
           let internalUrl = WKInternalURL(url) {
            // If the current page is an error page load the original URL
            if let page = internalUrl.originalURLFromErrorPage {
                let request = URLRequest(url: page, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                webView.load(request)
                logger.log("Reloaded webview as error page", level: .debug, category: .webview)
                return
            }

            // If the URL is a home page load as privileged
            if internalUrl.isAboutHomeURL {
                internalUrl.authorize()
                webView.load(URLRequest(url: internalUrl.url))
                logger.log("Reloaded the webview with homepage URL", level: .debug, category: .webview)
                return
            }
        }

        // Reload bypassing the cache
        if bypassCache, let url = sessionData.url {
            let reloadRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

            webView.load(reloadRequest)
            logger.log("Reloaded the webview ignoring cache", level: .debug, category: .webview)
            return
        }

        // Reloads the current webpage, and performs end-to-end revalidation of the content 
        // using cache-validating conditionals, if possible.
        if webView.reloadFromOrigin() != nil {
            logger.log("Reloaded webview from origin", level: .debug, category: .webview)
            return
        }

        if let lastRequest = sessionData.lastRequest, webView.load(lastRequest) != nil {
            logger.log("Restoring webView from lastRequest", level: .debug, category: .tabs)
        } else {
            logger.log("Could not reload webView", level: .fatal, category: .tabs)
        }
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
        webView.engineScrollView?.setContentOffset(CGPoint.zero, animated: true)
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

    // MARK: - SessionHandler

    func commitURLChange() {
        guard let url = webView.url else { return }

        sessionData.url = url
        delegate?.onLocationChange(url: url.absoluteString)

        metadataFetcher.fetch(fromSession: self, url: url)
    }

    func fetchMetadata(withURL url: URL) {
        metadataFetcher.fetch(fromSession: self, url: url)
    }

    func received(error: NSError, forURL url: URL) {
        telemetryProxy?.handleTelemetry(event: .showErrorPage(errorCode: error.code))
        delegate?.onErrorPageRequest(error: error)
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
        telemetryProxy?.handleTelemetry(event: .trackAdsClickedOnPage(providerName: providerName))
    }

    func trackAdsFoundOnPage(providerName: String, urls: [String]) {
        telemetryProxy?.handleTelemetry(event: .trackAdsFoundOnPage(providerName: providerName, adUrls: urls))
    }

    func searchProviderModels() -> [EngineSearchProviderModel] {
        return delegate?.adsSearchProviderModels() ?? []
    }
}
