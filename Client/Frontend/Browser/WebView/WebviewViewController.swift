// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

class WebviewViewController: UIViewController, ContentContainable {
    private let webView: WKWebView
    var contentType: ContentType = .webview

    init(webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

    private func setupLayout() {
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: webView.topAnchor),
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
    }
}
