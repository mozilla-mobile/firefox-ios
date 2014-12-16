/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class Browser {
    private let webView = WKWebView()
    private let webViewObserver = WebViewObserver()

    var view: UIView {
        return webView
    }
    
    var didLoadCallBack: ((tab: Browser) -> ())? {
        didSet {
            if let callback = self.didLoadCallBack {
                self.webViewObserver.didLoadCallback = { callback(tab: self) }
            }
        }
    }
    
    init() {
        webView.allowsBackForwardNavigationGestures = true
        webViewObserver.startObservingWebView(webView)
    }

    var url: String? {
        return webView.URL?.absoluteString
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

    func loadRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }
}

private class WebViewObserver : NSObject {
    typealias KVOContext = UInt8
    private var ThisKVOContext = KVOContext()
    
    var didLoadCallback: (() -> ())?
    
    func startObservingWebView(webView: WKWebView) {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.New, context: &ThisKVOContext)
    }
    
    func stopObservingWebView(webView: WKWebView) {
        webView.removeObserver(self, forKeyPath: "estimatedProgress", context: &ThisKVOContext)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch (keyPath, context) {
        case ("estimatedProgress", &ThisKVOContext):
            println("Estimated Progress: \(change)")
            let propChange = change["new"] as Float
            if propChange >= 1.0 {
                if let callback = self.didLoadCallback {
                    callback()
                }
            }
        default:
            println("Uknown Key: \(keyPath)")
        }
    }
}
