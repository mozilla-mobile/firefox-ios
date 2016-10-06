/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit
import WebKit

class AboutContentViewController: UIViewController, WKNavigationDelegate {
    var url: URL!
    fileprivate var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIConstants.colors.background

        webView = WKWebView()
        webView.alpha = 0
        view.addSubview(webView)

        webView.snp.remakeConstraints { make in
            make.edges.equalTo(self.view)
        }

        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillAppear(animated)
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Add a small delay to allow the stylesheets to load and avoid flicker.
        let delayTime = DispatchTime.now() + Double(Int64(200 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            webView.animateHidden(false, duration: 0.3)
        }
    }
}
