// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared
import SiteImageView
import WebKit
import WebEngine

private var debugTabCount = 0

func mostRecentTab(inTabs tabs: [Tab]) -> Tab? {
    guard var recent = tabs.first else {
        return nil
    }

    tabs.forEach { tab in
        if tab.lastExecutedTime > recent.lastExecutedTime {
            recent = tab
        }
    }

    return recent
}

protocol TabContentScript {
    static func name() -> String
    func scriptMessageHandlerNames() -> [String]?
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    )
    func prepareForDeinit()
}

extension TabContentScript {
    // By default most script don't need a `prepareForDeinit`
    func prepareForDeinit() {}
}

protocol LegacyTabDelegate: AnyObject {
    func tab(_ tab: Tab, didAddLoginAlert alert: SaveLoginAlert)
    func tab(_ tab: Tab, didRemoveLoginAlert alert: SaveLoginAlert)
    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String)
    func tab(_ tab: Tab, didSelectSearchWithFirefoxForSelection selection: String)
    func tab(_ tab: Tab, didCreateWebView webView: WKWebView)
    func tab(_ tab: Tab, willDeleteWebView webView: WKWebView)
}

struct TabState {
    var isPrivate = false
    var url: URL?
    var title: String?
}

enum TabUrlType: String {
    case regular
    case search
    case followOnSearch
    case organicSearch
    case googleTopSite
    case googleTopSiteFollowOn
}

typealias TabUUID = String

class Tab: NSObject, ThemeApplicable, FeatureFlaggable, ShareTab {
    static let privateModeKey = "PrivateModeKey"
    private var _isPrivate = false
    private(set) var isPrivate: Bool {
        get {
            return _isPrivate
        }
        set {
            if _isPrivate != newValue {
                _isPrivate = newValue
            }
        }
    }

