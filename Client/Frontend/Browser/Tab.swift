/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared
import SwiftyJSON
import XCGLogger

protocol TabHelper {
    static func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

@objc
protocol TabDelegate {
    func tab(_ tab: Tab, didAddSnackbar bar: SnackBar)
    func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar)
    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String)
    @objc optional func tab(_ tab: Tab, didCreateWebView webView: WKWebView)
    @objc optional func tab(_ tab: Tab, willDeleteWebView webView: WKWebView)
}

struct TabState {
    var isPrivate: Bool = false
    var desktopSite: Bool = false
    var isBookmarked: Bool = false
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
        return TabState(isPrivate: _isPrivate, desktopSite: desktopSite, isBookmarked: isBookmarked, url: url, title: displayTitle, favicon: displayFavicon)
    }

    // PageMetadata is derived from the page content itself, and as such lags behind the
    // rest of the tab.
    var pageMetadata: PageMetadata?

    var canonicalURL: URL? {
        if let string = pageMetadata?.siteURL,
            let siteURL = URL(string: string) {
            return siteURL
        }
        return self.url
    }

    var webView: WKWebView?
    var tabDelegate: TabDelegate?
    var bars = [SnackBar]()
    var favicons = [Favicon]()
    var lastExecutedTime: Timestamp?
    var sessionData: SessionData?
    fileprivate var lastRequest: URLRequest?
    var restoring: Bool = false
    var pendingScreenshot = false
    var url: URL?
    var mimeType: String?

    fileprivate var _noImageMode = false

    /// Returns true if this tab's URL is known, and it's longer than we want to store.
    var urlIsTooLong: Bool {
        guard let url = self.url else {
            return false
        }
        return url.absoluteString.lengthOfBytes(using: String.Encoding.utf8) > AppConstants.DB_URL_LENGTH_MAX
    }

    // Use computed property so @available can be used to guard `noImageMode`.
    @available(iOS 11, *)
    var noImageMode: Bool {
        get { return _noImageMode }
        set {
            if newValue == _noImageMode {
                return
            }
            _noImageMode = newValue
            let helper = (contentBlocker as? ContentBlockerHelper)
            helper?.noImageMode(enabled: _noImageMode)
        }
    }

    // There is no 'available macro' on props, we currently just need to store ownership.
    var contentBlocker: AnyObject?

    /// The last title shown by this tab. Used by the tab tray to show titles for zombie tabs.
    var lastTitle: String?

    /// Whether or not the desktop site was requested with the last request, reload or navigation. Note that this property needs to
    /// be managed by the web view's navigation delegate.
    var desktopSite: Bool = false
    var isBookmarked: Bool = false
    
    var readerModeAvailableOrActive: Bool {
        if let readerMode = self.getHelper(name: "ReaderMode") as? ReaderMode {
            return readerMode.state != .unavailable
        }
        return false
    }

    fileprivate(set) var screenshot: UIImage?
    var screenshotUUID: UUID?

    // If this tab has been opened from another, its parent will point to the tab from which it was opened
    var parent: Tab?

    fileprivate var helperManager: HelperManager?
    fileprivate var configuration: WKWebViewConfiguration?

    /// Any time a tab tries to make requests to display a Javascript Alert and we are not the active
    /// tab instance, queue it for later until we become foregrounded.
    fileprivate var alertQueue = [JSAlertInfo]()

    init(configuration: WKWebViewConfiguration, isPrivate: Bool = false) {
        self.configuration = configuration
        super.init()
        self.isPrivate = isPrivate

        if #available(iOS 11, *) {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile {
                contentBlocker = ContentBlockerHelper(tab: self, profile: profile)
            }
        }
    }

    class func toTab(_ tab: Tab) -> RemoteTab? {
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
            assert(configuration != nil, "Create webview can only be called once")
            configuration!.userContentController = WKUserContentController()
            configuration!.preferences = WKPreferences()
            configuration!.preferences.javaScriptCanOpenWindowsAutomatically = false
            configuration!.allowsInlineMediaPlayback = true
            let webView = TabWebView(frame: CGRect.zero, configuration: configuration!)
            webView.delegate = self
            configuration = nil

            webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webView.allowsBackForwardNavigationGestures = true
            webView.allowsLinkPreview = false
            webView.backgroundColor = UIColor.lightGray

            // Turning off masking allows the web content to flow outside of the scrollView's frame
            // which allows the content appear beneath the toolbars in the BrowserViewController
            webView.scrollView.layer.masksToBounds = false
            webView.navigationDelegate = navigationDelegate
            helperManager = HelperManager(webView: webView)

            restore(webView)

            self.webView = webView
            self.webView?.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
            tabDelegate?.tab?(self, didCreateWebView: webView)
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
            guard let json = JSON(jsonDict).stringValue() else {
                return
            }
            let escapedJSON = json.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let restoreURL = URL(string: "\(WebServer.sharedInstance.base)/about/sessionrestore?history=\(escapedJSON)")
            lastRequest = PrivilegedRequest(url: restoreURL!) as URLRequest
            webView.load(lastRequest!)
        } else if let request = lastRequest {
            webView.load(request)
        } else {
            print("creating webview with no lastRequest and no session data: \(self.url?.description ?? "nil")")
        }
    }

    deinit {
        if let webView = webView {
            tabDelegate?.tab?(self, willDeleteWebView: webView)
            webView.removeObserver(self, forKeyPath: "URL")
        }
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

        // When picking a display title. Tabs with sessionData are pending a restore so show their old title.
        // To prevent flickering of the display title. If a tab is restoring make sure to use its lastTitle.
        if let url = self.url, url.isAboutHomeURL, sessionData == nil, !restoring {
            return ""
        }

        guard let lastTitle = lastTitle, !lastTitle.isEmpty else {
            return self.url?.displayURL?.absoluteString ??  ""
        }

        return lastTitle
    }

    var currentInitialURL: URL? {
        get {
            let initalURL = self.webView?.backForwardList.currentItem?.initialURL
            return initalURL
        }
    }

    var displayFavicon: Favicon? {
        var width = 0
        var largest: Favicon?
        for icon in favicons where icon.width! > width {
            width = icon.width!
            largest = icon
        }
        return largest
    }

    var canGoBack: Bool {
        return webView?.canGoBack ?? false
    }

    var canGoForward: Bool {
        return webView?.canGoForward ?? false
    }

    func goBack() {
        _ = webView?.goBack()
    }

    func goForward() {
        _ = webView?.goForward()
    }

    func goToBackForwardListItem(_ item: WKBackForwardListItem) {
        _ = webView?.go(to: item)
    }

    @discardableResult func loadRequest(_ request: URLRequest) -> WKNavigation? {
        if let webView = webView {
            lastRequest = request
            return webView.load(request)
        }
        return nil
    }

    func stop() {
        webView?.stopLoading()
    }

    func reload() {
        let userAgent: String? = desktopSite ? UserAgent.desktopUserAgent() : nil
        if (userAgent ?? "") != webView?.customUserAgent,
           let currentItem = webView?.backForwardList.currentItem {
            webView?.customUserAgent = userAgent

            // Reload the initial URL to avoid UA specific redirection
            loadRequest(PrivilegedRequest(url: currentItem.initialURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60) as URLRequest)
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

    func addHelper(_ helper: TabHelper, name: String) {
        helperManager!.addHelper(helper, name: name)
    }

    func getHelper(name: String) -> TabHelper? {
        return helperManager?.getHelper(name)
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
        if let index = bars.index(of: bar) {
            bars.remove(at: index)
            tabDelegate?.tab(self, didRemoveSnackbar: bar)
        }
    }

    func removeAllSnackbars() {
        // Enumerate backwards here because we'll remove items from the list as we go.
        for i in (0..<bars.count).reversed() {
            let bar = bars[i]
            removeSnackbar(bar)
        }
    }

    func expireSnackbars() {
        // Enumerate backwards here because we may remove items from the list as we go.
        for i in (0..<bars.count).reversed() {
            let bar = bars[i]
            if !bar.shouldPersist(self) {
                removeSnackbar(bar)
            }
        }
    }

    func setScreenshot(_ screenshot: UIImage?, revUUID: Bool = true) {
        self.screenshot = screenshot
        if revUUID {
            self.screenshotUUID = UUID()
        }
    }

    func toggleDesktopSite() {
        desktopSite = !desktopSite
        reload()
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
            let path = keyPath, path == "URL" else {
            return assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
        }
    }

    func isDescendentOf(_ ancestor: Tab) -> Bool {
        var tab = parent
        while tab != nil {
            if tab! == ancestor {
                return true
            }
            tab = tab?.parent
        }
        return false
    }

    func setNightMode(_ enabled: Bool) {
        webView?.evaluateJavaScript("window.__firefox__.NightMode.setEnabled(\(enabled))", completionHandler: nil)
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
}

extension Tab: TabWebViewDelegate {
    fileprivate func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String) {
        tabDelegate?.tab(self, didSelectFindInPageForSelection: selection)
    }
}

private class HelperManager: NSObject, WKScriptMessageHandler {
    fileprivate var helpers = [String: TabHelper]()
    fileprivate weak var webView: WKWebView?

    init(webView: WKWebView) {
        self.webView = webView
    }

    @objc func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        for helper in helpers.values {
            if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
                if scriptMessageHandlerName == message.name {
                    helper.userContentController(userContentController, didReceiveScriptMessage: message)
                    return
                }
            }
        }
    }

    func addHelper(_ helper: TabHelper, name: String) {
        if let _ = helpers[name] {
            assertionFailure("Duplicate helper added: \(name)")
        }

        helpers[name] = helper

        // If this helper handles script messages, then get the handler name and register it. The Browser
        // receives all messages and then dispatches them to the right TabHelper.
        if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
            webView?.configuration.userContentController.add(self, name: scriptMessageHandlerName)
        }
    }

    func getHelper(_ name: String) -> TabHelper? {
        return helpers[name]
    }
}

private protocol TabWebViewDelegate: class {
    func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String)
}

private class TabWebView: WKWebView, MenuHelperInterface {
    fileprivate weak var delegate: TabWebViewDelegate?

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender) || action == MenuHelper.SelectorFindInPage
    }

    @objc func menuHelperFindInPage() {
        evaluateJavaScript("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
        }
    }

    fileprivate override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
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
