/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit
import WebKit

let DefaultTimeoutTimeInterval = 10.0 // Seconds.  We'll want some telemetry on load times in the wild.
private var TODOPageLoadErrorString = NSLocalizedString("Could not load page.", comment: "Error message that is shown in settings when there was a problem loading")

/**
 * A controller that manages a single web view and provides a way for
 * the user to navigate back to Settings.
 */
class SettingsContentViewController: UIViewController, WKNavigationDelegate {
    let interstitialBackgroundColor: UIColor
    var settingsTitle: NSAttributedString?
    var url: NSURL!
    var timer: NSTimer?

    var isLoaded: Bool = false {
        didSet {
            if isLoaded {
                UIView.transitionFromView(interstitialView, toView: webView,
                    duration: 0.5,
                    options: UIViewAnimationOptions.TransitionCrossDissolve,
                    completion: { finished in
                        self.interstitialView.removeFromSuperview()
                        self.interstitialSpinnerView.stopAnimating()
                })
            }
        }
    }

    private var isError: Bool = false {
        didSet {
            if isError {
                interstitialErrorView.hidden = false
                UIView.transitionFromView(interstitialSpinnerView, toView: interstitialErrorView,
                    duration: 0.5,
                    options: UIViewAnimationOptions.TransitionCrossDissolve,
                    completion: { finished in
                        self.interstitialSpinnerView.removeFromSuperview()
                        self.interstitialSpinnerView.stopAnimating()
                })
            }
        }
    }

    // The view shown while the content is loading in the background web view.
    private var interstitialView: UIView!
    private var interstitialSpinnerView: UIActivityIndicatorView!
    private var interstitialErrorView: UILabel!

    // The web view that displays content.
    var webView: WKWebView!

    private func startLoading(timeout: Double = DefaultTimeoutTimeInterval) {
        if self.isLoaded {
            return
        }
        if timeout > 0 {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(timeout, target: self, selector: "SELdidTimeOut", userInfo: nil, repeats: false)
        } else {
            self.timer = nil
        }
        self.webView.loadRequest(NSURLRequest(URL: url))
        self.interstitialSpinnerView.startAnimating()
    }

    init(backgroundColor: UIColor = UIColor.whiteColor(), title: NSAttributedString? = nil) {
        interstitialBackgroundColor = backgroundColor
        settingsTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // This background agrees with the web page background.
        // Keeping the background constant prevents a pop of mismatched color.
        view.backgroundColor = interstitialBackgroundColor

        self.webView = makeWebView()
        view.addSubview(webView)
        self.webView.snp_remakeConstraints { make in
            make.edges.equalTo(self.view)
        }

        // Destructuring let causes problems.
        let ret = makeInterstitialViews()
        self.interstitialView = ret.0
        self.interstitialSpinnerView = ret.1
        self.interstitialErrorView = ret.2
        view.addSubview(interstitialView)
        self.interstitialView.snp_remakeConstraints { make in
            make.edges.equalTo(self.view)
        }

        startLoading()
    }

    func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 1, height: 1),
            configuration: config
        )
        webView.navigationDelegate = self
        return webView
    }

    private func makeInterstitialViews() -> (UIView, UIActivityIndicatorView, UILabel) {
        let view = UIView()

        // Keeping the background constant prevents a pop of mismatched color.
        view.backgroundColor = interstitialBackgroundColor

        let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        view.addSubview(spinner)

        let error = UILabel()
        if let _ = settingsTitle {
            error.text = TODOPageLoadErrorString
            error.textColor = UIColor.redColor() // Firefox Orange!
            error.textAlignment = NSTextAlignment.Center
        }
        error.hidden = true
        view.addSubview(error)

        spinner.snp_makeConstraints { make in
            make.center.equalTo(view)
            return
        }

        error.snp_makeConstraints { make in
            make.center.equalTo(view)
            make.left.equalTo(view.snp_left).offset(20)
            make.right.equalTo(view.snp_right).offset(-20)
            make.height.equalTo(44)
            return
        }

        return (view, spinner, error)
    }

    func SELdidTimeOut() {
        self.timer = nil
        self.isError = true
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        SELdidTimeOut()
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        SELdidTimeOut()
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        self.timer?.invalidate()
        self.timer = nil
        self.isLoaded = true
    }
}