    var isInactiveTabsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildAndUser)
    }

    var isNormal: Bool {
        return !isPrivate
    }

    var isNormalActive: Bool {
        return !isPrivate && (isInactiveTabsEnabled ? isActive : true)
    }

    var isNormalAndInactive: Bool {
        return !isPrivate && (isInactiveTabsEnabled ? isInactive : false)
    }

    /// The window associated with the tab (where the tab lives and will be displayed).
    /// Currently tabs cannot be actively moved between windows on iPadOS, however this
    /// may change in the future.
    let windowUUID: WindowUUID

    var urlType: TabUrlType = .regular
    var tabState: TabState {
        return TabState(isPrivate: _isPrivate, url: url, title: displayTitle)
    }

    var timerPerWebsite: [String: StopWatchTimer] = [:]

    // Tab Groups
    var metadataManager: LegacyTabMetadataManager?

    // PageMetadata is derived from the page content itself, and as such lags behind the
    // rest of the tab.
    var pageMetadata: PageMetadata? {
        didSet {
            faviconURL = pageMetadata?.faviconURL
        }
    }

    var readabilityResult: ReadabilityResult?

    var consecutiveCrashes: UInt = 0

    // Setting default page as topsites
    var newTabPageType: NewTabPage = .topSites
    var tabUUID: TabUUID = UUID().uuidString
    private var screenshotUUIDString: String?

    var screenshotUUID: UUID? {
        get {
            guard let uuidString = screenshotUUIDString else { return nil }
            return UUID(uuidString: uuidString)
        } set(value) {
            screenshotUUIDString = value?.uuidString ?? ""
        }
    }

    var adsTelemetryUrlList = [String]() {
        didSet {
            startingSearchUrlWithAds = url
        }
    }
    var adsTelemetryRedirectUrlList = [URL]()
    var startingSearchUrlWithAds: URL?
    var adsProviderName = ""
    var hasHomeScreenshot = false
    var shouldScrollToTop = false
    var isFindInPageMode = false

    private var logger: Logger

    // To check if current URL is the starting page i.e. either blank page or internal page like topsites
    var isURLStartingPage: Bool {
        guard url != nil else { return true }
        if url!.absoluteString.hasPrefix("internal://") {
            return true
        }
        return false
    }

    var canonicalURL: URL? {
        if isPDFRefactorEnabled, temporaryDocument?.isDownloading ?? false {
            return url
        }
        if let string = pageMetadata?.siteURL,
           let siteURL = URL(string: string, invalidCharacters: false) {
            // If the canonical URL from the page metadata doesn't contain the
            // "#" fragment, check if the tab's URL has a fragment and if so,
            // append it to the canonical URL.
            if siteURL.fragment == nil,
               let fragment = self.url?.fragment,
               let siteURLWithFragment = URL(string: "\(string)#\(fragment)", invalidCharacters: false) {
                return siteURLWithFragment
            }

            return siteURL
        }
        return url
    }

    var loading: Bool {
        return webView?.isLoading ?? false
    }

    var estimatedProgress: Double {
        return webView?.estimatedProgress ?? 0
    }

    private var backList: [WKBackForwardListItem]? {
        return webView?.backForwardList.backList
    }

    var historyList: [URL] {
        func listToUrl(_ item: WKBackForwardListItem) -> URL { return item.url }

        var historyUrls = self.backList?.map(listToUrl) ?? [URL]()
        if let url = url {
            historyUrls.append(url)
        }
        return historyUrls
    }

    var title: String? {
        if let title = webView?.title, !title.isEmpty {
            return webView?.title
        }

        return nil
    }

    /// This property returns, ideally, the web page's title. Otherwise, based on the page being internal
    /// or not, it will resort to other displayable titles.
    var displayTitle: String {
        if self.isFxHomeTab {
            return .LegacyAppMenu.AppMenuOpenHomePageTitleString
        }

        if let url, url.isFileURL {
            // return the file name
            return url.lastPathComponent
        }

        if let lastTitle = lastTitle, !lastTitle.isEmpty {
            return lastTitle
        }

        // First, check if the webView can give us a title.
        if let title = webView?.title, !title.isEmpty {
            return title
        }

        // Then, if it's not Home, and it's also not a complete and valid URL, display what was "entered" as the title.
        if let url = self.url, !InternalURL.isValid(url: url), let shownUrl = url.displayURL?.absoluteString {
            return shownUrl
        }

        // Finally, somehow lastTitle is persisted (and webView's title isn't).
        guard let lastTitle = lastTitle, !lastTitle.isEmpty else {
            // And if `lastTitle` fails, we'll take the URL itself (somewhat treated) as the last resort.
            return self.url?.displayURL?.baseDomain ??  ""
        }

        return lastTitle
    }

    /// Use the display title unless it's an empty string, then use the base domain from the url
    func getTabTrayTitle() -> String {
        let baseDomain = url?.baseDomain
        var backUpName = "" // In case display title is empty

        if let baseDomain = baseDomain {
            backUpName = baseDomain.contains("local") ? .LegacyAppMenu.AppMenuOpenHomePageTitleString : baseDomain
        } else if let url = url, let about = InternalURL(url)?.aboutComponent {
            backUpName = about
        }

        return displayTitle.isEmpty ? backUpName : displayTitle
    }

    var canGoBack: Bool {
        // FXIOS-9785 This could result in the back button never being enabled for restored tabs
        assert(webView != nil, "We should not be trying to enable or disable the back button before the webView is set")

        return webView?.canGoBack ?? false
    }

    var canGoForward: Bool {
        // FXIOS-9785 This could result in the forward button never being enabled for restored tabs
        assert(webView != nil, "We should not be trying to enable or disable the forward button before the webView is set")

        return webView?.canGoForward ?? false
    }

    var userActivity: NSUserActivity?
    var webView: TabWebView?
    weak var tabDelegate: LegacyTabDelegate?
    var loginAlert: SaveLoginAlert?
    var lastExecutedTime: Timestamp
    var firstCreatedTime: Timestamp
    private let faviconHelper: SiteImageHandler
    var faviconURL: String? {
        didSet {
            guard let url = url,
                  let faviconURLString = faviconURL,
                  let faviconUrl = URL(string: faviconURLString, invalidCharacters: false)
            else { return }
            faviconHelper.cacheFaviconURL(
                siteURL: url,
                faviconURL: faviconUrl
            )
        }
    }
    fileprivate var lastRequest: URLRequest?
    var pendingScreenshot = false
    var url: URL? {
        didSet {
            if isPDFRefactorEnabled, let _url = url, let sourceURL = downloadedTemporaryDocs[_url] {
                url = sourceURL
            }
            if let _url = url, let internalUrl = InternalURL(_url), internalUrl.isAuthorized {
                url = URL(string: internalUrl.stripAuthorization, invalidCharacters: false)
            }
        }
    }

    var lastKnownUrl: URL? {
        // Historically, there was a check for the tab session data beforehand here.
        // Since session data doesn't exist anymore since we use WKWebview interaction state
        // Tab.lastKnownUrl is in fact the Tab.url.
        return self.url
    }

    var isFxHomeTab: Bool {
        // Check if there is a url or last known url
        let url = url ?? lastKnownUrl
        guard let url = url else { return false }

        // Make sure the url is of type home page
        if url.absoluteString.hasPrefix("internal://"),
           let internalUrl = InternalURL(url),
           internalUrl.isAboutHomeURL {
            return true
        }
        // TODO: Find a new home for this FXIOS-8527
        // A computed variable should not be making view level changes
        ensureMainThread {
            self.setZoomLevelforDomain()
        }
        return false
    }

    var isCustomHomeTab: Bool {
        if let customHomeUrl = HomeButtonHomePageAccessors.getHomePage(profile.prefs),
           let customHomeBaseDomain = customHomeUrl.baseDomain,
           let url = url,
           let baseDomain = url.baseDomain,
           baseDomain.hasPrefix(customHomeBaseDomain) {
            return true
        }
        return false
    }

    var mimeType: String?
    var isEditing = false
    // When viewing a non-HTML content type in the webview (like a PDF document), this URL will
    // point to a tempfile containing the content so it can be shared to external applications.
    var temporaryDocument: TemporaryDocument?

    /// Used to retain a reference to an AR 3D model preview until display ends
    var quickLookPreviewHelper: OpenQLPreviewHelper?

    /// Returns true if this tab's URL is known, and it's longer than we want to store.
    var urlIsTooLong: Bool {
        guard let url = self.url else {
            return false
        }
        return url.absoluteString.lengthOfBytes(using: .utf8) > AppConstants.databaseURLLengthMax
    }

    // Use computed property so @available can be used to guard `noImageMode`.
    var noImageMode: Bool {
        didSet {
            guard noImageMode != oldValue else { return }

            contentBlocker?.noImageMode(enabled: noImageMode)

            UserScriptManager.shared.injectUserScriptsIntoWebView(
                webView,
                nightMode: nightMode,
                noImageMode: noImageMode
            )
        }
    }

    var nightMode: Bool {
        didSet {
            guard nightMode != oldValue else { return }
            webView?.isOpaque = !nightMode
            webView?.evaluateJavascriptInCustomContentWorld(
                NightModeHelper.jsCallbackBuilder(nightMode),
                in: .world(name: NightModeHelper.name())
            )
            UserScriptManager.shared.injectUserScriptsIntoWebView(
                webView,
                nightMode: nightMode,
                noImageMode: noImageMode
            )
        }
    }

    var contentBlocker: FirefoxTabContentBlocker?

    /// The last title shown by this tab. Used by the tab tray to show titles for zombie tabs.
    var lastTitle: String?

    /// Whether or not the desktop site was requested with the last request, reload or navigation.
    var changedUserAgent = false {
        didSet {
            if changedUserAgent != oldValue {
                TabEvent.post(.didToggleDesktopMode, for: self)
            }
        }
    }

    var readerModeAvailableOrActive: Bool {
        if mimeType == MIMEType.HTML,
           let readerMode = self.getContentScript(name: "ReaderMode") as? ReaderMode {
            return readerMode.state != .unavailable
        }
        return false
    }

    fileprivate(set) var pageZoom: CGFloat = 1.0 {
        didSet {
            webView?.setValue(pageZoom, forKey: "viewScale")
        }
    }

    fileprivate(set) var screenshot: UIImage?

    // If this tab has been opened from another, its parent will point to the tab from which it was opened
    weak var parent: Tab?

    private var contentScriptManager = TabContentScriptManager()

    private var configuration: WKWebViewConfiguration?

    /// Any time a tab tries to make requests to display a Javascript Alert and we are not the active
    /// tab instance, queue it for later until we become foregrounded.
    private var alertQueue = [JSAlertInfo]()

    var onLoading: VoidReturnCallback?
    private var webViewLoadingObserver: NSKeyValueObservation?
    /// The dictionary containing as key the location for a document and its corresponding source URL.
    private var downloadedTemporaryDocs = [URL: URL]()

    private var isPDFRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.pdfRefactor, checking: .buildOnly)
    }

    var profile: Profile

    /// Returns true if this tab is considered inactive (has not been executed for more than a specific number of days).
    /// Note: When `FasterInactiveTabsOverride` is enabled, tabs become inactive very quickly for testing purposes.
    var isInactive: Bool {
        let currentDate = Date()
        let inactiveDate: Date

        // Check if we're debugging for inactive tabs to easily test in code
        let rawValue = UserDefaults.standard.integer(forKey: PrefsKeys.FasterInactiveTabsOverride)
        let option = FasterInactiveTabsOption(rawValue: rawValue) ?? .normal
        switch option {
        case .normal:
            // Normal operation when no debug setting overrides the inactive tabs timeout
            inactiveDate = Calendar.current.date(byAdding: .day, value: -14, to: currentDate.noon) ?? Date()
        case .tenSeconds:
            inactiveDate = Calendar.current.date(byAdding: .second, value: -10, to: currentDate) ?? Date()
        case .oneMinute:
            inactiveDate = Calendar.current.date(byAdding: .minute, value: -1, to: currentDate) ?? Date()
        case .twoMinutes:
            inactiveDate = Calendar.current.date(byAdding: .minute, value: -2, to: currentDate) ?? Date()
        }

        // If the tabDate is older than our inactive date cutoff, return true
        let tabDate = Date.fromTimestamp(lastExecutedTime)
        return tabDate <= inactiveDate
    }

    /// Returns true if this tab is considered active (has been executed within a specific numbers of days).
    /// Note: When `FasterInactiveTabsOverride` is enabled, tabs become inactive very quickly for testing purposes.
    var isActive: Bool {
        return !isInactive
    }

    init(profile: Profile,
         isPrivate: Bool = false,
         windowUUID: WindowUUID,
         faviconHelper: SiteImageHandler = DefaultSiteImageHandler.factory(),
         tabCreatedTime: Date = Date(),
         logger: Logger = DefaultLogger.shared) {
        self.nightMode = false
        self.windowUUID = windowUUID
        self.noImageMode = false
        self.profile = profile
        self.metadataManager = LegacyTabMetadataManager(metadataObserver: profile.places)
        self.faviconHelper = faviconHelper
        self.lastExecutedTime = tabCreatedTime.toTimestamp()
        self.firstCreatedTime = tabCreatedTime.toTimestamp()
        self.logger = logger
        super.init()
        self.isPrivate = isPrivate

        debugTabCount += 1

        TelemetryWrapper.recordEvent(
            category: .action,
            method: .add,
            object: .tab,
            value: isPrivate ? .privateTab : .normalTab
        )
    }

    class func toRemoteTab(_ tab: Tab, inactive: Bool) -> RemoteTab? {
        if tab.isPrivate {
            return nil
        }

        let icon = (tab.faviconURL ?? tab.pageMetadata?.faviconURL).flatMap { URL(string: $0) }
        if let displayURL = tab.url?.displayURL, RemoteTab.shouldIncludeURL(displayURL) {
            let history = Array(tab.historyList.filter(RemoteTab.shouldIncludeURL).reversed())
            return RemoteTab(
                clientGUID: nil,
                URL: displayURL,
                title: tab.title ?? tab.displayTitle,
                history: history,
                lastUsed: tab.lastExecutedTime,
                icon: icon,
                inactive: inactive
            )
        }

        return nil
    }

    weak var navigationDelegate: WKNavigationDelegate? {
        didSet {
            if let webView = webView {
                webView.navigationDelegate = navigationDelegate
            }
        }
    }

    func createWebview(with restoreSessionData: Data? = nil, configuration: WKWebViewConfiguration) {
        self.configuration = configuration
        if webView == nil {
            configuration.userContentController = WKUserContentController()
            configuration.allowsInlineMediaPlayback = true
            let webView = TabWebView(frame: .zero, configuration: configuration, windowUUID: windowUUID)
            webView.configure(delegate: self, navigationDelegate: navigationDelegate)
            webView.accessibilityLabel = .WebViewAccessibilityLabel
            webView.allowsBackForwardNavigationGestures = true
            webView.allowsLinkPreview = true

            // Allow Safari Web Inspector (requires toggle in Settings > Safari > Advanced).
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }

            // Turning off masking allows the web content to flow outside of the scrollView's frame
            // which allows the content appear beneath the toolbars in the BrowserViewController
            webView.scrollView.layer.masksToBounds = false

            restore(webView, interactionState: restoreSessionData)

            self.webView = webView

            // FXIOS-5549
            // There is a crash in didCreateWebView for when webview becomes nil.
            // We are adding a check before that method gets called as the webview
            // should not be nil at this point considering we created it above.
            guard self.webView != nil else {
                logger.log("No webview found for didCreateWebView.",
                           level: .fatal,
                           category: .tabs)
                return
            }

            configureEdgeSwipeGestureRecognizers()
            self.webView?.addObserver(
                self,
                forKeyPath: KVOConstants.URL.rawValue,
                options: .new,
                context: nil
            )
            self.webView?.addObserver(
                self,
                forKeyPath: KVOConstants.title.rawValue,
                options: .new,
                context: nil
            )
            self.webView?.addObserver(
                self,
                forKeyPath: KVOConstants.hasOnlySecureContent.rawValue,
                options: .new,
                context: nil
            )
            UserScriptManager.shared.injectUserScriptsIntoWebView(
                webView,
                nightMode: nightMode,
                noImageMode: noImageMode
            )

            tabDelegate?.tab(self, didCreateWebView: webView)
            webViewLoadingObserver = webView.observe(\.isLoading) { [weak self] _, _ in
                self?.onLoading?()
            }
        }
    }

    func restore(_ webView: WKWebView, interactionState: Data? = nil) {
        if let url = url {
            if let internalURL = InternalURL(url),
               internalURL.isAboutHomeURL {
                webView.load(PrivilegedRequest(url: url) as URLRequest)
            } else {
                webView.load(URLRequest(url: url))
            }
        }

        if let interactionState = interactionState {
            webView.interactionState = interactionState
        }
    }

    deinit {
        deleteDownloadedDocuments()
        webViewLoadingObserver?.invalidate()
        webView?.removeObserver(self, forKeyPath: KVOConstants.URL.rawValue)
        webView?.removeObserver(self, forKeyPath: KVOConstants.title.rawValue)
        webView?.removeObserver(self, forKeyPath: KVOConstants.hasOnlySecureContent.rawValue)
        webView?.navigationDelegate = nil

        debugTabCount -= 1
#if DEBUG
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        func checkTabCount(failures: Int) {
            // Need delay for pool to drain.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if appDelegate.tabManager.remoteTabs.count == debugTabCount {
                    return
                }

                // If this assert has false positives, remove it and just log an error.
                assert(failures < 3, "Tab init/deinit imbalance, possible memory leak.")
                checkTabCount(failures: failures + 1)
            }
        }
        checkTabCount(failures: 0)
