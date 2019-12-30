/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared
import SwiftyJSON
import XCGLogger
import ARKit

fileprivate var debugTabCount = 0

func mostRecentTab(inTabs tabs: [Tab]) -> Tab? {
    var recent = tabs.first
    tabs.forEach { tab in
        if let time = tab.lastExecutedTime, time > (recent?.lastExecutedTime ?? 0) {
            recent = tab
        }
    }
    return recent
}

protocol TabContentScript {
    static func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

@objc
protocol TabDelegate {
    func tab(_ tab: Tab, didAddSnackbar bar: SnackBar)
    func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar)
    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String)
    func tab(_ tab: Tab, didSelectSearchWithFirefoxForSelection selection: String)
    @objc optional func tab(_ tab: Tab, didCreateWebView webView: WKWebView)
    @objc optional func tab(_ tab: Tab, willDeleteWebView webView: WKWebView)
}

@objc
protocol URLChangeDelegate {
    func tab(_ tab: Tab, urlDidChangeTo url: URL)
}

struct TabState {
    var isPrivate: Bool = false
    var url: URL?
    var title: String?
    var favicon: Favicon?
}

class Tab: NSObject {
    fileprivate var _isPrivate: Bool = false
    internal fileprivate(set) var isPrivate: Bool {
        get {
            return _isPrivate
        }
        set {
            if _isPrivate != newValue {
                _isPrivate = newValue
            }
        }
    }

    var tabState: TabState {
        return TabState(isPrivate: _isPrivate, url: url, title: displayTitle, favicon: displayFavicon)
    }

    // PageMetadata is derived from the page content itself, and as such lags behind the
    // rest of the tab.
    var pageMetadata: PageMetadata?

    var consecutiveCrashes: UInt = 0

    var canonicalURL: URL? {
        if let string = pageMetadata?.siteURL,
            let siteURL = URL(string: string) {

            // If the canonical URL from the page metadata doesn't contain the
            // "#" fragment, check if the tab's URL has a fragment and if so,
            // append it to the canonical URL.
            if siteURL.fragment == nil,
                let fragment = self.url?.fragment,
                let siteURLWithFragment = URL(string: "\(string)#\(fragment)") {
                return siteURLWithFragment
            }

            return siteURL
        }
        return self.url
    }

    var userActivity: NSUserActivity?

    var webView: WKWebView?
    var tabDelegate: TabDelegate?
    weak var urlDidChangeDelegate: URLChangeDelegate?     // TODO: generalize this.
    var bars = [SnackBar]()
    var favicons = [Favicon]()
    var lastExecutedTime: Timestamp?
    var sessionData: SessionData?
    fileprivate var lastRequest: URLRequest?
    var restoring: Bool = false
    var pendingScreenshot = false
    var url: URL? {
        didSet {
            if let _url = url, let internalUrl = InternalURL(_url), internalUrl.isAuthorized {
                url = URL(string: internalUrl.stripAuthorization)
            }
        }
    }
    var mimeType: String?
    var isEditing: Bool = false

    // When viewing a non-HTML content type in the webview (like a PDF document), this URL will
    // point to a tempfile containing the content so it can be shared to external applications.
    var temporaryDocument: TemporaryDocument?

    /// Returns true if this tab's URL is known, and it's longer than we want to store.
    var urlIsTooLong: Bool {
        guard let url = self.url else {
            return false
        }
        return url.absoluteString.lengthOfBytes(using: .utf8) > AppConstants.DB_URL_LENGTH_MAX
    }

    // Use computed property so @available can be used to guard `noImageMode`.
    var noImageMode: Bool {
        didSet {
            guard noImageMode != oldValue else {
                return
            }

            contentBlocker?.noImageMode(enabled: noImageMode)

            UserScriptManager.shared.injectUserScriptsIntoTab(self, nightMode: nightMode, noImageMode: noImageMode)
        }
    }

    var nightMode: Bool {
        didSet {
            guard nightMode != oldValue else {
                return
            }

            webView?.evaluateJavaScript("window.__firefox__.NightMode.setEnabled(\(nightMode))")
            // For WKWebView background color to take effect, isOpaque must be false,
            // which is counter-intuitive. Default is true. The color is previously
            // set to black in the WKWebView init.
            webView?.isOpaque = !nightMode

            UserScriptManager.shared.injectUserScriptsIntoTab(self, nightMode: nightMode, noImageMode: noImageMode)
        }
    }

    var contentBlocker: FirefoxTabContentBlocker?

    /// The last title shown by this tab. Used by the tab tray to show titles for zombie tabs.
    var lastTitle: String?

    /// Whether or not the desktop site was requested with the last request, reload or navigation.
    var changedUserAgent: Bool = false {
        didSet {
            webView?.customUserAgent = changedUserAgent ? UserAgent.oppositeUserAgent() : nil
            if changedUserAgent != oldValue {
                TabEvent.post(.didToggleDesktopMode, for: self)
            }
        }
    }

    var readerModeAvailableOrActive: Bool {
        if let readerMode = self.getContentScript(name: "ReaderMode") as? ReaderMode {
            return readerMode.state != .unavailable
        }
        return false
    }

    fileprivate(set) var screenshot: UIImage?
    var screenshotUUID: UUID?

    // If this tab has been opened from another, its parent will point to the tab from which it was opened
    weak var parent: Tab?

    fileprivate var contentScriptManager = TabContentScriptManager()

    fileprivate let configuration: WKWebViewConfiguration

    /// Any time a tab tries to make requests to display a Javascript Alert and we are not the active
    /// tab instance, queue it for later until we become foregrounded.
    fileprivate var alertQueue = [JSAlertInfo]()

    weak var browserViewController:BrowserViewController?
    lazy var stateController: AppStateController = AppStateController(state: AppState.defaultState())
    var arkController: ARKController?
    var webController: WebController?
    var messageController: MessageController?
//    var overlayController: UIOverlayController?
//    private var animator: Animator?
    private var deferredHitTest: (Int, CGFloat, CGFloat, ResultArrayBlock)? = nil
    private var timerSessionRunningInBackground: Timer?
    private var savedRender: Block? = nil

    init(bvc: BrowserViewController, configuration: WKWebViewConfiguration, isPrivate: Bool = false) {
        self.configuration = configuration
        self.nightMode = false
        self.noImageMode = false
        self.browserViewController = bvc
        super.init()
        self.isPrivate = isPrivate

        debugTabCount += 1

        UnifiedTelemetry.recordEvent(category: .action, method: .add, object: .tab, value: isPrivate ? .privateTab : .normalTab)
    }

    class func toRemoteTab(_ tab: Tab) -> RemoteTab? {
        if tab.isPrivate {
            return nil
        }

        if let displayURL = tab.url?.displayURL, RemoteTab.shouldIncludeURL(displayURL) {
            let history = Array(tab.historyList.filter(RemoteTab.shouldIncludeURL).reversed())
            return RemoteTab(clientGUID: nil,
                URL: displayURL,
                title: tab.displayTitle,
                history: history,
                lastUsed: Date.now(),
                icon: nil)
        } else if let sessionData = tab.sessionData, !sessionData.urls.isEmpty {
            let history = Array(sessionData.urls.filter(RemoteTab.shouldIncludeURL).reversed())
            if let displayURL = history.first {
                return RemoteTab(clientGUID: nil,
                    URL: displayURL,
                    title: tab.displayTitle,
                    history: history,
                    lastUsed: sessionData.lastUsedTime,
                    icon: nil)
            }
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

    func createWebview() {
        if webView == nil {
            configuration.userContentController = WKUserContentController()
            configuration.allowsInlineMediaPlayback = true
//            configuration.mediaTypesRequiringUserActionForPlayback = []
//            configuration.allowsPictureInPictureMediaPlayback = true
//            configuration.allowsPictureInPictureMediaPlayback = true
//            let preferences = WKPreferences()
//            preferences.javaScriptEnabled = true
//            configuration.preferences = preferences
            
//            browserViewController?.webViewContainer = UIView()
            
            for view in browserViewController?.webViewContainer.subviews ?? [] {
                view.removeFromSuperview()
            }
            
            setupXRWebController()
            setupXRControllers()
//            let webView = TabWebView(frame: .zero, configuration: configuration)
            webController?.webView?.delegate = self

            webController?.webView?.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webController?.webView?.allowsBackForwardNavigationGestures = true

            if #available(iOS 13, *) {
                webController?.webView?.allowsLinkPreview = true
            } else {
                webController?.webView?.allowsLinkPreview = false
            }


            // Night mode enables this by toggling WKWebView.isOpaque, otherwise this has no effect.
//            webController?.webView?.backgroundColor = .black

            // Turning off masking allows the web content to flow outside of the scrollView's frame
            // which allows the content appear beneath the toolbars in the BrowserViewController
            webController?.webView?.scrollView.layer.masksToBounds = false
            webController?.webView?.navigationDelegate = navigationDelegate

            guard let tabView = webController?.webView else {
                print("Unable to grab webController webView")
                return
            }
            restore(tabView)

            self.webView = webController?.webView
            self.webView?.addObserver(self, forKeyPath: KVOConstants.URL.rawValue, options: .new, context: nil)
            UserScriptManager.shared.injectUserScriptsIntoTab(self, nightMode: nightMode, noImageMode: noImageMode)
            tabDelegate?.tab?(self, didCreateWebView: tabView)
        }
    }

