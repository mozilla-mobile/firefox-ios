/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class Browser {
    private let webView = WKWebView()

    var view: UIView {
        return webView
    }
    
    init() {
        webView.allowsBackForwardNavigationGestures = true
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
