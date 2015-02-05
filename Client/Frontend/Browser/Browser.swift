/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol BrowserHelper {
    init?(browser: Browser)
    class func name() -> String
    func scriptMessageHandlerName() -> String?
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage)
}

class Browser: NSObject, WKScriptMessageHandler {
    let webView: WKWebView

    init(configuration: WKWebViewConfiguration) {
        configuration.userContentController = WKUserContentController()
        webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")

        super.init()
    }

    var backList: [WKBackForwardListItem]? {
        return webView.backForwardList.backList as? [WKBackForwardListItem]
    }

    var forwardList: [WKBackForwardListItem]? {
        return webView.backForwardList.forwardList as? [WKBackForwardListItem]
    }

    var url: NSURL? {
        return webView.URL?
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
}

extension WKWebView {

    func runScriptFunction(function: String, fromScript: String, callback: (AnyObject?) -> Void) {
        if let path = NSBundle.mainBundle().pathForResource(fromScript, ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
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