    func restore(_ webView: WKWebView) {
        // Pulls restored session data from a previous SavedTab to load into the Tab. If it's nil, a session restore
        // has already been triggered via custom URL, so we use the last request to trigger it again; otherwise,
        // we extract the information needed to restore the tabs and create a NSURLRequest with the custom session restore URL
        // to trigger the session restore via custom handlers
        if let sessionData = self.sessionData {
            restoring = true

            var urls = [String]()
            for url in sessionData.urls {
                urls.append(url.absoluteString)
            }

            let currentPage = sessionData.currentPage
            self.sessionData = nil
            var jsonDict = [String: AnyObject]()
            jsonDict["history"] = urls as AnyObject?
            jsonDict["currentPage"] = currentPage as AnyObject?
            guard let json = JSON(jsonDict).stringify()?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return
            }

            if let restoreURL = URL(string: "\(InternalURL.baseUrl)/\(SessionRestoreHandler.path)?history=\(json)") {
                let request = PrivilegedRequest(url: restoreURL) as URLRequest
                webView.load(request)
                lastRequest = request
            }
        } else if let request = lastRequest {
            webView.load(request)
        } else {
            print("creating webview with no lastRequest and no session data: \(self.url?.description ?? "nil")")
        }
    }

    deinit {
        debugTabCount -= 1

        #if DEBUG
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        func checkTabCount(failures: Int) {
            // Need delay for pool to drain.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if appDelegate.tabManager.tabs.count == debugTabCount {
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

    func closeAndRemovePrivateBrowsingData() {
        contentScriptManager.uninstall(tab: self)

        webView?.removeObserver(self, forKeyPath: KVOConstants.URL.rawValue)

        if let webView = webView {
            tabDelegate?.tab?(self, willDeleteWebView: webView)
        }

        if isPrivate {
            removeAllBrowsingData()
        }

        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil
    }

    func removeAllBrowsingData(completionHandler: @escaping () -> Void = {}) {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        webView?.configuration.websiteDataStore.removeData(ofTypes: dataTypes,
                                                     modifiedSince: Date.distantPast,
                                                 completionHandler: completionHandler)
    }

    var loading: Bool {
        return webView?.isLoading ?? false
    }

    var estimatedProgress: Double {
        return webView?.estimatedProgress ?? 0
    }

    var backList: [WKBackForwardListItem]? {
        return webView?.backForwardList.backList
    }

    var forwardList: [WKBackForwardListItem]? {
        return webView?.backForwardList.forwardList
    }

    var historyList: [URL] {
        func listToUrl(_ item: WKBackForwardListItem) -> URL { return item.url }
        var tabs = self.backList?.map(listToUrl) ?? [URL]()
        if let url = url {
            tabs.append(url)
        }
        return tabs
    }

    var title: String? {
        return webView?.title
    }

    var displayTitle: String {
        if let title = webView?.title, !title.isEmpty {
            return title
        }

        // When picking a display title. Tabs with sessionData are pending a restore so show their old title.
        // To prevent flickering of the display title. If a tab is restoring make sure to use its lastTitle.
        if let url = self.url, InternalURL(url)?.isAboutHomeURL ?? false, sessionData == nil, !restoring {
            return Strings.AppMenuOpenHomePageTitleString
        }

        //lets double check the sessionData in case this is a non-restored new tab
        if let firstURL = sessionData?.urls.first, sessionData?.urls.count == 1,  InternalURL(firstURL)?.isAboutHomeURL ?? false {
            return Strings.AppMenuOpenHomePageTitleString
        }

        if let url = self.url, !InternalURL.isValid(url: url), let shownUrl = url.displayURL?.absoluteString {
            return shownUrl
        }

        guard let lastTitle = lastTitle, !lastTitle.isEmpty else {
            return self.url?.displayURL?.absoluteString ??  ""
        }

        return lastTitle
    }

    var displayFavicon: Favicon? {
        return favicons.max { $0.width! < $1.width! }
    }

    var canGoBack: Bool {
        return webView?.canGoBack ?? false
    }

    var canGoForward: Bool {
        return webView?.canGoForward ?? false
    }

    func goBack() {
        if browserViewController?.webViewContainer.subviews.count ?? 1 > 1 {
            browserViewController?.webViewContainer.subviews[0].removeFromSuperview()
        }
        _ = webView?.goBack()
    }

    func goForward() {
        if browserViewController?.webViewContainer.subviews.count ?? 1 > 1 {
            browserViewController?.webViewContainer.subviews[0].removeFromSuperview()
        }
        _ = webView?.goForward()
    }

    func goToBackForwardListItem(_ item: WKBackForwardListItem) {
        _ = webView?.go(to: item)
    }

    @discardableResult func loadRequest(_ request: URLRequest) -> WKNavigation? {
        if browserViewController?.webViewContainer.subviews.count ?? 1 > 1 {
            browserViewController?.webViewContainer.subviews[0].removeFromSuperview()
        }
        
        if let webView = webView {
            stateController.setWebXR(false)
            // Convert about:reader?url=http://example.com URLs to local ReaderMode URLs
            if let url = request.url, let syncedReaderModeURL = url.decodeReaderModeURL, let localReaderModeURL = syncedReaderModeURL.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) {
                let readerModeRequest = PrivilegedRequest(url: localReaderModeURL) as URLRequest
                lastRequest = readerModeRequest
                return webView.load(readerModeRequest)
            }
            lastRequest = request
            if let url = request.url, url.isFileURL, request.isPrivileged {
                return webView.loadFileURL(url, allowingReadAccessTo: url)
            }
            if UserDefaults.standard.bool(forKey: Constant.exposeWebXRAPIKey()) {
                if let webView = self.webView,
                    let path = Bundle.main.path(forResource: "webxrShim", ofType: "js"),
                    var source = try? String(contentsOfFile: path)
                {
                    let polyfillURL = UserDefaults.standard.string(forKey: Constant.polyfillURLKey()) ?? "https://raw.githack.com/MozillaReality/webxr-ios-js/develop/dist/webxr.js"
                    source = "{ const REALAPI_URL = '\(polyfillURL)'; " + source
                    let userScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                    webView.configuration.userContentController.addUserScript(userScript)
                }
            }
            return webView.load(request)
        }
        return nil
    }

    func stop() {
        webView?.stopLoading()
    }

    func reload() {
        if browserViewController?.webViewContainer.subviews.count ?? 1 > 1 {
            browserViewController?.webViewContainer.subviews[0].removeFromSuperview()
        }
        
        // If the current page is an error page, and the reload button is tapped, load the original URL
        if let url = webView?.url, let internalUrl = InternalURL(url), let page = internalUrl.originalURLFromErrorPage {
            webView?.evaluateJavaScript("location.replace('\(page)')", completionHandler: nil)
            return
        }
        
        if let _ = webView?.reloadFromOrigin() {
            print("reloaded zombified tab from origin")
            return
        }

        if let webView = self.webView {
            print("restoring webView from scratch")
            restore(webView)
        }
    }

    func addContentScript(_ helper: TabContentScript, name: String) {
        contentScriptManager.addContentScript(helper, name: name, forTab: self)
    }

    func getContentScript(name: String) -> TabContentScript? {
        return contentScriptManager.getContentScript(name)
    }

    func hideContent(_ animated: Bool = false) {
        webView?.isUserInteractionEnabled = false
        if animated {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.webView?.alpha = 0.0
            })
        } else {
            webView?.alpha = 0.0
        }
    }

    func showContent(_ animated: Bool = false) {
        webView?.isUserInteractionEnabled = true
        if animated {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.webView?.alpha = 1.0
            })
        } else {
            webView?.alpha = 1.0
        }
    }

    func addSnackbar(_ bar: SnackBar) {
        bars.append(bar)
        tabDelegate?.tab(self, didAddSnackbar: bar)
    }

    func removeSnackbar(_ bar: SnackBar) {
        if let index = bars.firstIndex(of: bar) {
            bars.remove(at: index)
            tabDelegate?.tab(self, didRemoveSnackbar: bar)
        }
    }

    func removeAllSnackbars() {
        // Enumerate backwards here because we'll remove items from the list as we go.
        bars.reversed().forEach { removeSnackbar($0) }
    }

    func expireSnackbars() {
        // Enumerate backwards here because we may remove items from the list as we go.
        bars.reversed().filter({ !$0.shouldPersist(self) }).forEach({ removeSnackbar($0) })
    }

    func expireSnackbars(withClass snackbarClass: String) {
        bars.reversed().filter({ $0.snackbarClassIdentifier == snackbarClass }).forEach({ removeSnackbar($0) })
    }

    func setScreenshot(_ screenshot: UIImage?, revUUID: Bool = true) {
        self.screenshot = screenshot
        if revUUID {
            self.screenshotUUID = UUID()
        }
    }

    func toggleChangeUserAgent() {
        changedUserAgent = !changedUserAgent
        reload()
        TabEvent.post(.didToggleDesktopMode, for: self)
    }

    func queueJavascriptAlertPrompt(_ alert: JSAlertInfo) {
        alertQueue.append(alert)
    }

    func dequeueJavascriptAlertPrompt() -> JSAlertInfo? {
        guard !alertQueue.isEmpty else {
            return nil
        }
        return alertQueue.removeFirst()
    }

    func cancelQueuedAlerts() {
        alertQueue.forEach { alert in
            alert.cancel()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView, webView == self.webView,
            let path = keyPath, path == KVOConstants.URL.rawValue else {
            return assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
        }
        guard let url = self.webView?.url else {
            return
        }

        self.urlDidChangeDelegate?.tab(self, urlDidChangeTo: url)
    }

    func isDescendentOf(_ ancestor: Tab) -> Bool {
        return sequence(first: parent) { $0?.parent }.contains { $0 == ancestor }
    }

    func injectUserScriptWith(fileName: String, type: String = "js", injectionTime: WKUserScriptInjectionTime = .atDocumentEnd, mainFrameOnly: Bool = true) {
        guard let webView = self.webView else {
            return
        }
        if let path = Bundle.main.path(forResource: fileName, ofType: type),
            let source = try? String(contentsOfFile: path) {
            let userScript = WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: mainFrameOnly)
            webView.configuration.userContentController.addUserScript(userScript)
        }
    }

    func observeURLChanges(delegate: URLChangeDelegate) {
        self.urlDidChangeDelegate = delegate
    }

    func removeURLChangeObserver(delegate: URLChangeDelegate) {
        if let existing = self.urlDidChangeDelegate, existing === delegate {
            self.urlDidChangeDelegate = nil
        }
    }

    func applyTheme() {
        UITextField.appearance().keyboardAppearance = isPrivate ? .dark : (ThemeManager.instance.currentName == .dark ? .dark : .light)
    }
    
    func setupXRControllers() {
        setupXRStateController()
//        setupAnimator()
        setupMessageController()
//        setupXRWebController()
//        setupOverlayController()
        setupXRNotifications()
    }
    
    // MARK: - Setup State Controller
    
    func setupXRStateController() {
        weak var blockSelf: Tab? = self

        stateController.onDebug = { showDebug in
            blockSelf?.webController?.showDebug(showDebug)
        }

        stateController.onModeUpdate = { mode in
            blockSelf?.arkController?.setShowMode(mode)
//            blockSelf?.overlayController?.setMode(mode)
            guard let showURL = blockSelf?.stateController.shouldShowURLBar() else { return }
            blockSelf?.webController?.showBar(showURL)
//            if blockSelf?.messageLabel.text != "" {
//                blockSelf?.showHideMessage(hide: !showURL)
//            }
//            blockSelf?.trackingStatusIcon.isHidden = showURL
        }

        stateController.onOptionsUpdate = { options in
            blockSelf?.arkController?.setShowOptions(options)
//            blockSelf?.overlayController?.setOptions(options)
            guard let showURL = blockSelf?.stateController.shouldShowURLBar() else { return }
            blockSelf?.webController?.showBar(showURL)
//            if blockSelf?.messageLabel.text != "" {
//                blockSelf?.showHideMessage(hide: !showURL)
//            }
//            blockSelf?.trackingStatusIcon.isHidden = showURL
        }

        stateController.onXRUpdate = { xr in
//            blockSelf?.messageLabel.text = ""
            if xr {
                guard let debugSelected = blockSelf?.webController?.isDebugButtonSelected() else { return }
                guard let shouldShowSessionStartedPopup = blockSelf?.stateController.state.shouldShowSessionStartedPopup else { return }
                
                if debugSelected {
                    blockSelf?.stateController.setShowMode(.debug)
                } else {
                    blockSelf?.stateController.setShowMode(.nothing)
                }

                var tabsRunningXR = 0
                for tab in blockSelf?.browserViewController?.tabManager.tabs ?? [] {
                    if tab.arkController?.arSessionState == .arkSessionRunning {
                        tabsRunningXR += 1
                    }
                }
                if tabsRunningXR > 1 {
                    blockSelf?.stateController.state.shouldShowSessionStartedPopup = false
                    blockSelf?.messageController?.showMessage(withTitle: MULTIPLE_AR_SESSIONS_TITLE, message: MULTIPLE_AR_SESSIONS_MESSAGE, hideAfter: MULTIPLE_AR_SESSIONS_POPUP_TIME_IN_SECONDS)
                }
                
                if shouldShowSessionStartedPopup {
                    blockSelf?.stateController.state.shouldShowSessionStartedPopup = false
                    blockSelf?.messageController?.showMessage(withTitle: AR_SESSION_STARTED_POPUP_TITLE, message: AR_SESSION_STARTED_POPUP_MESSAGE, hideAfter: AR_SESSION_STARTED_POPUP_TIME_IN_SECONDS)
                }

                blockSelf?.webController?.lastXRVisitedURL = blockSelf?.webController?.webView?.url?.absoluteString ?? ""
                blockSelf?.browserViewController?.scrollController.hideToolbars(animated: true)
                blockSelf?.browserViewController?.urlBar.updateReaderModeState(.unavailable)
            } else {
                blockSelf?.stateController.setShowMode(.nothing)
//                blockSelf?.webController?.barView?.permissionLevelButton?.buttonImage = nil
//                blockSelf?.webController?.barView?.permissionLevelButton?.isEnabled = blockSelf?.arkController?.webXRAuthorizationStatus == .denied ? true : false
                if blockSelf?.arkController?.arSessionState == .arkSessionRunning {
                    blockSelf?.timerSessionRunningInBackground?.invalidate()
                    let timerSeconds: Int = UserDefaults.standard.integer(forKey: Constant.secondsInBackgroundKey())
                    print(String(format: "\n\n*********\n\nMoving away from an XR site, keep ARKit running, and launch the timer for %ld seconds\n\n*********", timerSeconds))
                    blockSelf?.timerSessionRunningInBackground = Timer.scheduledTimer(withTimeInterval: TimeInterval(timerSeconds), repeats: false, block: { timer in
                        print("\n\n*********\n\nTimer expired, pausing session\n\n*********")
                        UserDefaults.standard.set(Date(), forKey: Constant.backgroundOrPausedDateKey())
                        blockSelf?.arkController?.pauseSession()
                        blockSelf?.timerSessionRunningInBackground?.invalidate()
                        blockSelf?.timerSessionRunningInBackground = nil
                    })
                }
                blockSelf?.browserViewController?.scrollController.showToolbars(animated: true)
            }
            blockSelf?.updateConstraints()
//            blockSelf?.cancelAllScheduledMessages()
//            blockSelf?.showHideMessage(hide: true)
            blockSelf?.arkController?.controller.initializingRender = true
            blockSelf?.savedRender = nil
//            blockSelf?.trackingStatusIcon.image = nil
            blockSelf?.webController?.setup(forWebXR: xr)
        }

        stateController.onReachable = { url in
            blockSelf?.loadURL(url)
        }

        stateController.onEnterForeground = { url in
            blockSelf?.stateController.state.shouldRemoveAnchorsOnNextARSession = false

            blockSelf?.messageController?.clean()
            let requestedURL = UserDefaults.standard.string(forKey: REQUESTED_URL_KEY)
            if requestedURL != nil {
                print("\n\n*********\n\nMoving to foreground because the user wants to open a URL externally, loading the page\n\n*********")
                UserDefaults.standard.set(nil, forKey: REQUESTED_URL_KEY)
                blockSelf?.loadURL(requestedURL)
            } else {
                guard let arSessionState = blockSelf?.arkController?.arSessionState else { return }
                switch arSessionState {
                    case .arkSessionUnknown:
                        print("\n\n*********\n\nMoving to foreground while ARKit is not initialized, do nothing\n\n*********")
                    case .arkSessionPaused:
                        guard let hasWorldMap = blockSelf?.arkController?.hasBackgroundWorldMap() else { return }
                        if !hasWorldMap {
                            // if no background map, then need to remove anchors on next session
                            print("\n\n*********\n\nMoving to foreground while the session is paused, remember to remove anchors on next AR request\n\n*********")
                            blockSelf?.stateController.state.shouldRemoveAnchorsOnNextARSession = true
                        }
                    case .arkSessionRunning:
                        guard let hasWorldMap = blockSelf?.arkController?.hasBackgroundWorldMap() else { return }
                        if hasWorldMap {
                            print("\n\n*********\n\nMoving to foreground while the session is running and it was in BG\n\n*********")

                            print("\n\n*********\n\nARKit will attempt to relocalize the worldmap automatically\n\n*********")
                        } else {
                            let interruptionDate = UserDefaults.standard.object(forKey: Constant.backgroundOrPausedDateKey()) as? Date
                            let now = Date()
                            if let aDate = interruptionDate {
                                if now.timeIntervalSince(aDate) >= Constant.pauseTimeInSecondsToRemoveAnchors() {
                                    print("\n\n*********\n\nMoving to foreground while the session is running and it was in BG for a long time, remove the anchors\n\n*********")
                                    blockSelf?.arkController?.removeAllAnchors()
                                } else {
                                    print("\n\n*********\n\nMoving to foreground while the session is running and it was in BG for a short time, do nothing\n\n*********")
                                }
                            }
                        }
                }
            }

            UserDefaults.standard.set(nil, forKey: Constant.backgroundOrPausedDateKey())
        }

        stateController.onMemoryWarning = { url in
            blockSelf?.arkController?.controller.previewingSinglePlane = false
//            blockSelf?.chooseSinglePlaneButton.isHidden = true
            blockSelf?.messageController?.showMessageAboutMemoryWarning(withCompletion: {
                blockSelf?.webController?.prefillLastURL()
            })

            blockSelf?.webController?.didReceiveError(error: NSError(domain: MEMORY_ERROR_DOMAIN, code: MEMORY_ERROR_CODE, userInfo: [NSLocalizedDescriptionKey: MEMORY_ERROR_MESSAGE]))
        }

        stateController.onRequestUpdate = { dict in
            defer {
                if dict?[WEB_AR_CV_INFORMATION_OPTION] as? Bool ?? false {
                    blockSelf?.stateController.state.computerVisionFrameRequested = true
                    blockSelf?.arkController?.computerVisionFrameRequested = true
                    blockSelf?.stateController.state.sendComputerVisionData = true
                }
            }
            
            if blockSelf?.timerSessionRunningInBackground != nil {
                print("\n\n*********\n\nInvalidate timer\n\n*********")
                blockSelf?.timerSessionRunningInBackground?.invalidate()
            }
            if let metal = blockSelf?.arkController?.usingMetal,
                metal != UserDefaults.standard.bool(forKey: Constant.useMetalForARKey())
            {
                blockSelf?.savedRender = nil
                blockSelf?.arkController = nil
            }

            if blockSelf?.arkController == nil {
                print("\n\n*********\n\nARKit is nil, instantiate and start a session\n\n*********")
                blockSelf?.startNewARKitSession(withRequest: dict)
            } else {
                guard let arSessionState = blockSelf?.arkController?.arSessionState else { return }
                guard let state = blockSelf?.stateController.state else { return }
                
                if blockSelf?.arkController?.trackingStateRelocalizing() ?? false {
                    blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                    return
                }
                
                switch arSessionState {
                    case .arkSessionUnknown:
                        print("\n\n*********\n\nARKit is in unknown state, instantiate and start a session\n\n*********")
                        blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                    case .arkSessionRunning:
                        if let lastTrackingResetDate = UserDefaults.standard.object(forKey: Constant.lastResetSessionTrackingDateKey()) as? Date,
                            Date().timeIntervalSince(lastTrackingResetDate) >= Constant.thresholdTimeInSecondsSinceLastTrackingReset() {
                            print("\n\n*********\n\nSession is running but it's been a while since last resetting tracking, resetting tracking and removing anchors now to prevent coordinate system drift\n\n*********")
                            blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                        } else if blockSelf?.urlIsNotTheLastXRVisitedURL() ?? false {
                            print("\n\n*********\n\nThis site is not the last XR site visited, and the timer hasn't expired yet. Remove distant anchors and continue with the session\n\n*********")
                            blockSelf?.arkController?.removeDistantAnchors()
                            blockSelf?.arkController?.runSession(with: state)
                        } else {
                            print("\n\n*********\n\nThis site is the last XR site visited, and the timer hasn't expired yet. Continue with the session\n\n*********")
                        }
                    case .arkSessionPaused:
                        print("\n\n*********\n\nRequest of a new AR session when it's paused\n\n*********")
                        guard let shouldRemoveAnchors = blockSelf?.stateController.state.shouldRemoveAnchorsOnNextARSession else { return }
                        if let lastTrackingResetDate = UserDefaults.standard.object(forKey: Constant.lastResetSessionTrackingDateKey()) as? Date,
                            Date().timeIntervalSince(lastTrackingResetDate) >= Constant.thresholdTimeInSecondsSinceLastTrackingReset() {
                            print("\n\n*********\n\nSession is paused and it's been a while since last resetting tracking, resetting tracking and removing anchors on this paused session to prevent coordinate system drift\n\n*********")
                            blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                        } else if shouldRemoveAnchors {
                            print("\n\n*********\n\nRun session removing anchors\n\n*********")
                            blockSelf?.stateController.state.shouldRemoveAnchorsOnNextARSession = false
                            blockSelf?.arkController?.runSessionRemovingAnchors(with: state)
                        } else {
                            print("\n\n*********\n\nResume session\n\n*********")
                            blockSelf?.arkController?.resumeSession(with: state)
                        }
                }
            }
        }
    }
    
