/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class Browser {

    let webView = WKWebView()
    
    private let webViewObserver = WebViewObserver()

    var loadingCallback: ((tab: Browser) -> ())? {
        didSet {
            if let callback = self.loadingCallback {
                self.webViewObserver.loadingCallback = { callback(tab: self) }
            }
        }
    }
    
    init() {
        webView.allowsBackForwardNavigationGestures = true
        webViewObserver.startObservingWebView(webView)
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
    
    var estimatedProgresss: Float {
        return Float(webView.estimatedProgress)
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
}

private class WebViewObserver : NSObject {
    typealias KVOContext = UInt8
    private var ThisKVOContext = KVOContext()
    
    var loadingCallback: (() -> ())?
    
    func startObservingWebView(webView: WKWebView) {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.New, context: &ThisKVOContext)
    }
    
    func stopObservingWebView(webView: WKWebView) {
        webView.removeObserver(self, forKeyPath: "estimatedProgress", context: &ThisKVOContext)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch (keyPath, context) {
        case ("estimatedProgress", &ThisKVOContext):
            let propChange = change["new"] as Double
            println("Estimated Progress: \(propChange)")
            if let callback = self.loadingCallback {
                callback()
            }
        default:
            println("Uknown Key: \(keyPath)")
        }
    }
}
