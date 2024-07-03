// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

protocol WebViewPreloadManaging {
    var webView: WKWebView? { get }
    func preloadWebView()
    func teardownWebView()
}

class EditAddressWebViewManager: WebViewPreloadManaging {
    private(set) var webView: WKWebView?

    init() {
        let webConfiguration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.webView?.translatesAutoresizingMaskIntoConstraints = false

        #if targetEnvironment(simulator)
        // Allow Safari Web Inspector only when running in simulator.
        // Requires to toggle `show features for web developers` in
        // Safari > Settings > Advanced menu.
        if #available(iOS 16.4, *) {
            self.webView?.isInspectable = true
        }
        #endif
    }

    func preloadWebView() {
        loadLocalFile("AddressFormManager", relativeTo: Bundle.main.bundleURL)
    }

    private func loadLocalFile(_ filePath: String, relativeTo baseURL: URL) {
        if let url = Bundle.main.url(forResource: filePath, withExtension: "html") {
            let request = URLRequest(url: url)
            webView?.loadFileURL(url, allowingReadAccessTo: url)
            webView?.load(request)
        }
    }

    func teardownWebView() {
        webView?.removeFromSuperview()
        webView = nil
    }
}
