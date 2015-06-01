/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

protocol BrowserHelper {
    static func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

@objc
protocol BrowserDelegate {
    func browser(browser: Browser, didAddSnackbar bar: SnackBar)
    func browser(browser: Browser, didRemoveSnackbar bar: SnackBar)
    optional func browser(browser: Browser, didCreateWebView webView: WKWebView)
    optional func browser(browser: Browser, willDeleteWebView webView: WKWebView)
}

class Browser: NSObject {
    var webView: WKWebView? = nil

    var browserDelegate: BrowserDelegate? = nil
    var bars = [SnackBar]()
    var favicons = [Favicon]()

    var screenshot: UIImage?
    private var helperManager: HelperManager? = nil
    var lastRequest: NSURLRequest? = nil
    private var configuration: WKWebViewConfiguration? = nil

    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration
    }

    class func toTab(browser: Browser) -> RemoteTab? {
        if let displayURL = browser.displayURL {
            return RemoteTab(clientGUID: nil,
                URL: displayURL,
                title: browser.displayTitle,
                history: browser.historyList,
                lastUsed: Timestamp(),
                icon: nil)
        } else {
            return nil
        }
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
            let webView = WKWebView(frame: CGRectZero, configuration: configuration!)
            configuration = nil

            webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webView.allowsBackForwardNavigationGestures = true
            webView.backgroundColor = UIColor.lightGrayColor()
            webView.scrollView.layer.masksToBounds = false

            // Turning off masking allows the web content to flow outside of the scrollView's frame
            // which allows the content appear beneath the toolbars in the BrowserViewController
            webView.scrollView.layer.masksToBounds = false
            webView.navigationDelegate = navigationDelegate
            helperManager = HelperManager(webView: webView)

            if let request = lastRequest {
                webView.loadRequest(request)
            }

            self.webView = webView
            browserDelegate?.browser?(self, didCreateWebView: webView)
        }
    }

    deinit {
        if let webView = webView {
            browserDelegate?.browser?(self, willDeleteWebView: webView)
        }
    }

    var loading: Bool {
        return webView?.loading ?? false
    }

    var estimatedProgress: Double {
        return webView?.estimatedProgress ?? 0
    }

    var backList: [WKBackForwardListItem]? {
        return webView?.backForwardList.backList as? [WKBackForwardListItem]
    }

    var forwardList: [WKBackForwardListItem]? {
        return webView?.backForwardList.forwardList as? [WKBackForwardListItem]
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
        return displayURL?.absoluteString ?? ""
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
        return webView?.URL ?? lastRequest?.URL
    }

    var displayURL: NSURL? {
        if let url = webView?.URL ?? lastRequest?.URL {
            if url.scheme != "about" {
                if ReaderModeUtils.isReaderModeURL(url) {
                    return ReaderModeUtils.decodeURL(url)
                }

                if ErrorPageHelper.isErrorPageURL(url) {
                    return ErrorPageHelper.decodeURL(url)
                }

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
        lastRequest = request
        if let webView = webView {
            return webView.loadRequest(request)
        }
        return nil
    }

    func stop() {
        webView?.stopLoading()
    }

    func reload() {
        webView?.reload()
    }

    func addHelper(helper: BrowserHelper, name: String) {
        helperManager!.addHelper(helper, name: name)
    }

    func getHelper(#name: String) -> BrowserHelper? {
        return helperManager!.getHelper(name: name)
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
        browserDelegate?.browser(self, didAddSnackbar: bar)
    }

    func removeSnackbar(bar: SnackBar) {
        if let index = find(bars, bar) {
            bars.removeAtIndex(index)
            browserDelegate?.browser(self, didRemoveSnackbar: bar)
        }
    }

    func removeAllSnackbars() {
        // Enumerate backwards here because we'll remove items from the list as we go.
        for var i = bars.count-1; i >= 0; i-- {
            let bar = bars[i]
            removeSnackbar(bar)
        }
    }

    func expireSnackbars() {
        // Enumerate backwards here because we may remove items from the list as we go.
        for var i = bars.count-1; i >= 0; i-- {
            let bar = bars[i]
            if !bar.shouldPersist(self) {
                removeSnackbar(bar)
            }
        }
    }
}

private class HelperManager: NSObject, WKScriptMessageHandler {
    private var helpers = [String: BrowserHelper]()
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

    func addHelper(helper: BrowserHelper, name: String) {
        if let existingHelper = helpers[name] {
            assertionFailure("Duplicate helper added: \(name)")
        }

        helpers[name] = helper

        // If this helper handles script messages, then get the handler name and register it. The Browser
        // receives all messages and then dispatches them to the right BrowserHelper.
        if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
            webView?.configuration.userContentController.addScriptMessageHandler(self, name: scriptMessageHandlerName)
        }
    }

    func getHelper(#name: String) -> BrowserHelper? {
        return helpers[name]
    }
}

extension WKWebView {
    func runScriptFunction(function: String, fromScript: String, callback: (AnyObject?) -> Void) {
        if let path = NSBundle.mainBundle().pathForResource(fromScript, ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as? String {
                evaluateJavaScript(source, completionHandler: { (obj, err) -> Void in
                    if let err = err {
                        println("Error injecting \(err)")
                        return
                    }

                    self.evaluateJavaScript("__firefox__.\(fromScript).\(function)", completionHandler: { (obj, err) -> Void in
                        self.evaluateJavaScript("delete window.__firefox__.\(fromScript)", completionHandler: { (obj, err) -> Void in })
                        if let err = err {
                            println("Error running \(err)")
                            return
                        }
                        callback(obj)
                    })
                })
            }
        }
    }
}
