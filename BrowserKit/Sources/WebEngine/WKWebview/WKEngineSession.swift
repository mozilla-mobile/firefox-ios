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

protocol WKJavascriptInterface: AnyObject {
    /// Calls a javascript method.
    /// - Parameter method: The method signature to be called in javascript world.
    /// - Parameter scope: An optional string defining the scope in which the method should be called.
    func callJavascriptMethod(_ method: String, scope: String?)
}

class WKEngineSession: NSObject,
                       EngineSession,
                       WKEngineWebViewDelegate,
                       WKJavascriptInterface,
                       MetadataFetcherDelegate,
                       SessionHandler {
    weak var delegate: EngineSessionDelegate? {
        didSet {
            uiHandler.delegate = delegate
        }
    }
    weak var telemetryProxy: EngineTelemetryProxy?
    weak var fullscreenDelegate: FullscreenDelegate?

    private(set) var webView: WKEngineWebView
    var sessionData = WKEngineSessionData()

    private var scriptResponder: EngineSessionScriptResponder
    private var logger: Logger
    private var contentScriptManager: WKContentScriptManager
    private var metadataFetcher: MetadataFetcherHelper
    private var contentBlockingSettings: WKContentBlockingSettings = []
    let navigationHandler: WKNavigationHandler
    private let uiHandler: WKUIHandler
    public var isActive = false {
        didSet {
            self.uiHandler.isActive = self.isActive
        }
    }

    // TODO: With Swift 6 we can use default params in the init
    @MainActor
    public static func sessionFactory(
        userScriptManager: WKUserScriptManager,
        dependencies: EngineSessionDependencies,
        configurationProvider: WKEngineConfigurationProvider,
        readerModeDelegate: WKReaderModeDelegate? = nil
    ) -> WKEngineSession? {
        let webViewProvider = DefaultWKWebViewProvider()
        let logger = DefaultLogger.shared
        let contentScriptManager = DefaultContentScriptManager()
        let scriptResponder = EngineSessionScriptResponder()
        let metadataFetcher = DefaultMetadataFetcherHelper()
        let navigationHandler = DefaultNavigationHandler()
        let uiHandler = DefaultUIHandler(sessionDependencies: dependencies)

        return WKEngineSession(
            userScriptManager: userScriptManager,
            dependencies: dependencies,
            configurationProvider: configurationProvider,
            webViewProvider: webViewProvider,
            logger: logger,
            contentScriptManager: contentScriptManager,
            scriptResponder: scriptResponder,
            metadataFetcher: metadataFetcher,
            navigationHandler: navigationHandler,
            uiHandler: uiHandler,
            readerModeDelegate: readerModeDelegate
        )
    }

    @MainActor
    init?(userScriptManager: WKUserScriptManager,
          dependencies: EngineSessionDependencies,
          configurationProvider: WKEngineConfigurationProvider,
          webViewProvider: WKWebViewProvider,
          logger: Logger = DefaultLogger.shared,
          contentScriptManager: WKContentScriptManager,
          scriptResponder: EngineSessionScriptResponder,
          metadataFetcher: MetadataFetcherHelper,
          navigationHandler: DefaultNavigationHandler,
          uiHandler: WKUIHandler,
          readerModeDelegate: WKReaderModeDelegate?) {
        guard let webView = webViewProvider.createWebview(configurationProvider: configurationProvider,
                                                          parameters: dependencies.webviewParameters) else {
            logger.log("WKEngineWebView creation failed on configuration",
                       level: .fatal,
                       category: .webview)
            return nil
        }

        self.webView = webView
        self.logger = logger
        self.contentScriptManager = contentScriptManager
        self.metadataFetcher = metadataFetcher
        self.navigationHandler = navigationHandler
        self.uiHandler = uiHandler
        self.scriptResponder = scriptResponder
        self.telemetryProxy = dependencies.telemetryProxy
        super.init()

        self.metadataFetcher.delegate = self
        navigationHandler.session = self

        uiHandler.delegate = delegate
        uiHandler.isActive = isActive
        webView.uiDelegate = uiHandler
        webView.navigationDelegate = navigationHandler
        webView.delegate = self
        userScriptManager.injectUserScriptsIntoWebView(webView)
        addContentScripts(readerModeDelegate: readerModeDelegate)
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

    @available(iOS 16.0, *)
    func showFindInPage(withSearchText searchText: String?) {
        if let findInteraction = webView.findInteraction {
            logger.log("Will show find in page", level: .debug, category: .webview)
            findInteraction.searchText = searchText ?? ""
            findInteraction.presentFindNavigator(showingReplace: false)
        }
    }

    func goToHistory(item: EngineSessionBackForwardListItem) {
        guard let backForwardListItem = item as? WKBackForwardListItem else {
            logger.log("""
                        Going to an EngineSessionBackForwardListItem that is not of \
                        type WKBackForwardListItem in WKEngineSession is not permitted
                        """,
                        level: .debug,
                        category: .webview)
            return
        }
        webView.go(to: backForwardListItem)
    }

    func currentHistoryItem() -> (EngineSessionBackForwardListItem)? {
        return webView.currentBackForwardListItem()
    }

    func getBackListItems() -> [EngineSessionBackForwardListItem] {
        return webView.backList()
    }

    func getForwardListItems() -> [EngineSessionBackForwardListItem] {
        return webView.forwardList()
    }

    func restore(state: Data) {
        if let lastRequest = sessionData.lastRequest {
            webView.load(lastRequest)
        }

        webView.interactionState = state
    }

    func close() {
        contentScriptManager.uninstall(session: self)
        webView.close()
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

    func viewPrintFormatter() -> UIPrintFormatter {
        return webView.viewPrintFormatter()
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

    // MARK: - WKJavascriptInterface

    func callJavascriptMethod(_ method: String, scope: String?) {
        guard let scope else {
            webView.evaluateJavascriptInDefaultContentWorld(method)
            return
        }
        webView.evaluateJavaScript(method, in: nil, in: .world(name: scope), completionHandler: nil)
    }

    // MARK: - Content scripts

    private func addContentScripts(readerModeDelegate: WKReaderModeDelegate?) {
        scriptResponder.session = self
        let searchProviders = delegate?.adsSearchProviderModels() ?? []
        contentScriptManager.addContentScript(AdsTelemetryContentScript(delegate: scriptResponder,
                                                                        searchProviderModels: searchProviders),
                                              name: AdsTelemetryContentScript.name(),
                                              forSession: self)
        contentScriptManager.addContentScript(FocusContentScript(delegate: scriptResponder),
                                              name: FocusContentScript.name(),
                                              forSession: self)

        let readerMode = ReaderModeContentScript(session: self)
        readerMode.delegate = readerModeDelegate
        contentScriptManager.addContentScript(readerMode,
                                              name: ReaderModeContentScript.name(),
                                              forSession: self)

        contentScriptManager.addContentScriptToPage(
            PrintContentScript(webView: webView),
            name: PrintContentScript.name(),
            forSession: self
        )
    }

    func setReaderMode(style: ReaderModeStyle, namespace: ReaderModeInfo) {
        webView.evaluateJavascriptInDefaultContentWorld(
            "\(namespace.rawValue).setStyle(\(style.encode()))"
        ) { object, error in
            return
        }
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

    func webViewPropertyChanged(_ property: WKEngineWebViewProperty) {
        switch property {
        case .loading(let isLoading):
            delegate?.onLoadingStateChange(loading: isLoading)
        case .estimatedProgress(let progress):
            if let url = webView.url, !WKInternalURL.isValid(url: url) {
                delegate?.onProgress(progress: progress)
            } else {
                delegate?.onHideProgressBar()
            }
        case .URL:
            handleURLChange()
        case .title(let title):
            handleTitleChange(title: title)
        case .canGoBack(let canGoBack):
            delegate?.onNavigationStateChange(canGoBack: canGoBack, canGoForward: webView.canGoForward)
        case .canGoForward(let canGoForward):
            delegate?.onNavigationStateChange(canGoBack: webView.canGoBack, canGoForward: canGoForward)
        case .contentSize:
            // TODO: FXIOS-8086 - Handle view port in WebEngine
            break
        case .hasOnlySecureContent(let hasOnlySecureContent):
            handleHasOnlySecureContentChanged(hasOnlySecureContent)
        case .isFullScreen(let isFullScreen):
            handleFullscreen(isFullScreen: isFullScreen)
        }
    }

    func webViewNeedsReload() {
        reload()
    }

    // MARK: - WebView Properties Change

    private func handleHasOnlySecureContentChanged(_ value: Bool) {
        sessionData.hasOnlySecureContent = value
        delegate?.onHasOnlySecureContentChanged(secure: value)
    }

    private func handleTitleChange(title: String) {
        // Ensure that the title actually changed to prevent repeated calls to onTitleChange
        if !title.isEmpty, title != sessionData.title {
            sessionData.title = title
            delegate?.onTitleChange(title: title)
        }
    }

    private func handleURLChange() {
        // Special case for "about:blank" popups, if the webView.url is nil, keep the sessionData url as "about:blank"
        if sessionData.url?.absoluteString == EngineConstants.aboutBlank
            && webView.url == nil { return }

        // Ensure we do have a URL from that observer
        guard let url = webView.url else { return }

        // Security safety check (Bugzilla #1933079)
        if let internalURL = WKInternalURL(url), internalURL.isErrorPage, !internalURL.isAuthorized {
            webView.load(URLRequest(url: URL(string: EngineConstants.aboutBlank)!))
            return
        }

        // To prevent spoofing, only change the URL immediately if the new URL is on
        // the same origin as the current URL. Otherwise, do nothing and wait for
        // didCommitNavigation to confirm the page load.
        guard sessionData.url?.origin == webView.url?.origin else { return }

        // Update session data, inform delegate, fetch metadata
        commitURLChange()
    }

    func handleFullscreen(isFullScreen: Bool) {
        if isFullScreen {
            fullscreenDelegate?.enteringFullscreen()
        } else {
            fullscreenDelegate?.exitingFullscreen()
        }
    }

    // MARK: - MetadataFetcherDelegate

    func didLoad(pageMetadata: EnginePageMetadata) {
        delegate?.didLoad(pageMetadata: pageMetadata)
    }
}
