// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import Common
import Shared

class PrivacyPolicyViewController: UIViewController, Themeable {
    private var url: URL
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var timer: Timer?

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?

    init(
        url: URL,
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.url = url
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    func setupView() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(InternalSchemeHandler(shouldUseOldErrorPage: true), forURLScheme: InternalURL.scheme)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))

        view.backgroundColor = .systemBackground
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Theming
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        if #available(iOS 26.0, *) {
            navigationItem.rightBarButtonItem?.tintColor = theme.colors.textOnLight
        } else {
            navigationItem.rightBarButtonItem?.tintColor = theme.colors.actionPrimary
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension PrivacyPolicyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        timer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if webView.isLoading {
                    ErrorPageHelper(certStore: nil).loadPage(
                        NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet),
                        forUrl: self.url,
                        inWebView: webView
                    )
                    self.stopTimer()
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
        let nsError = error as NSError

        if nsError.code == CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue ||
            nsError.code == NSURLErrorNotConnectedToInternet {
            ErrorPageHelper(certStore: nil).loadPage(error as NSError, forUrl: url, inWebView: webView)
        }

        stopTimer()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        stopTimer()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        stopTimer()
    }
}