#endif
    }

    /// When a user clears ALL history, `sessionData` and `historyList` need to be purged, and close the webView.
    func clearAndResetTabHistory() {
        guard let currentlyOpenUrl = lastKnownUrl ?? historyList.last else { return }

        url = currentlyOpenUrl
        close()
    }

    func close() {
        contentScriptManager.uninstall(tab: self)
        webView?.configuration.userContentController.removeAllUserScripts()
        webView?.configuration.userContentController.removeAllScriptMessageHandlers()

        webView?.removeObserver(self, forKeyPath: KVOConstants.URL.rawValue)
        webView?.removeObserver(self, forKeyPath: KVOConstants.title.rawValue)
        webView?.removeObserver(self, forKeyPath: KVOConstants.hasOnlySecureContent.rawValue)

        if let webView = webView {
            tabDelegate?.tab(self, willDeleteWebView: webView)
        }

        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil
    }

    func goBack() {
        if isPDFRefactorEnabled {
            // if the file was cancelled then return and avoid calling webView.goBack
            // since the previous page is already there
            guard !cancelTemporaryDocumentDownload() else { return }
        }
        _ = webView?.goBack()
    }

    func goForward() {
        if isPDFRefactorEnabled {
            // if the file was cancelled then return and avoid calling webView.goForward
            // since the previous page is already there
            guard !cancelTemporaryDocumentDownload() else { return }
        }
        _ = webView?.goForward()
    }

    func goToBackForwardListItem(_ item: WKBackForwardListItem) {
        if isPDFRefactorEnabled {
            cancelTemporaryDocumentDownload()
        }
        _ = webView?.go(to: item)
    }

    @discardableResult
    func loadRequest(_ request: URLRequest) -> WKNavigation? {
        if isPDFRefactorEnabled {
            cancelTemporaryDocumentDownload(forceReload: false)
        }
        if let webView = webView {
            // Convert about:reader?url=http://example.com URLs to local ReaderMode URLs
            if let url = request.url,
               let syncedReaderModeURL = url.decodeReaderModeURL,
               let localReaderModeURL = syncedReaderModeURL.encodeReaderModeURL(
                WebServer.sharedInstance.baseReaderModeURL()
               ) {
                let readerModeRequest = PrivilegedRequest(url: localReaderModeURL) as URLRequest
                lastRequest = readerModeRequest
                return webView.load(readerModeRequest)
            }
            lastRequest = request
            if let url = request.url, url.isFileURL, request.isPrivileged {
                return webView.loadFileURL(url, allowingReadAccessTo: url)
            }
            return webView.load(request)
        }
        return nil
    }

    func stop() {
        webView?.stopLoading()
        if isPDFRefactorEnabled {
            cancelTemporaryDocumentDownload()
        }
    }

    func reload(bypassCache: Bool = false) {
        if isPDFRefactorEnabled {
            if cancelTemporaryDocumentDownload() {
                return
            }
        }
        // If the current page is an error page, and the reload button is tapped, load the original URL
        if let url = webView?.url, let internalUrl = InternalURL(url), let page = internalUrl.originalURLFromErrorPage {
            let request = URLRequest(url: page, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            webView?.load(request)
            return
        }

        if bypassCache, let url = webView?.url {
            let reloadRequest = URLRequest(url: url,
                                           cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                           timeoutInterval: 10.0)

            if webView?.load(reloadRequest) != nil {
                logger.log("Reloaded the tab from originating source, ignoring local cache.",
                           level: .debug,
                           category: .tabs)
                return
            }
        }

        // Do not reload from origin for homepage internal URLs
        if let webView, webView.url != nil && !(InternalURL(webView.url)?.isAboutHomeURL ?? false) {
            webView.reloadFromOrigin()
            logger.log("Reloaded zombified tab from origin",
                       level: .debug,
                       category: .tabs)
            return
        }

        if let webView = self.webView {
            logger.log("restoring webView from scratch",
                       level: .debug,
                       category: .tabs)
            restore(webView)
        }
    }

    @objc
    func reloadPage() {
        reload()
    }

    @objc
    func zoomIn() {
        switch pageZoom {
        case 0.75:
            pageZoom = 0.9
        case 0.9:
            pageZoom = 1.0
        case 1.0:
            pageZoom = 1.10
        case 1.10:
            pageZoom = 1.25
        case 2.0:
            return
        default:
            pageZoom += 0.25
        }
    }

    @objc
    func zoomOut() {
        switch pageZoom {
        case 0.5:
            return
        case 0.9:
            pageZoom = 0.75
        case 1.0:
            pageZoom = 0.9
        case 1.10:
            pageZoom = 1.0
        case 1.25:
            pageZoom = 1.10
        default:
            pageZoom -= 0.25
        }
    }

    func resetZoom() {
        pageZoom = 1.0
    }

    func setZoomLevelforDomain() {
        if let host = url?.host,
           let domainZoomLevel = ZoomLevelStore.shared.findZoomLevel(forDomain: host) {
            pageZoom = domainZoomLevel.zoomLevel
        } else {
            resetZoom()
        }
    }

    func addContentScript(_ helper: TabContentScript, name: String) {
        contentScriptManager.addContentScript(helper, name: name, forTab: self)
    }

    func addContentScriptToPage(_ helper: TabContentScript, name: String) {
        contentScriptManager.addContentScriptToPage(helper, name: name, forTab: self)
    }

    func addContentScriptToCustomWorld(_ helper: TabContentScript, name: String) {
        contentScriptManager.addContentScriptToCustomWorld(helper, name: name, forTab: self)
    }

    func getContentScript(name: String) -> TabContentScript? {
        return contentScriptManager.getContentScript(name)
    }

    func addLoginAlert(_ alert: SaveLoginAlert) {
        // Only one login alert can show per tab
        guard loginAlert == nil else { return }
        loginAlert = alert
        tabDelegate?.tab(self, didAddLoginAlert: alert)
    }

    func removeLoginAlert(_ alert: SaveLoginAlert) {
        tabDelegate?.tab(self, didRemoveLoginAlert: alert)
        loginAlert = nil
    }

    func expireLoginAlert() {
        if let loginAlert, !loginAlert.shouldPersist {
            removeLoginAlert(loginAlert)
        }
    }

    func setFindInPage(isBottomSearchBar: Bool, doesFindInPageBarExist: Bool) {
        if #available(iOS 16, *) {
            guard let webView = self.webView,
                  let findInteraction = webView.findInteraction else { return }
            isFindInPageMode = findInteraction.isFindNavigatorVisible && isBottomSearchBar
        } else {
            isFindInPageMode = doesFindInPageBarExist && isBottomSearchBar
        }
    }

    func setScreenshot(_ screenshot: UIImage?) {
        self.screenshot = screenshot
    }

    func toggleChangeUserAgent() {
        changedUserAgent = !changedUserAgent

        if changedUserAgent, let url = url {
            let url = ChangeUserAgent().removeMobilePrefixFrom(url: url)
            let request = URLRequest(url: url)
            webView?.load(request)
        } else {
            reload()
        }

        TabEvent.post(.didToggleDesktopMode, for: self)
    }

    func cancelQueuedAlerts() {
        alertQueue.forEach { alert in
            alert.cancel()
        }
    }

    /// Queues a JS Alert for later display
    /// Do not call completionHandler until the alert is displayed and dismissed
    func queueJavascriptAlertPrompt(_ alert: JSAlertInfo) {
        alertQueue.append(alert)
    }

    func dequeueJavascriptAlertPrompt() -> JSAlertInfo? {
        guard !alertQueue.isEmpty else { return nil }
        return alertQueue.removeFirst()
    }

    func hasJavascriptAlertPrompt() -> Bool {
        return !alertQueue.isEmpty
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let webView = object as? WKWebView,
              webView == self.webView,
              let path = keyPath else {
            return assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
        }

        if let title = self.webView?.title, !title.isEmpty,
           path == KVOConstants.title.rawValue {
            metadataManager?.updateObservationTitle(title)
            _ = Tab.toRemoteTab(self, inactive: false)
        }
    }

    func isDescendentOf(_ ancestor: Tab) -> Bool {
        return sequence(first: parent) { $0?.parent }.contains { $0 == ancestor }
    }

    func getProviderForUrl() -> SearchEngine {
        guard let url = self.webView?.url else {
            return .none
        }

        for provider in SearchEngine.allCases where url.absoluteString.contains(provider.rawValue) {
            return provider
        }

        return .none
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        UITextField.appearance().keyboardAppearance = theme.type.keyboardAppearence(isPrivate: isPrivate)
        webView?.applyTheme(theme: theme)
        /// Configures the web view's background to prevent a white flash during initial load in night mode.
        /// Note: Background colors are only visible when `isOpaque` is false — setting them while it's true has no effect.
        webView?.backgroundColor =  theme.colors.layer1
        webView?.scrollView.backgroundColor = theme.colors.layer1
        webView?.isOpaque = !nightMode
        webView?.underPageBackgroundColor = nightMode ? .black : nil
    }

    // MARK: - Static Helpers

    /// Returns true if the tabs both have the same type of private, normal active, and normal inactive.
    /// Simply checks the `isPrivate` and `isActive` flags of both tabs.
    func isSameTypeAs(_ otherTab: Tab) -> Bool {
        switch (self.isPrivate, otherTab.isPrivate) {
        case (true, true):
            // Two private tabs are always lumped together in the same type regardless of their last execution time
            return true
        case (false, false):
            // Two normal tabs are only the same type if they're both active, or both inactive
            return isInactiveTabsEnabled
                ? self.isActive == otherTab.isActive
                : true
        default:
            return false
        }
    }

    // MARK: - Temporary Document handling - PDF Refactor

    /// Returns true if the download was cancelled.
    ///
    /// `forceReload` forces the reload of the page when a document is downloading.
    ///  After download cancellation reload the page to ensure clean state.
    @discardableResult
    private func cancelTemporaryDocumentDownload(forceReload: Bool = true) -> Bool {
        guard let temporaryDocument else { return false }
        self.temporaryDocument = nil
        if temporaryDocument.isDownloading {
            temporaryDocument.cancelDownload()
            if forceReload {
                // if the webView's url is the home page then bypass cache so to reload the homepage
                // Otherwise the webView is restored causing the PDF to be reloaded again.
                let isInternalURL = InternalURL(webView?.url) != nil
                reload(bypassCache: isInternalURL)
            }
            return true
        }
        return false
    }

    private func deleteDownloadedDocuments() {
        let docsURL = downloadedTemporaryDocs
        guard !docsURL.isEmpty else { return }
        DispatchQueue.global(qos: .background).async {
            docsURL.forEach { url in
                try? FileManager.default.removeItem(at: url.value)
            }
        }
    }

    func canLoadDocumentRequest(_ request: URLRequest) -> Bool {
        return temporaryDocument?.canDownload(request: request) ?? true
    }

    func enqueueDocument(_ document: TemporaryDocument) {
        temporaryDocument = document

        temporaryDocument?.download { [weak self] url in
            guard let url else { return }
            self?.webView?.load(URLRequest(url: url))
            // Don't add a source URL if it is a local one. Thats happen when reloading the PDF content
            guard let sourceURL = document.sourceURL, document.sourceURL?.isFileURL == false else { return }
            self?.downloadedTemporaryDocs[url] = sourceURL
        }
    }

    func pauseResumeDocumentDownload() {
        temporaryDocument?.pauseResumeDownload()
    }

    func isDownloadingDocument() -> Bool {
        return temporaryDocument?.isDownloading ?? false
    }
}

