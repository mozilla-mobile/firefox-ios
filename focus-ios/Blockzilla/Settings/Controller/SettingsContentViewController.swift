/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebKit

let DefaultTimeoutTimeInterval = 10.0 // Seconds.  We'll want some telemetry on load times in the wild.

/**
 * A controller that manages a single web view and provides a way for
 * the user to navigate back to Settings.
 */
class SettingsContentViewController: UIViewController, WKNavigationDelegate {
    let interstitialBackgroundColor: UIColor
    var url: URL
    var timer: Timer?

    var isLoaded = false {
        didSet {
            if isLoaded {
                // Add a small delay to allow the stylesheets to load and avoid flicker.
                let delayTime = DispatchTime.now() + Double(Int64(200 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                    UIView.transition(
                        from: self.interstitialView,
                        to: self.webView,
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
    }

    private var isError = false {
        didSet {
            if isError {
                interstitialErrorView.isHidden = false
                // Add a small delay to allow the stylesheets to load and avoid flicker.
                let delayTime = DispatchTime.now() + Double(Int64(200 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                    UIView.transition(
                        from: self.interstitialSpinnerView,
                        to: self.interstitialErrorView,
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
    }

    // The view shown while the content is loading in the background web view.
    private lazy var interstitialView: UIView = {
        let interstitialView = UIView()
        interstitialView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = interstitialBackgroundColor
        return interstitialView
    }()

    private lazy var interstitialSpinnerView: UIActivityIndicatorView = {
        let interstitialSpinnerView = UIActivityIndicatorView(style: .large)
        interstitialSpinnerView.translatesAutoresizingMaskIntoConstraints = false
        return interstitialSpinnerView
    }()

    private lazy var interstitialErrorView: SmartLabel = {
        let interstitialErrorView = SmartLabel()
        interstitialErrorView.translatesAutoresizingMaskIntoConstraints = false
        return interstitialErrorView
    }()

    // The web view that displays content.
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 1, height: 1),
            configuration: config
        )
        webView.allowsLinkPreview = false
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    private func startLoading(_ timeout: Double = DefaultTimeoutTimeInterval) {
        if self.isLoaded {
            return
        }
        if timeout > 0 {
            self.timer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(SettingsContentViewController.SELdidTimeOut), userInfo: nil, repeats: false)
        } else {
            self.timer = nil
        }
        self.webView.load(URLRequest(url: url))
        self.interstitialSpinnerView.startAnimating()
    }

    init(url: URL, backgroundColor: UIColor = .systemBackground) {
        interstitialBackgroundColor = backgroundColor
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // This background agrees with the web page background.
        // Keeping the background constant prevents a pop of mismatched color.
        view.backgroundColor = interstitialBackgroundColor
        navigationController?.navigationBar.tintColor = .accent

        view.addSubview(webView)
        view.addSubview(interstitialView)
        interstitialView.addSubview(interstitialSpinnerView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            interstitialView.topAnchor.constraint(equalTo: view.topAnchor),
            interstitialView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            interstitialView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interstitialView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            interstitialSpinnerView.topAnchor.constraint(equalTo: interstitialView.topAnchor),
            interstitialSpinnerView.bottomAnchor.constraint(equalTo: interstitialView.bottomAnchor),
            interstitialSpinnerView.leadingAnchor.constraint(equalTo: interstitialView.leadingAnchor),
            interstitialSpinnerView.trailingAnchor.constraint(equalTo: interstitialView.trailingAnchor)
        ])

        startLoading()
    }

    @objc
    func SELdidTimeOut() {
        self.timer = nil
        self.isError = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        SELdidTimeOut()
        let errorPageData = ErrorPage(error: error).data
        webView.load(errorPageData, mimeType: "", characterEncodingName: "", baseURL: url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        SELdidTimeOut()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.timer?.invalidate()
        self.timer = nil
        self.isLoaded = true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let isLicensePage = navigationAction.request.url?.pathComponents.last.map({ $0 == "licenses.html" }) ?? false

        guard !isLicensePage else {
            decisionHandler(.cancel)
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString,
                                        invalidCharacters: false)
            else { return }
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            return
        }

        decisionHandler(.allow)
    }
}