//    func setupAnimator() {
//        self.animator = Animator()
//    }
    
    // MARK: - Setup Message Controller
    
    func setupMessageController() {
        self.messageController = MessageController(viewController: browserViewController)

        weak var blockSelf: Tab? = self

        messageController?.didShowMessage = {
            blockSelf?.stateController.saveOnMessageShowMode()
            blockSelf?.stateController.setShowMode(.nothing)
        }

        messageController?.didHideMessage = {
            blockSelf?.stateController.applyOnMessageShowMode()
        }

        messageController?.didHideMessageByUser = {
            //[[blockSelf stateController] applyOnMessageShowMode];
        }
    }
    
    func setupXRNotifications() {
        weak var blockSelf: Tab? = self

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main, using: { note in
            blockSelf?.arkController?.controller.previewingSinglePlane = false
//            blockSelf?.chooseSinglePlaneButton.isHidden = true
            var arSessionState: ARKitSessionState
            if blockSelf?.arkController?.arSessionState != nil {
                arSessionState = (blockSelf?.arkController?.arSessionState)!
            } else {
                arSessionState = .arkSessionUnknown
            }
            switch arSessionState {
                case .arkSessionUnknown:
                    print("\n\n*********\n\nMoving to background while ARKit is not initialized, nothing to do\n\n*********")
                case .arkSessionPaused:
                    print("\n\n*********\n\nMoving to background while the session is paused, nothing to do\n\n*********")
                    // need to try and save WorldMap here.  May fail?
                    blockSelf?.arkController?.saveWorldMapInBackground()
                case .arkSessionRunning:
                    print("\n\n*********\n\nMoving to background while the session is running, store the timestamp\n\n*********")
                    UserDefaults.standard.set(Date(), forKey: Constant.backgroundOrPausedDateKey())
                    // need to save WorldMap here
                    blockSelf?.arkController?.saveWorldMapInBackground()
            }

            blockSelf?.webController?.didBackgroundAction(true)

            blockSelf?.stateController.saveMoveToBackground(onURL: blockSelf?.webController?.lastURL)
        })

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main, using: { note in
            blockSelf?.stateController.applyOnEnterForegroundAction()
        })

        NotificationCenter.default.addObserver(self, selector: #selector(Tab.deviceOrientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func deviceOrientationDidChange(_ notification: Notification?) {
        arkController?.shouldUpdateWindowSize = true
        updateConstraints()
    }
    
    // MARK: - Setup Web Controller
    
    func setupXRWebController() {
//        CLEAN_VIEW(v: webLayerView)
        weak var blockSelf: Tab? = self

        self.webController = WebController(rootView: browserViewController?.webViewContainer)
        if !ARKController.supportsARFaceTrackingConfiguration() {
            webController?.hideCameraFlipButton()
        }
//        webController?.animator = animator
        webController?.onStartLoad = {
            if blockSelf?.arkController != nil {
                blockSelf?.arkController?.controller.previewingSinglePlane = false
//                blockSelf?.chooseSinglePlaneButton.isHidden = true
                let lastURL = blockSelf?.webController?.lastURL
                let currentURL = blockSelf?.webController?.webView?.url?.absoluteString

                if lastURL == currentURL {
                    // Page reload
                    blockSelf?.arkController?.removeAllAnchorsExceptPlanes()
                } else {
                    blockSelf?.arkController?.detectionImageCreationPromises.removeAllObjects()
                    blockSelf?.arkController?.detectionImageCreationRequests.removeAllObjects()
                }
                
                if let worldTrackingConfiguration = blockSelf?.arkController?.configuration as? ARWorldTrackingConfiguration,
                    worldTrackingConfiguration.detectionImages.count > 0,
                    let state = blockSelf?.stateController.state
                {
                    worldTrackingConfiguration.detectionImages = Set<ARReferenceImage>()
                    blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                }
            }
            blockSelf?.arkController?.webXRAuthorizationStatus = .notDetermined
            blockSelf?.stateController.setWebXR(false)
        }

        webController?.onFinishLoad = {
            //         [blockSelf hideSplashWithCompletion:^
            //          { }];
        }
        
        webController?.onInitAR = { uiOptionsDict in
            blockSelf?.stateController.setShowOptions(self.showOptionsFormDict(dict: uiOptionsDict))
            blockSelf?.stateController.applyOnEnterForegroundAction()
            blockSelf?.stateController.applyOnDidReceiveMemoryAction()
            blockSelf?.stateController.state.numberOfTrackedImages = 0
            blockSelf?.arkController?.setNumberOfTrackedImages(0)
            blockSelf?.savedRender = nil
        }

        webController?.onError = { error in
            if let error = error {
//                blockSelf?.showWebError(error as NSError)
            }
        }

        webController?.onWatchAR = { request in
            blockSelf?.handleOnWatchAR(withRequest: request, initialLoad: true, grantedPermissionsBlock: nil)
        }
        
        webController?.onRequestSession = { request, grantedPermissions in
            blockSelf?.handleOnWatchAR(withRequest: request, initialLoad: true, grantedPermissionsBlock: grantedPermissions)
        }
        
        webController?.onJSFinishedRendering = {
            blockSelf?.arkController?.controller.initializingRender = false
            blockSelf?.savedRender?()
            blockSelf?.savedRender = nil
            blockSelf?.arkController?.controller.readyToRenderFrame = true
            if let controller = blockSelf?.arkController?.controller as? ARKMetalController {
                controller.draw(in: controller.renderView)
            }
        }

        webController?.onStopAR = {
            blockSelf?.stateController.setWebXR(false)
            blockSelf?.stateController.setShowMode(.nothing)
            blockSelf?.webController?.userStoppedAR()
        }
        
        webController?.onShowPermissions = {
            blockSelf?.messageController?.forceShowPermissionsPopup = true
            guard let request = blockSelf?.stateController.state.aRRequest else { return }
            blockSelf?.handleOnWatchAR(withRequest: request, initialLoad: false, grantedPermissionsBlock: nil)
        }

        webController?.onJSUpdateData = {
            return blockSelf?.commonData() ?? [:]
        }

        webController?.loadURL = { url in
            blockSelf?.webController?.loadURL(url)
        }

        webController?.onSetUI = { uiOptionsDict in
            blockSelf?.stateController.setShowOptions(self.showOptionsFormDict(dict: uiOptionsDict))
        }

        webController?.onHitTest = { mask, x, y, result in
            if blockSelf?.arkController?.controller.previewingSinglePlane ?? false {
                print("Wait until after Lite Mode plane selected to perform hit tests")
                blockSelf?.deferredHitTest = (mask, x, y, result)
                return
            }
            if blockSelf?.arkController?.webXRAuthorizationStatus == .lite {
                // Default hit testing is done against plane geometry,
                // (HIT_TEST_TYPE_EXISTING_PLANE_GEOMETRY = 32 = 2^5), but to preserve privacy in
                // .lite Mode only hit test against the plane itself
                // (HIT_TEST_TYPE_EXISTING_PLANE = 8 = 2^3)
                if blockSelf?.arkController?.usingMetal ?? false {
                    var array = [[AnyHashable: Any]]()
                    switch blockSelf?.arkController?.interfaceOrientation {
                    case .landscapeLeft?:
                        array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: 1-x, y: 1-y), types: 8) ?? []
                    case .landscapeRight?:
                        array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: x, y: y), types: 8) ?? []
                    default:
                        array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: y, y: 1-x), types: 8) ?? []
                    }
                    result(array)
                } else {
                    let array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: x, y: y), types: 8)
                    result(array)
                }
            } else {
                if blockSelf?.arkController?.usingMetal ?? false {
                    var array = [[AnyHashable: Any]]()
                    switch blockSelf?.arkController?.interfaceOrientation {
                    case .landscapeLeft?:
                        array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: 1-x, y: 1-y), types: mask) ?? []
                    case .landscapeRight?:
                        array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: x, y: y), types: mask) ?? []
                    default:
                        array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: y, y: 1-x), types: mask) ?? []
                    }
                    result(array)
                } else {
                    let array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: x, y: y), types: mask)
                    result(array)
                }
            }
        }

        webController?.onAddAnchor = { name, transformArray, result in
            if blockSelf?.arkController?.addAnchor(name, transformHash: transformArray) ?? false {
                if let anArray = transformArray {
                    result([WEB_AR_UUID_OPTION: name ?? 0, WEB_AR_TRANSFORM_OPTION: anArray])
                }
            } else {
                result([:])
            }
        }

        webController?.onRemoveObjects = { objects in
            blockSelf?.arkController?.removeAnchors(objects)
        }

        webController?.onDebugButtonToggled = { selected in
            blockSelf?.stateController.setShowMode(selected ? ShowMode.urlDebug : ShowMode.url)
        }
        
        webController?.onGeometryArraysSet = { geometryArrays in
            blockSelf?.stateController.state.geometryArrays = geometryArrays
        }
        
        webController?.onSettingsButtonTapped = {
            // Before showing the settings popup, we hide the bar and the debug buttons so they are not in the way
            // After dismissing the popup, we show them again.
//            let settingsViewController = SettingsViewController()
//            let navigationController = UINavigationController(rootViewController: settingsViewController)
//            weak var weakSettingsViewController = settingsViewController
//            settingsViewController.onDoneButtonTapped = {
//                weakSettingsViewController?.dismiss(animated: true)
//                blockSelf?.webController?.showBar(true)
//                blockSelf?.stateController.setShowMode(.url)
//            }
//
//            blockSelf?.webController?.showBar(false)
//            blockSelf?.webController?.hideKeyboard()
//            blockSelf?.stateController.setShowMode(.nothing)
//            blockSelf?.present(navigationController, animated: true)
        }

        webController?.onComputerVisionDataRequested = {
            blockSelf?.stateController.state.computerVisionFrameRequested = true
            blockSelf?.arkController?.computerVisionFrameRequested = true
        }

        webController?.onResetTrackingButtonTapped = {

//            blockSelf?.messageController?.showMessageAboutResetTracking({ option in
//                guard let state = blockSelf?.stateController.state else { return }
//                switch option {
//                    case .resetTracking:
//                        blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
//                    case .removeExistingAnchors:
//                        blockSelf?.arkController?.runSessionRemovingAnchors(with: state)
//                    case .saveWorldMap:
//                        blockSelf?.arkController?.saveWorldMap()
//                    case .loadSavedWorldMap:
//                        blockSelf?.arkController?.loadSavedMap()
//                }
//            })
        }

        webController?.onStartSendingComputerVisionData = {
            blockSelf?.stateController.state.sendComputerVisionData = true
        }

        webController?.onStopSendingComputerVisionData = {
            blockSelf?.stateController.state.sendComputerVisionData = false
        }
        
        webController?.onSetNumberOfTrackedImages = { number in
            blockSelf?.stateController.state.numberOfTrackedImages = number
            blockSelf?.arkController?.setNumberOfTrackedImages(number)
        }

        webController?.onActivateDetectionImage = { imageName, completion in
            blockSelf?.arkController?.activateDetectionImage(imageName, completion: completion)
        }

        webController?.onGetWorldMap = { completion in
//            let completion = completion as? GetWorldMapCompletionBlock
            blockSelf?.arkController?.getWorldMap(completion)
        }

        webController?.onSetWorldMap = { dictionary, completion in
            blockSelf?.arkController?.setWorldMap(dictionary, completion: completion)
        }

        webController?.onDeactivateDetectionImage = { imageName, completion in
            blockSelf?.arkController?.deactivateDetectionImage(imageName, completion: completion)
        }

        webController?.onDestroyDetectionImage = { imageName, completion in
            blockSelf?.arkController?.destroyDetectionImage(imageName, completion: completion)
        }

        webController?.onCreateDetectionImage = { dictionary, completion in
            blockSelf?.arkController?.createDetectionImage(dictionary, completion: completion)
        }

        webController?.onSwitchCameraButtonTapped = {
//            let numberOfImages = blockSelf?.stateController.state.numberOfTrackedImages ?? 0
//            blockSelf?.arkController?.switchCameraButtonTapped(numberOfImages)
            guard let state = blockSelf?.stateController.state else { return }
            blockSelf?.arkController?.switchCameraButtonTapped(state)
        }

        if stateController.wasMemoryWarning() {
            stateController.applyOnDidReceiveMemoryAction()
        } else {
            let requestedURL = UserDefaults.standard.string(forKey: REQUESTED_URL_KEY)
            if requestedURL != nil && requestedURL != "" {
                UserDefaults.standard.set(nil, forKey: REQUESTED_URL_KEY)
                webController?.loadURL(requestedURL)
            } else {
                let lastURL = UserDefaults.standard.string(forKey: LAST_URL_KEY)
                if lastURL != nil {
                    webController?.loadURL(lastURL)
                } else {
                    let homeURL = UserDefaults.standard.string(forKey: Constant.homeURLKey())
                    if homeURL != nil && homeURL != "" {
                        webController?.loadURL(homeURL)
                    } else {
                        webController?.loadURL(WEB_URL)
                    }
                }
            }
        }
    }
    
    // MARK: Setup Overlay Controller
    
