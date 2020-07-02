/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit
import WebKit

class RelayConnectViewController: UIViewController {
//    let webView: WKWebView
    let prefs: Prefs

    private let authUrl = "https://relay.firefox.com/accounts/fxa/login/?process=login"
    private let profileUrl = "https://relay.firefox.com/accounts/profile/"

    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()

        var userController: WKUserContentController = WKUserContentController()
        userController.add(self, name: "relayMessageHandler")
        config.userContentController = userController;

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = UserAgent.mobileUserAgent() // This is not shown full-screen, use mobile UA
        webView.navigationDelegate = self
        webView.uiDelegate = self

        return webView
    }()

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.snp.remakeConstraints { make in
            make.edges.equalTo(self.view)
        }

        if let url = URL(string: authUrl) {
            webView.load(URLRequest(url: url))
        }
    }
}

extension RelayConnectViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.name)
        if let body = message.body as? String {
            print(message.body)
        }
    }
}

extension RelayConnectViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url == URL(string: profileUrl) {
            let js = "document.getElementById('profile-main').getAttribute('data-api-token')"
            webView.evaluateJavaScript(js) { (result, error) in
                if let result = result as? String {
                    self.prefs.setString(result, forKey: "relay-api-key")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

extension RelayConnectViewController: WKUIDelegate {
    
}
