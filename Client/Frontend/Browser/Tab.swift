/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

import XCGLogger

private let log = Logger.browserLogger

protocol TabHelper {
    static func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

@objc
protocol TabDelegate {
    func tab(tab: Tab, didAddSnackbar bar: SnackBar)
    func tab(tab: Tab, didRemoveSnackbar bar: SnackBar)
    func tab(tab: Tab, didSelectFindInPageForSelection selection: String)
    optional func tab(tab: Tab, didCreateWebView webView: WKWebView)
    optional func tab(tab: Tab, willDeleteWebView webView: WKWebView)
}

struct TabState {
    var isPrivate: Bool = false
    var desktopSite: Bool = false
    var isBookmarked: Bool = false
    var url: NSURL?
}

class Tab: NSObject {
    private var _isPrivate: Bool = false
    internal private(set) var isPrivate: Bool {
        get {
            if #available(iOS 9, *) {
                return _isPrivate
            } else {
                return false
            }
        }
        set {
            _isPrivate = newValue
        }
    }

    var tabState: TabState {
        return TabState(isPrivate: _isPrivate, desktopSite: desktopSite, isBookmarked: isBookmarked, url: url)
    }

    var webView: WKWebView? = nil
    var tabDelegate: TabDelegate? = nil
    weak var appStateDelegate: AppStateDelegate?
    var bars = [SnackBar]()
    var favicons = [Favicon]()
    var lastExecutedTime: Timestamp?
    var sessionData: SessionData?
    var lastRequest: NSURLRequest? = nil
    var restoring: Bool = false
    var pendingScreenshot = false

    /// The last title shown by this tab. Used by the tab tray to show titles for zombie tabs.
    var lastTitle: String?

    /// Whether or not the desktop site was requested with the last request, reload or navigation. Note that this property needs to
    /// be managed by the web view's navigation delegate.
    var desktopSite: Bool = false
    var isBookmarked: Bool = false

    private(set) var screenshot: UIImage?
    var screenshotUUID: NSUUID?

    private var helperManager: HelperManager? = nil
    private var configuration: WKWebViewConfiguration? = nil