//    func setupOverlayController() {
//        CLEAN_VIEW(v: hotLayerView)
//
//        weak var blockSelf: Tab? = self
//
//        let debugAction: HotAction = { any in
//            blockSelf?.stateController.invertDebugMode()
//        }
//
//        browserViewController?.webViewContainer.processTouchInSubview = true
//
//        self.overlayController = UIOverlayController(rootView: browserViewController?.webViewContainer ?? UIView(), debugAction: debugAction)
//
//        overlayController?.animator = animator
//
//        overlayController?.setMode(stateController.state.showMode)
//        overlayController?.setOptions(stateController.state.showOptions)
//    }
    
    // MARK: - Setup ARK Controller
    
    func setupARKController() {
//        CLEAN_VIEW(v: arkLayerView)

        weak var blockSelf: Tab? = self

        guard let webView = webView else {
            print("Unable to grab tab webView")
            return
        }
//        arkController = ARKController(type: UserDefaults.standard.bool(forKey: Constant.useMetalForARKey()) ? .arkMetal : .arkSceneKit, rootView: self.view)
        arkController = ARKController(type: .arkMetal, rootView: browserViewController?.webViewContainer ?? UIView())

        arkController?.didUpdate = {
            guard let shouldSendNativeTime = blockSelf?.stateController.shouldSendNativeTime() else { return }
            guard let shouldSendARKData = blockSelf?.stateController.shouldSendARKData() else { return }
            guard let shouldSendCVData = blockSelf?.stateController.shouldSendCVData() else { return }
            
            if shouldSendNativeTime {
                blockSelf?.sendNativeTime()
                var numberOfTimesSendNativeTimeWasCalled = blockSelf?.stateController.state.numberOfTimesSendNativeTimeWasCalled
                numberOfTimesSendNativeTimeWasCalled = (numberOfTimesSendNativeTimeWasCalled ?? 0) + 1
                blockSelf?.stateController.state.numberOfTimesSendNativeTimeWasCalled = numberOfTimesSendNativeTimeWasCalled ?? 1
            }

            if shouldSendARKData {
                blockSelf?.sendARKData()
            }

            if shouldSendCVData {
                if blockSelf?.sendComputerVisionData() ?? false {
                    blockSelf?.stateController.state.computerVisionFrameRequested = false
                    blockSelf?.arkController?.computerVisionFrameRequested = false
                }
            }
        }
        arkController?.didChangeTrackingState = { camera in
            
            if let camera = camera,
                let webXR = blockSelf?.stateController.state.webXR,
                webXR
            {
//                blockSelf?.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
//                blockSelf?.updateTrackingStatusIcon(for: camera.trackingState)
//                switch camera.trackingState {
//                case .notAvailable:
//                    return
//                case .limited:
//                    blockSelf?.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
//                case .normal:
//                    blockSelf?.cancelScheduledMessage(forType: .trackingStateEscalation)
//                }
            }
        }
        arkController?.sessionWasInterrupted = {
//            blockSelf?.overlayController?.setARKitInterruption(true)
            blockSelf?.messageController?.showMessageAboutARInterruption(true)
            blockSelf?.webController?.wasARInterruption(true)
        }
        arkController?.sessionInterruptionEnded = {
//            blockSelf?.overlayController?.setARKitInterruption(false)
            blockSelf?.messageController?.showMessageAboutARInterruption(false)
            blockSelf?.webController?.wasARInterruption(false)
        }
        arkController?.didFailSession = { error in
            guard let error = error as NSError? else { return }
            blockSelf?.arkController?.arSessionState = .arkSessionUnknown
            blockSelf?.webController?.didReceiveError(error: error)

            if error.code == SENSOR_FAILED_ARKIT_ERROR_CODE {
                var currentARRequest = blockSelf?.stateController.state.aRRequest
                if currentARRequest?[WEB_AR_WORLD_ALIGNMENT] as? Bool ?? false {
                    // The session failed because the compass (heading) couldn't be initialized. Fallback the session to ARWorldAlignmentGravity
                    currentARRequest?[WEB_AR_WORLD_ALIGNMENT] = false
                    blockSelf?.stateController.setARRequest(currentARRequest ?? [:]) { () -> () in
                        return
                    }
                }
            }

            var errorMessage = "ARKit Error"
            switch error.code {
                case Int(CAMERA_ACCESS_NOT_AUTHORIZED_ARKIT_ERROR_CODE):
                    // If there is a camera access error, do nothing
                    return
                case Int(UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_CODE):
                    errorMessage = UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_MESSAGE
                case Int(SENSOR_UNAVAILABLE_ARKIT_ERROR_CODE):
                    errorMessage = SENSOR_UNAVAILABLE_ARKIT_ERROR_MESSAGE
                case Int(SENSOR_FAILED_ARKIT_ERROR_CODE):
                    errorMessage = SENSOR_FAILED_ARKIT_ERROR_MESSAGE
                case Int(WORLD_TRACKING_FAILED_ARKIT_ERROR_CODE):
                    errorMessage = WORLD_TRACKING_FAILED_ARKIT_ERROR_MESSAGE
                default:
                    break
            }

            DispatchQueue.main.async(execute: {
                blockSelf?.messageController?.hideMessages()
                blockSelf?.messageController?.showMessageAboutFailSession(withMessage: errorMessage) {
                    DispatchQueue.main.async(execute: {
                        self.webController?.prefillLastURL()
                    })
                }
            })
        }

        arkController?.didUpdateWindowSize = {
            blockSelf?.webController?.updateWindowSize()
        }

//        animator?.animate(browserViewController?.webViewContainer, toFade: false)

        arkController?.startSession(with: stateController.state)
        
        if arkController?.usingMetal ?? false {
            arkController?.controller.renderer.rendererShouldUpdateFrame = { block in
                if let frame = blockSelf?.arkController?.session.currentFrame {
                    blockSelf?.arkController?.controller.readyToRenderFrame = false
                    blockSelf?.savedRender = block
                    blockSelf?.arkController?.updateARKData(with: frame)
                    blockSelf?.arkController?.didUpdate?()
                } else {
                    print("Unable to updateARKData since ARFrame isn't ready")
                    block()
                }
            }
        }

        // Log event when we start an AR session
//        AnalyticsManager.sharedInstance.sendEvent(category: .action, method: .webXR, object: .initialize)
    }
    
    func handleOnWatchAR(withRequest request: [AnyHashable : Any], initialLoad: Bool, grantedPermissionsBlock: ResultBlock?) {
        weak var blockSelf: Tab? = self

        if initialLoad {
            arkController?.computerVisionDataEnabled = false
            stateController.state.userGrantedSendingComputerVisionData = false
            stateController.state.userGrantedSendingWorldStateData = .notDetermined
            stateController.state.sendComputerVisionData = false
            stateController.state.askedComputerVisionData = false
            stateController.state.askedWorldStateData = false
        }
        
        guard let url = webController?.webView?.url else {
            grantedPermissionsBlock?([ "error" : "no web page loaded, should not happen"])
            return
        }
        arkController?.controller.previewingSinglePlane = false
        if let arController = arkController?.controller as? ARKMetalController {
            arController.focusedPlane = nil
        }
//        else if let arController = arkController?.controller as? ARKSceneKitController {
//            arController.focusedPlane = nil
//        }
//        chooseSinglePlaneButton.isHidden = true

        stateController.state.numberOfTimesSendNativeTimeWasCalled = 0
        stateController.setARRequest(request) { () -> () in
            if request[WEB_AR_CV_INFORMATION_OPTION] as? Bool ?? false {
                blockSelf?.messageController?.showMessageAboutEnteringXR(.videoCameraAccess, authorizationGranted: { access in
                    
                    blockSelf?.arkController?.geometryArrays = blockSelf?.stateController.state.geometryArrays ?? false
                    blockSelf?.stateController.state.askedComputerVisionData = true
                    blockSelf?.stateController.state.askedWorldStateData = true
                    let grantedCameraAccess = access == .videoCameraAccess ? true : false
                    let grantedWorldAccess = (access == .videoCameraAccess || access == .worldSensing || access == .lite) ? true : false
                    
                    blockSelf?.arkController?.computerVisionDataEnabled = grantedCameraAccess
                    
                    // Approving computer vision data implicitly approves the world sensing data
                    blockSelf?.arkController?.webXRAuthorizationStatus = access
                    
                    blockSelf?.stateController.state.userGrantedSendingComputerVisionData = grantedCameraAccess
                    blockSelf?.stateController.state.userGrantedSendingWorldStateData = access
                    
                    switch access {
                    case .minimal, .lite, .worldSensing, .videoCameraAccess:
                        blockSelf?.stateController.setWebXR(true)
                    default:
                        blockSelf?.stateController.setWebXR(false)
                    }
                    blockSelf?.webController?.userGrantedWebXRAuthorizationState(access)
                    let permissions = [
                        "cameraAccess": grantedCameraAccess,
                        "worldAccess": grantedWorldAccess,
                        "webXRAccess": blockSelf?.stateController.state.webXR ?? false
                    ]
                    grantedPermissionsBlock?(permissions)
                }, url: url)
            } else if request[WEB_AR_WORLD_SENSING_DATA_OPTION] as? Bool ?? false {
                blockSelf?.messageController?.showMessageAboutEnteringXR(.worldSensing, authorizationGranted: { access in
                    
                    blockSelf?.arkController?.geometryArrays = blockSelf?.stateController.state.geometryArrays ?? false
                    blockSelf?.stateController.state.askedWorldStateData = true
                    blockSelf?.arkController?.webXRAuthorizationStatus = access
                    blockSelf?.stateController.state.userGrantedSendingWorldStateData = access
                    let grantedWorldAccess = (access == .worldSensing || access == .lite) ? true : false
                    
                    switch access {
                    case .minimal, .lite, .worldSensing, .videoCameraAccess:
                        blockSelf?.stateController.setWebXR(true)
                    default:
                        blockSelf?.stateController.setWebXR(false)
                    }
                    
                    blockSelf?.webController?.userGrantedWebXRAuthorizationState(access)
                    let permissions = [
                        "cameraAccess": false,
                        "worldAccess": grantedWorldAccess,
                        "webXRAccess": blockSelf?.stateController.state.webXR ?? false
                    ]
                    grantedPermissionsBlock?(permissions)
                    
                    if access == .lite {
                        blockSelf?.arkController?.controller.previewingSinglePlane = true
//                        blockSelf?.chooseSinglePlaneButton.isHidden = false
                        if blockSelf?.stateController.state.shouldShowLiteModePopup ?? false {
                            blockSelf?.stateController.state.shouldShowLiteModePopup = false
                            blockSelf?.messageController?.showMessage(withTitle: "Lite Mode Started", message: "Choose one plane to share with this website.", hideAfter: 2)
                        }
                    }
                }, url: url)
            } else {
                // if neither is requested, we'll request .minimal WebXR authorization!
                blockSelf?.messageController?.showMessageAboutEnteringXR(.minimal, authorizationGranted: { access in
                    
                    blockSelf?.arkController?.geometryArrays = blockSelf?.stateController.state.geometryArrays ?? false
                    blockSelf?.arkController?.webXRAuthorizationStatus = access
                    
                    switch access {
                    case .minimal, .lite, .worldSensing, .videoCameraAccess:
                        blockSelf?.stateController.setWebXR(true)
                    case .denied, .notDetermined:
                        blockSelf?.stateController.setWebXR(false)
                    }
                    
                    blockSelf?.webController?.userGrantedWebXRAuthorizationState(access)
                    let permissions = [
                        "cameraAccess": false,
                        "worldAccess": false,
                        "webXRAccess": blockSelf?.stateController.state.webXR ?? false
                    ]
                    grantedPermissionsBlock?(permissions)
                    
                    if access == .lite {
                        blockSelf?.arkController?.controller.previewingSinglePlane = true
//                        blockSelf?.chooseSinglePlaneButton.isHidden = false
                        if blockSelf?.stateController.state.shouldShowLiteModePopup ?? false {
                            blockSelf?.stateController.state.shouldShowLiteModePopup = false
                            blockSelf?.messageController?.showMessage(withTitle: "Lite Mode Started", message: "Choose one plane to share with this website.", hideAfter: 2)
                        }
                    }
                }, url: url)
            }
        }
    }
    
    func commonData() -> [AnyHashable : Any] {
        var dictionary = [AnyHashable : Any]()

        if let aData = arkController?.getARKData() {
            dictionary = aData
        }

        return dictionary
//        return arkController?.getARKData() ?? [:]
    }
    
    func loadURL(_ url: String?) {
        if url == nil {
            webController?.reload()
        } else {
            webController?.loadURL(url)
        }

        stateController.setWebXR(false)
    }
    
    func urlIsNotTheLastXRVisitedURL() -> Bool {
        return !(webController?.webView?.url?.absoluteString == webController?.lastXRVisitedURL)
    }
    
    func startNewARKitSession(withRequest request: [AnyHashable : Any]?) {
//        setupLocationController()
//        locationManager?.setup(forRequest: request)
        setupARKController()
    }
    
    func sendNativeTime() {
        guard let currentFrame = arkController?.currentFrameTimeInMilliseconds() else { return }
        webController?.sendNativeTime(currentFrame)
    }
    
    func sendComputerVisionData() -> Bool {
        if let data = arkController?.getComputerVisionData() {
            webController?.sendComputerVisionData(data)
            return true
        }
        return false
    }
    
    func sendARKData() {
        webController?.sendARData(arkController?.getARKData() ?? [:])
    }
    
    private func showOptionsFormDict(dict: [AnyHashable : Any]?) -> ShowOptions {
        if dict == nil {
            return .browser
        }
        
        var options: ShowOptions = .init(rawValue: 0)
        
        if (dict?[WEB_AR_UI_BROWSER_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .browser]
        }
        
        if (dict?[WEB_AR_UI_POINTS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arPoints]
        }
        
        if (dict?[WEB_AR_UI_DEBUG_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .debug]
        }
        
        if (dict?[WEB_AR_UI_STATISTICS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arStatistics]
        }
        
        if (dict?[WEB_AR_UI_FOCUS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arFocus]
        }
        
        if (dict?[WEB_AR_UI_BUILD_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .buildNumber]
        }
        
        if (dict?[WEB_AR_UI_PLANE_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arPlanes]
        }
        
        if (dict?[WEB_AR_UI_WARNINGS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arWarnings]
        }
        
        if (dict?[WEB_AR_UI_ANCHORS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arObject]
        }
        
        return options
    }
    
    func updateConstraints() {
//        guard let barViewHeight = webController?.barViewHeightAnchorConstraint else { return }
        guard let webViewTop = webController?.webViewTopAnchorConstraint else { return }
        guard let webViewLeft = webController?.webViewLeftAnchorConstraint else { return }
        guard let webViewRight = webController?.webViewRightAnchorConstraint else { return }
        let webXR = stateController.state.webXR
        // If XR is active, then the top anchor is 0 (fullscreen), else topSafeAreaInset + Constant.urlBarHeight()
        let topSafeAreaInset = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0.0
//        barViewHeight.constant = topSafeAreaInset + Constant.urlBarHeight()
        webViewTop.constant = webXR ? 0.0 : topSafeAreaInset + Constant.urlBarHeight()

        webViewLeft.constant = 0.0
        webViewRight.constant = 0.0
        if !stateController.state.webXR {
            let currentOrientation: UIInterfaceOrientation = Utils.getInterfaceOrientationFromDeviceOrientation()
            if currentOrientation == .landscapeLeft {
                // The notch is to the right
                let rightSafeAreaInset = UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0.0
                webViewRight.constant = webXR ? 0.0 : -rightSafeAreaInset
            } else if currentOrientation == .landscapeRight {
                // The notch is to the left
                let leftSafeAreaInset = CGFloat(UIApplication.shared.keyWindow?.safeAreaInsets.left ?? 0.0)
                webViewLeft.constant = leftSafeAreaInset
            }
        }

        webView?.setNeedsLayout()
        webView?.layoutIfNeeded()
    }
}