extension Tab: UIGestureRecognizerDelegate {
    // This prevents the recognition of one gesture recognizer from blocking another
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    func configureEdgeSwipeGestureRecognizers() {
        guard let webView = webView else { return }

        let edgeSwipeGesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleEdgeSwipeTabNavigation(_:))
        )
        edgeSwipeGesture.edges = .left
        edgeSwipeGesture.delegate = self
        webView.addGestureRecognizer(edgeSwipeGesture)
    }

    @objc
    func handleEdgeSwipeTabNavigation(_ sender: UIScreenEdgePanGestureRecognizer) {
        guard let webView = webView else { return }
        if sender.state == .ended, sender.velocity(in: webView).x > 150 {
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .swipe,
                object: .navigateTabHistoryBackSwipe
            )
        }
    }
}

extension Tab: TabWebViewDelegate {
    func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String) {
        tabDelegate?.tab(self, didSelectFindInPageForSelection: selection)
    }

    func tabWebViewSearchWithFirefox(
        _ tabWebViewSearchWithFirefox: TabWebView,
        didSelectSearchWithFirefoxForSelection selection: String
    ) {
        tabDelegate?.tab(self, didSelectSearchWithFirefoxForSelection: selection)
    }

    func tabWebViewShouldShowAccessoryView(_ tabWebView: TabWebView) -> Bool {
        // Hide the default WKWebView accessory view panel for PDF documents
        return mimeType != MIMEType.PDF
    }
}

