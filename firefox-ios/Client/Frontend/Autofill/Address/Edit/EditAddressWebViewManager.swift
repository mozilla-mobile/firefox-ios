// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

protocol WebViewPreloadManaging {
    var webView: WKWebView? { get }
    func preloadWebView()
    func teardownWebView()
}

class EditAddressWebViewManager: NSObject, WebViewPreloadManaging, WKScriptMessageHandler {
    private(set) var webView: WKWebView?

    override init() {
        super.init()

        let webConfiguration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "saveEnabled")
        webConfiguration.userContentController = contentController

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

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "saveEnabled",
              let body = message.body as? [String: Any],
              let saveEnabled = body["enabled"] as? Bool else { return }

        NotificationCenter.default.post(name: .addressSettingsSaving, object: nil, userInfo: ["enabled": saveEnabled])
    }
}

extension Notification.Name {
    static let addressSettingsSaving = Notification.Name("addressSettingsSaving")
}