extension Tab: TabWebViewDelegate {
    fileprivate func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String) {
        tabDelegate?.tab(self, didSelectFindInPageForSelection: selection)
    }
    fileprivate func tabWebViewSearchWithFirefox(_ tabWebViewSearchWithFirefox: TabWebView, didSelectSearchWithFirefoxForSelection selection: String) {
        tabDelegate?.tab(self, didSelectSearchWithFirefoxForSelection: selection)
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
            if let name = helper.value.scriptMessageHandlerName() {
                tab.webView?.configuration.userContentController.removeScriptMessageHandler(forName: name)
            }
        }
    }

    @objc func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        for helper in helpers.values {
            if let scriptMessageHandlerName = helper.scriptMessageHandlerName(), scriptMessageHandlerName == message.name {
                helper.userContentController(userContentController, didReceiveScriptMessage: message)
                return
            }
        }
    }

    func addContentScript(_ helper: TabContentScript, name: String, forTab tab: Tab) {
        if let _ = helpers[name] {
            assertionFailure("Duplicate helper added: \(name)")
        }

        helpers[name] = helper

        // If this helper handles script messages, then get the handler name and register it. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
            tab.webView?.configuration.userContentController.add(self, name: scriptMessageHandlerName)
        }
    }

    func getContentScript(_ name: String) -> TabContentScript? {
        return helpers[name]
    }
}