extension Tab: ContentBlockerTab {
    func currentURL() -> URL? {
        return url
    }

    func currentWebView() -> WKWebView? {
        return webView
    }

    func imageContentBlockingEnabled() -> Bool {
        return noImageMode
    }
}

private class TabContentScriptManager: NSObject, WKScriptMessageHandler {
    private var helpers = [String: TabContentScript]()

    // Without calling this, the TabContentScriptManager will leak.
    func uninstall(tab: Tab) {
        helpers.forEach { helper in
            helper.value.scriptMessageHandlerNames()?.forEach { name in
                tab.webView?.configuration.userContentController.removeScriptMessageHandler(forName: name)
            }
            helper.value.prepareForDeinit()
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        for helper in helpers.values {
            if let scriptMessageHandlerNames = helper.scriptMessageHandlerNames(),
               scriptMessageHandlerNames.contains(message.name) {
                helper.userContentController(userContentController, didReceiveScriptMessage: message)
                return
            }
        }
    }

    func addContentScript(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        // If a helper script already exists on a tab, skip adding this duplicate.
        guard helpers[name] == nil else { return }

        helpers[name] = helper

        // If this helper handles script messages, then get the handlers names and register them. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        helper.scriptMessageHandlerNames()?.forEach { scriptMessageHandlerName in
            tab.webView?.configuration.userContentController.addInDefaultContentWorld(
                scriptMessageHandler: self,
                name: scriptMessageHandlerName
            )
        }
    }

