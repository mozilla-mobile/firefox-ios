/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit
import WebKit

class AboutContentViewController: UIViewController, UIWebViewDelegate {
    private let url: URL

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIConstants.colors.background

        let webView = UIWebView()
        webView.alpha = 0
        view.addSubview(webView)

        webView.snp.remakeConstraints { make in
            make.edges.equalTo(self.view)
        }

        webView.delegate = self
        webView.loadRequest(URLRequest(url: url))
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillAppear(animated)
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        revealWebView(webView)
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        revealWebView(webView)
    }

    private func revealWebView(_ webView: UIWebView) {
        // Add a small delay to allow the stylesheets to load and avoid flicker.
        let delayTime = DispatchTime.now() + Double(Int64(200 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            webView.animateHidden(false, duration: 0.3)
        }
    }
}