    /// Any time a tab tries to make requests to display a Javascript Alert and we are not the active
    /// tab instance, queue it for later until we become foregrounded.
    private var alertQueue = [JSAlertInfo]()

    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration
    }

    @available(iOS 9, *)
    init(configuration: WKWebViewConfiguration, isPrivate: Bool) {
        self.configuration = configuration
        super.init()
        self.isPrivate = isPrivate
    }

    class func toTab(tab: Tab) -> RemoteTab? {
        if let displayURL = tab.displayURL where RemoteTab.shouldIncludeURL(displayURL) {
            let history = Array(tab.historyList.filter(RemoteTab.shouldIncludeURL).reverse())
            return RemoteTab(clientGUID: nil,
                URL: displayURL,
                title: tab.displayTitle,
                history: history,
                lastUsed: NSDate.now(),
                icon: nil)
        } else if let sessionData = tab.sessionData where !sessionData.urls.isEmpty {
            let history = Array(sessionData.urls.filter(RemoteTab.shouldIncludeURL).reverse())
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
            assert(configuration != nil, "Create webview can only be called once")
            configuration!.userContentController = WKUserContentController()
            configuration!.preferences = WKPreferences()
            configuration!.preferences.javaScriptCanOpenWindowsAutomatically = false
            let webView = TabWebView(frame: CGRectZero, configuration: configuration!)
            webView.delegate = self
            configuration = nil

            webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webView.allowsBackForwardNavigationGestures = true
            webView.backgroundColor = UIColor.lightGrayColor()

            // Turning off masking allows the web content to flow outside of the scrollView's frame
            // which allows the content appear beneath the toolbars in the BrowserViewController
            webView.scrollView.layer.masksToBounds = false
            webView.navigationDelegate = navigationDelegate
            helperManager = HelperManager(webView: webView)

            restore(webView)

            self.webView = webView
            tabDelegate?.tab?(self, didCreateWebView: webView)
        }
    }

    func restore(webView: WKWebView) {
        // Pulls restored session data from a previous SavedTab to load into the Browser. If it's nil, a session restore
        // has already been triggered via custom URL, so we use the last request to trigger it again; otherwise,
        // we extract the information needed to restore the tabs and create a NSURLRequest with the custom session restore URL
        // to trigger the session restore via custom handlers
        if let sessionData = self.sessionData {
            restoring = true

            var updatedURLs = [String]()
            for url in sessionData.urls {
                let updatedURL = WebServer.sharedInstance.updateLocalURL(url)!.absoluteString
                updatedURLs.append(updatedURL)
            }
            let currentPage = sessionData.currentPage
            self.sessionData = nil
            var jsonDict = [String: AnyObject]()
            jsonDict["history"] = updatedURLs
            jsonDict["currentPage"] = currentPage
            let escapedJSON = JSON.stringify(jsonDict, pretty: false).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            let restoreURL = NSURL(string: "\(WebServer.sharedInstance.base)/about/sessionrestore?history=\(escapedJSON)")
            lastRequest = NSURLRequest(URL: restoreURL!)
            webView.loadRequest(lastRequest!)
        } else if let request = lastRequest {
            webView.loadRequest(request)
        } else {
            log.error("creating webview with no lastRequest and no session data: \(self.url)")
        }
    }

    deinit {
        if let webView = webView {
            tabDelegate?.tab?(self, willDeleteWebView: webView)
        }
    }

    var loading: Bool {
        return webView?.loading ?? false
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

    var historyList: [NSURL] {
        func listToUrl(item: WKBackForwardListItem) -> NSURL { return item.URL }
        var tabs = self.backList?.map(listToUrl) ?? [NSURL]()
        tabs.append(self.url!)
        return tabs
    }

    var title: String? {
        return webView?.title
    }

    var displayTitle: String {
        if let title = webView?.title {
            if !title.isEmpty {
                return title
            }
        }

        guard let lastTitle = lastTitle where !lastTitle.isEmpty else {
            return displayURL?.absoluteString ??  ""
        }

        return lastTitle
    }

    var currentInitialURL: NSURL? {
        get {
            let initalURL = self.webView?.backForwardList.currentItem?.initialURL
            return initalURL
        }
    }

    var displayFavicon: Favicon? {
        var width = 0
        var largest: Favicon?
        for icon in favicons {
            if icon.width > width {
                width = icon.width!
                largest = icon
            }
        }
        return largest
    }

    var url: NSURL? {
        guard let resolvedURL = webView?.URL ?? lastRequest?.URL else {
            guard let sessionData = sessionData else { return nil }
            return sessionData.urls.last
        }
        return resolvedURL
    }

    var displayURL: NSURL? {
        if let url = url {
            if ReaderModeUtils.isReaderModeURL(url) {
                return ReaderModeUtils.decodeURL(url)
            }

            if ErrorPageHelper.isErrorPageURL(url) {
                let decodedURL = ErrorPageHelper.decodeURL(url)
                if !AboutUtils.isAboutURL(decodedURL) {
                    return decodedURL
                } else {
                    return nil
                }
            }

            if let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) where (urlComponents.user != nil) || (urlComponents.password != nil) {
                urlComponents.user = nil
                urlComponents.password = nil
                return urlComponents.URL
            }


            if !AboutUtils.isAboutURL(url) {
                return url
            }
        }
        return nil
    }

    var canGoBack: Bool {
        return webView?.canGoBack ?? false
    }

    var canGoForward: Bool {
        return webView?.canGoForward ?? false
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func goToBackForwardListItem(item: WKBackForwardListItem) {
        webView?.goToBackForwardListItem(item)
    }

    func loadRequest(request: NSURLRequest) -> WKNavigation? {
        if let webView = webView {
            lastRequest = request
            return webView.loadRequest(request)
        }
        return nil
    }

    func stop() {
        webView?.stopLoading()
    }

    func reload() {
        if #available(iOS 9.0, *) {
            let userAgent: String? = desktopSite ? UserAgent.desktopUserAgent() : nil
            if (userAgent ?? "") != webView?.customUserAgent,
               let currentItem = webView?.backForwardList.currentItem
            {
                webView?.customUserAgent = userAgent

                // Reload the initial URL to avoid UA specific redirection
                loadRequest(NSURLRequest(URL: currentItem.initialURL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 60))
                return
            }
        }

        if let _ = webView?.reloadFromOrigin() {
            log.info("reloaded zombified tab from origin")
            return
        }

        if let webView = self.webView {
            log.info("restoring webView from scratch")
            restore(webView)
        }
    }

    func addHelper(helper: TabHelper, name: String) {
        helperManager!.addHelper(helper, name: name)
    }

    func getHelper(name name: String) -> TabHelper? {
        return helperManager?.getHelper(name: name)
    }

    func hideContent(animated: Bool = false) {
        webView?.userInteractionEnabled = false
        if animated {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.webView?.alpha = 0.0
            })
        } else {
            webView?.alpha = 0.0
        }
    }

    func showContent(animated: Bool = false) {
        webView?.userInteractionEnabled = true
        if animated {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.webView?.alpha = 1.0
            })
        } else {
            webView?.alpha = 1.0
        }
    }

    func addSnackbar(bar: SnackBar) {
        bars.append(bar)
        tabDelegate?.tab(self, didAddSnackbar: bar)
    }

    func removeSnackbar(bar: SnackBar) {
        if let index = bars.indexOf(bar) {
            bars.removeAtIndex(index)
            tabDelegate?.tab(self, didRemoveSnackbar: bar)
        }
    }

    func removeAllSnackbars() {
        // Enumerate backwards here because we'll remove items from the list as we go.
        for i in (0..<bars.count).reverse() {
            let bar = bars[i]
            removeSnackbar(bar)
        }
    }

    func expireSnackbars() {
        // Enumerate backwards here because we may remove items from the list as we go.
        for i in (0..<bars.count).reverse() {
            let bar = bars[i]
            if !bar.shouldPersist(self) {
                removeSnackbar(bar)
            }
        }
    }

    func setScreenshot(screenshot: UIImage?, revUUID: Bool = true) {
        self.screenshot = screenshot
        if revUUID {
            self.screenshotUUID = NSUUID()
        }
    }

    @available(iOS 9, *)
    func toggleDesktopSite() {
        desktopSite = !desktopSite
        reload()
    }

    func queueJavascriptAlertPrompt(alert: JSAlertInfo) {
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
}