    func addContentScriptToPage(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        // If a helper script already exists on the page, skip adding this duplicate.
        guard helpers[name] == nil else { return }

        helpers[name] = helper

        // If this helper handles script messages, then get the handlers names and register them. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        helper.scriptMessageHandlerNames()?.forEach { scriptMessageHandlerName in
            tab.webView?.configuration.userContentController.addInPageContentWorld(
                scriptMessageHandler: self,
                name: scriptMessageHandlerName
            )
        }
    }

    func addContentScriptToCustomWorld(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        // If a helper script already exists on the page, skip adding this duplicate.
        guard helpers[name] == nil else { return }

        helpers[name] = helper

        // If this helper handles script messages, then get the handlers names and register them. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        helper.scriptMessageHandlerNames()?.forEach { scriptMessageHandlerName in
            tab.webView?.configuration.userContentController.addInCustomContentWorld(
                scriptMessageHandler: self,
                name: scriptMessageHandlerName
            )
        }
    }

    func getContentScript(_ name: String) -> TabContentScript? {
        return helpers[name]
    }
}

protocol TabWebViewDelegate: AnyObject {
    func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String)
    func tabWebViewSearchWithFirefox(
        _ tabWebViewSearchWithFirefox: TabWebView,
        didSelectSearchWithFirefoxForSelection selection: String
    )
    func tabWebViewShouldShowAccessoryView(_ tabWebView: TabWebView) -> Bool
}

