/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol BrowserHelper {
    static func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

protocol BrowserDelegate {
    func browser(browser: Browser, didAddSnackbar bar: SnackBar)
    func browser(browser: Browser, didRemoveSnackbar bar: SnackBar)
}

class Browser: NSObject, WKScriptMessageHandler {
    let webView: WKWebView
    var browserDelegate: BrowserDelegate? = nil
    var bars = [SnackBar]()

    init(configuration: WKWebViewConfiguration) {
        configuration.userContentController = WKUserContentController()
        webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
        webView.backgroundColor = UIColor.lightGrayColor()

        super.init()
    }

    var loading: Bool {
        return webView.loading
    }

    var backList: [WKBackForwardListItem]? {
        return webView.backForwardList.backList as? [WKBackForwardListItem]
    }

    var forwardList: [WKBackForwardListItem]? {
        return webView.backForwardList.forwardList as? [WKBackForwardListItem]
    }

    var title: String? {
        return webView.title
    }

    var displayTitle: String {
        if let title = webView.title {
            if !title.isEmpty {
                return title
            }
        }
        return displayURL?.absoluteString ?? ""
    }

    var url: NSURL? {
        return webView.URL
    }

    var displayURL: NSURL? {
        if let url = webView.URL {
            return ReaderModeUtils.isReaderModeURL(url) ? ReaderModeUtils.decodeURL(url) : url
        }
        return nil
    }

    var canGoBack: Bool {
        return webView.canGoBack
    }

    var canGoForward: Bool {
        return webView.canGoForward
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    func goToBackForwardListItem(item: WKBackForwardListItem) {
        webView.goToBackForwardListItem(item)
    }

    func loadRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }

    func stop() {
        webView.stopLoading()
    }

    func reload() {
        webView.reload()
    }

    private var helpers: [String: BrowserHelper] = [String: BrowserHelper]()

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
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
            webView.configuration.userContentController.addScriptMessageHandler(self, name: scriptMessageHandlerName)
        }
    }

    func getHelper(#name: String) -> BrowserHelper? {
        return helpers[name]
    }

    func hideContent(animated: Bool = false) {
        webView.userInteractionEnabled = false
        if animated {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.webView.alpha = 0.0
            })
        } else {
            webView.alpha = 0.0
        }
    }

    func showContent(animated: Bool = false) {
        webView.userInteractionEnabled = true
        if animated {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.webView.alpha = 1.0
            })
        } else {
            webView.alpha = 1.0
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