extension Tab: TabWebViewDelegate {
    private func tabWebView(tabWebView: TabWebView, didSelectFindInPageForSelection selection: String) {
        tabDelegate?.tab(self, didSelectFindInPageForSelection: selection)
    }
}

private class HelperManager: NSObject, WKScriptMessageHandler {
    private var helpers = [String: TabHelper]()
    private weak var webView: WKWebView?

    init(webView: WKWebView) {
        self.webView = webView
    }

    @objc func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        for helper in helpers.values {
            if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
                if scriptMessageHandlerName == message.name {
                    helper.userContentController(userContentController, didReceiveScriptMessage: message)
                    return
                }
            }
        }
    }

    func addHelper(helper: TabHelper, name: String) {
        if let _ = helpers[name] {
            assertionFailure("Duplicate helper added: \(name)")
        }

        helpers[name] = helper

        // If this helper handles script messages, then get the handler name and register it. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
            webView?.configuration.userContentController.addScriptMessageHandler(self, name: scriptMessageHandlerName)
        }
    }

    func getHelper(name name: String) -> TabHelper? {
        return helpers[name]
    }
}

private protocol TabWebViewDelegate: class {
    func tabWebView(tabWebView: TabWebView, didSelectFindInPageForSelection selection: String)
}

private class TabWebView: WKWebView, MenuHelperInterface {
    private weak var delegate: TabWebViewDelegate?

    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        return action == MenuHelper.SelectorFindInPage
    }

    @objc func menuHelperFindInPage(sender: NSNotification) {
        evaluateJavaScript("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
        }
    }

    private override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        becomeFirstResponder()

        return super.hitTest(point, withEvent: event)
    }
}