class TabWebView: WKWebView, MenuHelperWebViewInterface, ThemeApplicable, FeatureFlaggable {
    lazy var accessoryView = AccessoryViewProvider(windowUUID: windowUUID)
    private var logger: Logger = DefaultLogger.shared
    private weak var delegate: TabWebViewDelegate?
    let windowUUID: WindowUUID
    private var pullRefresh: PullRefreshView?
    private var isPDFRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.pdfRefactor, checking: .buildOnly)
    }

    override var hasOnlySecureContent: Bool {
        // When PDF refactor enabled we show the online URL for a local PDF so secure content should be true
        if isPDFRefactorEnabled, let url, url.isFileURL, url.lastPathComponent.hasSuffix(".pdf") {
            return true
        }
        return super.hasOnlySecureContent
    }

    override var inputAccessoryView: UIView? {
        guard delegate?.tabWebViewShouldShowAccessoryView(self) ?? true else { return nil }

        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            accessoryView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            accessoryView.heightAnchor.constraint(equalToConstant: 50)
        ])

        return accessoryView
    }

    func configure(delegate: TabWebViewDelegate,
                   navigationDelegate: WKNavigationDelegate?) {
        self.delegate = delegate
        self.navigationDelegate = navigationDelegate

        accessoryView.previousClosure = { [weak self] in
            guard let self else { return }
            FormAutofillHelper.focusPreviousInputField(tabWebView: self,
                                                       logger: self.logger)
        }

        accessoryView.nextClosure = { [weak self] in
            guard let self else { return }
            FormAutofillHelper.focusNextInputField(tabWebView: self,
                                                   logger: self.logger)
        }

        accessoryView.doneClosure = { [weak self] in
            guard let self else { return }
            FormAutofillHelper.blurActiveElement(tabWebView: self, logger: self.logger)
            self.endEditing(true)
        }
    }

    init(frame: CGRect, configuration: WKWebViewConfiguration, windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(frame: frame, configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func menuHelperFindInPage() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
        }
    }

    func menuHelperSearchWith() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebViewSearchWithFirefox(self, didSelectSearchWithFirefoxForSelection: selection)
        }
    }

    override internal func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        // Do not becomeFirstResponder on a mouse event.
        if let event = event, event.allTouches?.contains(where: { $0.type != .indirectPointer }) ?? false {
            becomeFirstResponder()
        }
        return super.hitTest(point, with: event)
    }

    // swiftlint:disable unneeded_override
