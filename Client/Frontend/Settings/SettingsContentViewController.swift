// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import SnapKit
import UIKit
import WebKit
import Common

let DefaultTimeoutTimeInterval = 10.0 // Seconds.  We'll want some telemetry on load times in the wild.

/**
 * A controller that manages a single web view and provides a way for
 * the user to navigate back to Settings.
 */
class SettingsContentViewController: UIViewController, WKNavigationDelegate, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    var settingsTitle: NSAttributedString?
    var url: URL!
    var timer: Timer?

    var isLoaded = false {
        didSet {
            if isLoaded {
                UIView.transition(
                    from: interstitialView,
                    to: settingsWebView,
                    duration: 0.5,
                    options: .transitionCrossDissolve,
                    completion: { finished in
                        self.interstitialView.removeFromSuperview()
                        self.interstitialSpinnerView.stopAnimating()
                    }
                )
            }
        }
    }

    fileprivate var isError = false {
        didSet {
            if isError {
                interstitialErrorView.isHidden = false
                UIView.transition(
                    from: interstitialSpinnerView,
                    to: interstitialErrorView,
                    duration: 0.5,
                    options: .transitionCrossDissolve,
                    completion: { finished in
                        self.interstitialSpinnerView.removeFromSuperview()
                        self.interstitialSpinnerView.stopAnimating()
                    }
                )
            }
        }
    }

    // The view shown while the content is loading in the background web view.
    fileprivate var interstitialView: UIView!
    fileprivate var interstitialSpinnerView: UIActivityIndicatorView!
    fileprivate var interstitialErrorView: UILabel!

    // The web view that displays content.
    var settingsWebView: WKWebView!

    fileprivate func startLoading(_ timeout: Double = DefaultTimeoutTimeInterval) {
        if self.isLoaded {
            return
        }
        if timeout > 0 {
            self.timer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
        } else {
            self.timer = nil
        }
        self.settingsWebView.load(PrivilegedRequest(url: url) as URLRequest)
        self.interstitialSpinnerView.startAnimating()
    }

    init(title: NSAttributedString? = nil,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.settingsTitle = title
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.settingsWebView = makeWebView()
        view.addSubview(settingsWebView)
        self.settingsWebView.snp.remakeConstraints { make in
            make.edges.equalTo(self.view)
        }

        // Destructuring let causes problems.
        let ret = makeInterstitialViews()
        self.interstitialView = ret.view
        self.interstitialSpinnerView = ret.activityView
        self.interstitialErrorView = ret.label
        view.addSubview(interstitialView)
        self.interstitialView.snp.remakeConstraints { make in
            make.edges.equalTo(self.view)
        }

        startLoading()

        applyTheme()
        listenForThemeChange(view)
    }

    func makeWebView() -> WKWebView {
        let config = LegacyTabManager.makeWebViewConfig(isPrivate: true, prefs: nil)
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(
            frame: CGRect(width: 1, height: 1),
            configuration: config
        )
        webView.allowsLinkPreview = false
        webView.navigationDelegate = self

        // This is not shown full-screen, use mobile UA
        webView.customUserAgent = UserAgent.mobileUserAgent()

        return webView
    }

    struct InterstitialViews {
        let view: UIView
        let activityView: UIActivityIndicatorView
        let label: UILabel
    }

    fileprivate func makeInterstitialViews() -> InterstitialViews {
        let view = UIView()
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = themeManager.currentTheme.colors.iconSpinner
        view.addSubview(spinner)

        let error = UILabel()
        if settingsTitle != nil {
            error.text = .SettingsContentPageLoadError
            error.textColor = themeManager.currentTheme.colors.textWarning
            error.textAlignment = .center
        }
        error.isHidden = true
        view.addSubview(error)

        spinner.snp.makeConstraints { make in
            make.center.equalTo(view)
            return
        }

        error.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.left.equalTo(view.snp.left).offset(20)
            make.right.equalTo(view.snp.right).offset(-20)
            make.height.equalTo(44)
            return
        }

        return InterstitialViews(view: view, activityView: spinner, label: error)
    }

    @objc
    func didTimeOut() {
        self.timer = nil
        self.isError = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        didTimeOut()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didTimeOut()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.timer?.invalidate()
        self.timer = nil
        self.isLoaded = true
    }

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer2
    }
}
