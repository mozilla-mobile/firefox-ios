/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Snap
import UIKit
import WebKit

let FxASignUpEndpoint = "https://latest.dev.lcip.org/signup?service=sync&context=fx_desktop_v1"
let FxASignInEndpoint = "https://latest.dev.lcip.org/signin?service=sync&context=fx_desktop_v1"

protocol FxASignInViewControllerDelegate {
    func signInViewControllerDidCancel(vc: FxASignInViewController)
    func signInViewControllerDidSignIn(vc: FxASignInViewController, data: JSON)
}

/**
 * A controller that connects an interstitial view with a background web view.
 */
class FxASignInViewController: UINavigationController, FxASignInWebViewControllerDelegate, FxAGetStartedViewControllerDelegate {
    var signInDelegate: FxASignInViewControllerDelegate?

    private var webViewController: FxASignInWebViewController!
    private var getStartedViewController: FxAGetStartedViewController!

    override func loadView() {
        super.loadView()
        webViewController = FxASignInWebViewController()
        webViewController.delegate = self
        getStartedViewController = FxAGetStartedViewController()
        getStartedViewController.delegate = self
        webViewController.startLoad(getUrl())
    }

    func getUrl() -> NSURL {
        return NSURL(string: FxASignInEndpoint)!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Prevent child views from extending under navigation bar.
        navigationBar.translucent = false

        // This background agrees with the content server background.
        // Keeping the background constant prevents a pop of mismatched color.
        view.backgroundColor = UIColor(red: 242 / 255.0, green: 242 / 255.0, blue: 242 / 255.0, alpha: 1.0)

        self.pushViewController(webViewController, animated: false)
        self.pushViewController(getStartedViewController, animated: false)
    }

    func getStartedViewControllerDidStart(vc: FxAGetStartedViewController) {
        popViewControllerAnimated(true)
    }

    func getStartedViewControllerDidCancel(vc: FxAGetStartedViewController) {
        signInDelegate?.signInViewControllerDidCancel(self)
    }

    func signInWebViewControllerDidLoad(vc: FxASignInWebViewController) {
        getStartedViewController.notifyReadyToStart()
    }

    func signInWebViewControllerDidCancel(vc: FxASignInWebViewController) {
        signInDelegate?.signInViewControllerDidCancel(self)
    }

    func signInWebViewControllerDidSignIn(vc: FxASignInWebViewController, data: JSON) {
        signInDelegate?.signInViewControllerDidSignIn(self, data: data)
    }


    func signInWebViewControllerDidFailProvisionalNavigation(vc: FxASignInWebViewController, withError error:
            NSError!) {
        // Assume that all provisional navigation failures mean we can't reach the Firefox Accounts server.
        let errorString = NSLocalizedString("Could not connect to Firefox Account server. Try again later.",
                comment: "Error shown when we can't connect to Firefox Accounts.")
        getStartedViewController.showError(errorString)
    }

    func signInWebViewControllerDidFailNavigation(vc: FxASignInWebViewController, withError error:
            NSError!) {
        // Ignore inner navigation failures for now.
    }
}
