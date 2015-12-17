/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

class WebViewPanel: UIViewController, HomePanel {

    weak var homePanelDelegate: HomePanelDelegate?

    private let url: NSURL

    private lazy var webView: WKWebView = {
        return WKWebView()
    }()

    init(url: String) {
        self.url = url.asURL!
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.snp_makeConstraints { make in
            make.edges.equalTo(view)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }
}
