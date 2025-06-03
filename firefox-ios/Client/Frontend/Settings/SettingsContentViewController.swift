// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import WebKit
import Common
import WebEngine

let DefaultTimeoutTimeInterval = 10.0 // Seconds.  We'll want some telemetry on load times in the wild.

/**
 * A controller that manages a single web view and provides a way for
 * the user to navigate back to Settings.
 */
class SettingsContentViewController: UIViewController, WKNavigationDelegate, Themeable {
    private struct UX {
        static let errorLeadingTrailingPadding: CGFloat = 20
        static let errorHeightPadding: CGFloat = 44
    }

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var settingsTitle: NSAttributedString?
    var url: URL?
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

    private var isError = false {
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
    private lazy var interstitialView: UIView = .build()
    private lazy var interstitialSpinnerView: UIActivityIndicatorView = .build()
    private lazy var interstitialErrorView: UILabel = .build()

    // The web view that displays content.
    private lazy var settingsWebView: WKWebView = .build()

    private func startLoading(_ timeout: Double = DefaultTimeoutTimeInterval) {
        guard !self.isLoaded, let url else {
            return
        }
        if timeout > 0 {
            self.timer = Timer.scheduledTimer(
                timeInterval: timeout,
                target: self,
                selector: #selector(didTimeOut),
                userInfo: nil,
                repeats: false
            )
        } else {
            self.timer = nil
        }
        settingsWebView.load(PrivilegedRequest(url: url) as URLRequest)
        interstitialSpinnerView.startAnimating()
    }

    init(title: NSAttributedString? = nil,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.settingsTitle = title
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        settingsWebView = makeWebView()

        // Destructuring let causes problems.
        let ret = makeInterstitialViews()
        self.interstitialView = ret.view
        self.interstitialSpinnerView = ret.activityView
        self.interstitialErrorView = ret.label
        view.addSubviews(settingsWebView, interstitialView)

        NSLayoutConstraint.activate([
            settingsWebView.topAnchor.constraint(equalTo: view.topAnchor),
            settingsWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            interstitialView.topAnchor.constraint(equalTo: view.topAnchor),
            interstitialView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interstitialView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interstitialView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        startLoading()

        applyTheme()
        listenForThemeChange(view)
    }

    func makeWebView() -> WKWebView {
        let parameters = WKWebViewParameters(
            blockPopups: true,
            isPrivate: true,
            autoPlay: .all,
            schemeHandler: WKInternalSchemeHandler()
        )

        let config = DefaultWKEngineConfigurationProvider().createConfiguration(parameters: parameters).webViewConfiguration

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
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

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    private func makeInterstitialViews() -> InterstitialViews {
        let view: UIView = .build()

        let spinner: UIActivityIndicatorView = .build { indicatorView in
            indicatorView.style = .medium
            indicatorView.color = self.currentTheme().colors.iconSpinner
        }

        let error: UILabel = .build { label in
            if self.settingsTitle != nil {
                label.text = .SettingsContentPageLoadError
                label.textColor = self.currentTheme().colors.textCritical
                label.textAlignment = .center
            }
            label.isHidden = true
        }

        view.addSubviews(spinner, error)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            error.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            error.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            error.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.errorLeadingTrailingPadding),
            error.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.errorLeadingTrailingPadding),
            error.heightAnchor.constraint(equalToConstant: UX.errorHeightPadding)
        ])

        return InterstitialViews(view: view, activityView: spinner, label: error)
    }

    @objc
    func didTimeOut() {
        self.timer = nil
        self.isError = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
        didTimeOut()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
        didTimeOut()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        self.timer?.invalidate()
        self.timer = nil
        self.isLoaded = true
    }

    func applyTheme() {
        view.backgroundColor = currentTheme().colors.layer2
    }
}
