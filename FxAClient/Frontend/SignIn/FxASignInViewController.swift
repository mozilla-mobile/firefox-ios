/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebKit

let SIGNUP_URI = "https://latest.dev.lcip.org/signup?service=sync&context=fx_desktop_v1"
let SIGNIN_URI = "https://latest.dev.lcip.org/signin?service=sync&context=fx_desktop_v1"

protocol FxASignInViewControllerDelegate {
    func didCancel()
    func didSignIn(data: JSON)
}

/**
 * A controller that connects an interstitial view with a background web view.
 */
class FxASignInViewController: UINavigationController, FxASignInWebViewControllerDelegate, FxAGetStartedViewControllerDelegate, WKNavigationDelegate {
    var signInDelegate: FxASignInViewControllerDelegate?

    private var webViewController: FxASignInWebViewController!
    private var getStartedViewController: FxAGetStartedViewController!

    override func loadView() {
        super.loadView()
        webViewController = FxASignInWebViewController()
        webViewController.delegate = self
        getStartedViewController = FxAGetStartedViewController()
        getStartedViewController.delegate = self
        webViewController.navigationDelegate = self
        webViewController.startLoad(getUrl())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Prevent child views from extending under navigation bar.
        navigationBar.translucent = false

        // This background agrees with the content server background.
        // Keeping the background constant prevents a pop of mismatched color.
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue:242/255.0, alpha:1.0)

        self.pushViewController(webViewController, animated: false)
        self.pushViewController(getStartedViewController, animated: false)
    }

    func didStart() {
        popViewControllerAnimated(true)
    }

    func getUrl() -> NSURL {
        NSLog("getUrl: \(SIGNIN_URI)")
        return NSURL(string: SIGNIN_URI)!
    }

    func didLoad() {
        NSLog("didLoad")
        getStartedViewController.notifyReadyToStart()
    }

    func didCancel() {
        NSLog("didCancel")
        signInDelegate?.didCancel()
    }

    func didSignIn(data: JSON) {
        NSLog("didSignIn")
        signInDelegate?.didSignIn(data)
    }

    func webView(webView: WKWebView!, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError!) {
        NSLog("WebView didFailProvisionalNavigation withError: \(error)")
        // Assume that all provisional navigation failures mean we can't reach the Firefox Accounts server.
        getStartedViewController.showError("Could not connect to Firefox Account server. Try again later.")
    }

    func webView(webView: WKWebView!, didFailNavigation navigation: WKNavigation!, withError error: NSError!) {
        NSLog("WebView didFailNavigation withError: \(error)")
        // Ignore inner navigation failures for now.
    }
}
