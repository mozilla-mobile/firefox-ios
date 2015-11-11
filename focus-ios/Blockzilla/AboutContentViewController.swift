/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit
import WebKit

class AboutContentViewController: UIViewController, WKNavigationDelegate {
    var url: NSURL!
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIConstants.Colors.Background

        webView = WKWebView()
        webView.alpha = 0
        view.addSubview(webView)

        webView.snp_remakeConstraints { make in
            make.edges.equalTo(self.view)
        }

        webView.navigationDelegate = self
        webView.loadRequest(NSURLRequest(URL: url))
    }

    override func viewWillAppear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillAppear(animated)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        // Add a small delay to allow the stylesheets to load and avoid flicker.
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(200 * Double(NSEC_PER_MSEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            webView.animateHidden(false, duration: 0.3)
        }
    }
}