private protocol TabWebViewDelegate: AnyObject {
    func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String)
    func tabWebViewSearchWithFirefox(_ tabWebViewSearchWithFirefox: TabWebView, didSelectSearchWithFirefoxForSelection selection: String)
}

class TabWebView: WKWebView, MenuHelperInterface {
    fileprivate weak var delegate: TabWebViewDelegate?

    // Updates the `background-color` of the webview to match
    // the theme if the webview is showing "about:blank" (nil).
    func applyTheme() {
        if url == nil {
            let backgroundColor = ThemeManager.instance.current.browser.background.hexString
            evaluateJavaScript("document.documentElement.style.backgroundColor = '\(backgroundColor)';")
        }
        window?.backgroundColor = UIColor.theme.browser.background
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender) || action == MenuHelper.SelectorFindInPage
    }

    @objc func menuHelperFindInPage() {
        evaluateJavaScript("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
        }
    }

    @objc func menuHelperSearchWithFirefox() {
        evaluateJavaScript("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebViewSearchWithFirefox(self, didSelectSearchWithFirefoxForSelection: selection)
        }
    }

    internal override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        becomeFirstResponder()

        return super.hitTest(point, with: event)
    }
}

///
// Temporary fix for Bug 1390871 - NSInvalidArgumentException: -[WKContentView menuHelperFindInPage]: unrecognized selector
//
// This class only exists to contain the swizzledMenuHelperFindInPage. This class is actually never
// instantiated. It only serves as a placeholder for the method. When the method is called, self is
// actually pointing to a WKContentView. Which is not public, but that is fine, we only need to know
// that it is a UIView subclass to access its superview.
//

class TabWebViewMenuHelper: UIView {
    @objc func swizzledMenuHelperFindInPage() {
        if let tabWebView = superview?.superview as? TabWebView {
            tabWebView.evaluateJavaScript("getSelection().toString()") { result, _ in
                let selection = result as? String ?? ""
                tabWebView.delegate?.tabWebView(tabWebView, didSelectFindInPageForSelection: selection)
            }
        }
    }
}
