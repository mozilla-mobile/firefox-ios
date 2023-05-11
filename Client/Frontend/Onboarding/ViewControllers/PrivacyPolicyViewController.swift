// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import Common
import Shared

class PrivacyPolicyViewController: UIViewController {
    private var webView: WKWebView!
    private var url: URL

    init(url: URL) {
        self.url = url

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    func setupView() {
        webView = WKWebView(frame: view.frame)
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
        view.backgroundColor = .systemBackground
        view.addSubview(webView)
    }
}

extension PrivacyPolicyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let contentSize = webView.scrollView.contentSize
        let viewSize = self.view.bounds.size
        let zoom = viewSize.width / contentSize.width

        webView.scrollView.minimumZoomScale = zoom * 0.8
        webView.scrollView.maximumZoomScale = zoom * 0.8
        webView.scrollView.zoomScale = zoom * 0.8
    }
}