#if compiler(>=6)
    override func evaluateJavaScript(
        _ javaScriptString: String,
        completionHandler: (
            @MainActor @Sendable (Any?, (any Error)?) -> Void
        )? = nil
    ) {
        super.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
#else
    /// Override evaluateJavascript - should not be called directly on TabWebViews any longer
    /// We should only be calling evaluateJavascriptInDefaultContentWorld in the future
    @available(*,
                unavailable,
                message: "Do not call evaluateJavaScript directly on TabWebViews, should only be called on super class")
    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        super.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
#endif
    // swiftlint:enable unneeded_override

    // MARK: - PullRefresh

    func addPullRefresh(onReload: @escaping () -> Void) {
        guard !scrollView.isZooming, scrollView.frame != .zero else { return }
        guard pullRefresh == nil else {
            pullRefresh?.startObservingContentScroll()
            return
        }
        let refresh = PullRefreshView(parentScrollView: scrollView,
                                      isPortraitOrientation: UIWindow.isPortrait) {
            onReload()
        }
        scrollView.addSubview(refresh)
        refresh.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            refresh.leadingAnchor.constraint(equalTo: leadingAnchor),
            refresh.trailingAnchor.constraint(equalTo: trailingAnchor),
            refresh.bottomAnchor.constraint(equalTo: scrollView.topAnchor),
            refresh.heightAnchor.constraint(equalToConstant: scrollView.frame.height),
            refresh.widthAnchor.constraint(equalToConstant: scrollView.frame.width)
        ])
        refresh.startObservingContentScroll()
        pullRefresh = refresh
    }

    func removePullRefresh() {
        pullRefresh?.stopObservingContentScroll()
        pullRefresh?.removeFromSuperview()
        pullRefresh = nil
    }

    // MARK: - ThemeApplicable

    /// Updates the `background-color` of the webview to match
    /// the theme if the webview is showing "about:blank" (nil).
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        pullRefresh?.applyTheme(theme: theme)
        if url == nil {
            let backgroundColor = theme.colors.layer1.hexString
            evaluateJavascriptInDefaultContentWorld("document.documentElement.style.backgroundColor = '\(backgroundColor)';")
        }
    }
}
